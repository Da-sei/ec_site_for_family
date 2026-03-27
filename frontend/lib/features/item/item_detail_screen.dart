import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import '../request/request_provider.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final int itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  Item? _item;
  bool _isLoading = true;
  String? _error;
  List<ItemRequest> _requests = [];
  final _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/items/${widget.itemId}');
      final item = Item.fromJson(response.data as Map<String, dynamic>);
      final requests =
          await ref.read(requestProvider.notifier).getRequestsForItem(widget.itemId);
      setState(() {
        _item = item;
        _requests = requests;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message']?.toString() ?? '商品の読み込みに失敗しました';
        _isLoading = false;
      });
    }
  }

  void _shareItem() {
    if (_item == null) return;
    final text = '【Family Marketplace】${_item!.title}\n'
        '${_item!.description ?? ''}\n'
        '渡し方: ${_item!.deliveryMethodsDisplay}\n'
        '出品者: ${_item!.seller.name}';
    Share.share(text);
  }

  Future<void> _applyForItem() async {
    final deliveryMethod = await _showDeliveryMethodSheet();
    if (deliveryMethod == null || !mounted) return;

    final success = await ref.read(requestProvider.notifier).applyForItem(widget.itemId, deliveryMethod);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('申し込みました'), backgroundColor: Colors.green),
      );
      await _loadItem();
    } else if (mounted) {
      final error = ref.read(requestProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error ?? '申し込みに失敗しました'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _showDeliveryMethodSheet() {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '渡し方を選択',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '相手との距離に合わせて選んでください',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ...[
                ('HAND_DELIVERY', '手渡し', Icons.handshake_rounded),
                ('POSTAL', '郵送', Icons.mail_rounded),
                ('COURIER', '宅配便', Icons.local_shipping_rounded),
                ('OTHER', 'その他', Icons.more_horiz_rounded),
              ].map((entry) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(entry.$3, color: const Color(0xFF1976D2), size: 22),
                    ),
                    title: Text(entry.$2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () => Navigator.pop(ctx, entry.$1),
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleRequestAction(String action, int requestId) async {
    bool success = false;
    final notifier = ref.read(requestProvider.notifier);
    switch (action) {
      case 'approve':
        success = await notifier.approveRequest(requestId);
        break;
      case 'decline':
        success = await notifier.declineRequest(requestId);
        break;
      case 'cancel':
        success = await notifier.cancelRequest(requestId);
        break;
      case 'complete':
        success = await notifier.completeRequest(requestId);
        break;
    }
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作が完了しました'), backgroundColor: Colors.green),
      );
      await _loadItem();
    } else if (mounted) {
      final error = ref.read(requestProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? '操作に失敗しました'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestState = ref.watch(requestProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(context, null),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _item == null) {
      return Scaffold(
        appBar: _buildAppBar(context, null),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 56, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(_error ?? 'エラーが発生しました',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadItem,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    final item = _item!;
    final isAvailable = item.status == 'AVAILABLE';

    return Scaffold(
      appBar: _buildAppBar(context, item),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像ギャラリー
            _buildImageGallery(item),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ステータス + タイトル行
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusBadge(status: item.status, label: item.statusDisplay),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // メタ情報カード
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _MetaRow(
                          icon: Icons.category_rounded,
                          label: 'カテゴリ',
                          value: item.category.name,
                        ),
                        const Divider(height: 16),
                        _MetaRow(
                          icon: Icons.person_rounded,
                          label: '出品者',
                          value: item.seller.name,
                        ),
                        const Divider(height: 16),
                        _MetaRow(
                          icon: Icons.calendar_today_rounded,
                          label: '出品日',
                          value: _formatDate(item.createdAt),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 説明
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const Text(
                      '説明',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE3F2FD)),
                      ),
                      child: Text(
                        item.description!,
                        style: const TextStyle(height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(),

                  // 申し込みボタン
                  if (isAvailable) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: requestState.isLoading ? null : _applyForItem,
                        icon: requestState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.shopping_bag_rounded),
                        label: const Text(
                          '申し込む',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 申し込み一覧
                  if (_requests.isNotEmpty) ...[
                    const Text(
                      '申し込み一覧',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    ..._requests.map((req) => _RequestCard(
                          request: req,
                          itemStatus: item.status,
                          onAction: _handleRequestAction,
                          isLoading: requestState.isLoading,
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, Item? item) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      title: item != null
          ? Text(
              item.title,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            )
          : null,
      actions: item != null
          ? [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: _shareItem,
                tooltip: 'シェア',
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () =>
                    context.push('/items/${item.id}/edit', extra: item),
                tooltip: '編集',
              ),
            ]
          : null,
    );
  }

  Widget _buildImageGallery(Item item) {
    if (item.images.isEmpty) {
      return Container(
        height: 300,
        color: const Color(0xFFE3F2FD),
        child: const Center(
          child: Icon(Icons.image_rounded, size: 64, color: Color(0xFF90CAF9)),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            itemCount: item.images.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (ctx, i) => Image.network(
              item.images[i].imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Container(
                color: const Color(0xFFE3F2FD),
                child: const Icon(Icons.image_rounded,
                    size: 64, color: Color(0xFF90CAF9)),
              ),
            ),
          ),
        ),
        if (item.images.length > 1) ...[
          // 画像カウンター
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1} / ${item.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // ドットインジケーター
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                item.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentImageIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentImageIndex
                        ? Colors.white
                        : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'AVAILABLE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable ? const Color(0xFF81C784) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isAvailable ? const Color(0xFF4CAF50) : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isAvailable ? const Color(0xFF2E7D32) : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1976D2)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ItemRequest request;
  final String itemStatus;
  final Future<void> Function(String action, int requestId) onAction;
  final bool isLoading;

  const _RequestCard({
    required this.request,
    required this.itemStatus,
    required this.onAction,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFE3F2FD),
                      child: Text(
                        request.requester.name.isNotEmpty
                            ? request.requester.name[0]
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      request.requester.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(request.status),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    request.statusDisplay,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (request.deliveryMethod != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.local_shipping_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '渡し方: ${request.deliveryMethodDisplay}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
            if (request.status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => onAction('approve', request.id),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('承認'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => onAction('decline', request.id),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('断る'),
                    ),
                  ),
                ],
              ),
            ] else if (request.status == 'APPROVED') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => onAction('complete', request.id),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('取引完了'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return const Color(0xFF1976D2);
      case 'DECLINED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      case 'COMPLETED':
        return const Color(0xFF43A047);
      default:
        return Colors.grey;
    }
  }
}
