import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../widgets/main_scaffold.dart';
import '../auth/auth_provider.dart';
import '../group/group_provider.dart';
import 'wishlist_provider.dart';

class WishlistListScreen extends ConsumerStatefulWidget {
  const WishlistListScreen({super.key});

  @override
  ConsumerState<WishlistListScreen> createState() => _WishlistListScreenState();
}

class _WishlistListScreenState extends ConsumerState<WishlistListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(groupProvider.notifier).loadMyGroups();
      final groupState = ref.read(groupProvider);
      if (groupState.selectedGroupId != null) {
        ref
            .read(wishlistProvider.notifier)
            .setGroupId(groupState.selectedGroupId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wishlistState = ref.watch(wishlistProvider);
    final groupState = ref.watch(groupProvider);
    final authState = ref.watch(authProvider);

    ref.listen(groupProvider.select((s) => s.selectedGroupId), (prev, next) {
      if (next != null && next != prev) {
        ref.read(wishlistProvider.notifier).setGroupId(next);
      }
    });

    return MainScaffold(
      selectedIndex: 3,
      title: 'ほしい物リスト',
      showGroupSelector: true,
      floatingActionButton: groupState.selectedGroupId != null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/wishlist/create'),
              icon: const Icon(Icons.card_giftcard_rounded),
              label: const Text(
                'リクエストを投稿',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: _buildBody(
        context,
        wishlistState: wishlistState,
        groupState: groupState,
        authAccountId: authState.accountId,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required wishlistState,
    required groupState,
    required String? authAccountId,
  }) {
    if (groupState.selectedGroupId == null && !groupState.isLoading) {
      return const Center(
        child: Text(
          'グループを選択してください',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    if (wishlistState.isLoading && wishlistState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (wishlistState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                size: 48,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ウィッシュリストはまだありません',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(wishlistProvider.notifier).loadWishlistItems(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        itemCount: wishlistState.items.length,
        itemBuilder: (ctx, i) {
          final item = wishlistState.items[i] as WishlistItem;
          final isOwner = authAccountId == item.requester.accountId;
          return _WishlistCard(
            item: item,
            isOwner: isOwner,
            onEdit: () => context.push('/wishlist/${item.id}/edit', extra: item),
            onDelete: () => _confirmDelete(context, item),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WishlistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${item.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(wishlistProvider.notifier).deleteWishlistItem(item.id);
    }
  }
}

class _WishlistCard extends StatelessWidget {
  final WishlistItem item;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WishlistCard({
    required this.item,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('編集')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('削除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                    child: const Icon(Icons.more_vert_rounded,
                        color: Colors.grey, size: 20),
                  ),
              ],
            ),
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description!,
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF555555)),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  item.requester.name,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}
