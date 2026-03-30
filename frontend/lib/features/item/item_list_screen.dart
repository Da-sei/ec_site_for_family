import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../widgets/main_scaffold.dart';
import '../group/group_provider.dart';
import 'item_list_provider.dart';

const _categories = [
  {'id': 1, 'name': '食品・飲み物'},
  {'id': 2, 'name': '衣類・ファッション'},
  {'id': 3, 'name': '家電・電子機器'},
  {'id': 4, 'name': '本・雑誌'},
  {'id': 5, 'name': 'おもちゃ・ゲーム'},
  {'id': 6, 'name': '家具・インテリア'},
  {'id': 7, 'name': 'スポーツ・アウトドア'},
  {'id': 8, 'name': 'その他'},
];

class ItemListScreen extends ConsumerStatefulWidget {
  final String? initialKeyword;

  const ItemListScreen({super.key, this.initialKeyword});

  @override
  ConsumerState<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends ConsumerState<ItemListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() async {
      await ref.read(groupProvider.notifier).loadMyGroups();
      _syncGroupAndLoadItems();
    });
  }

  void _syncGroupAndLoadItems() {
    final groupState = ref.read(groupProvider);
    if (groupState.selectedGroupId != null) {
      if (widget.initialKeyword != null) {
        ref.read(itemListProvider.notifier).setGroupIdWithKeyword(
          groupState.selectedGroupId!,
          widget.initialKeyword!,
        );
      } else {
        // 毎回強制リフレッシュして新着アイテムを取得する
        ref.read(itemListProvider.notifier).forceRefresh(groupState.selectedGroupId!);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(itemListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemState = ref.watch(itemListProvider);
    final groupState = ref.watch(groupProvider);
    final hasFilter = itemState.categoryId != null;

    ref.listen(groupProvider.select((s) => s.selectedGroupId), (prev, next) {
      if (next != null && next != prev) {
        ref.read(itemListProvider.notifier).setGroupId(next);
      }
    });

    return MainScaffold(
      selectedIndex: 0,
      title: 'ファミリーフリマ',
      showGroupSelector: true,
      floatingActionButton: groupState.selectedGroupId != null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/items/create'),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                '出品する',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Column(
        children: [
          // アクティブフィルターバー
          if (hasFilter)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFE3F2FD),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded,
                      size: 14, color: Color(0xFF1976D2)),
                  const SizedBox(width: 6),
                  Text(
                    (_categories
                            .firstWhere(
                              (c) => c['id'] == itemState.categoryId,
                              orElse: () => {'name': ''},
                            )['name'] as String?) ??
                        '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref.read(itemListProvider.notifier).refresh(
                            clearCategory: true,
                          );
                    },
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: Color(0xFF1976D2)),
                  ),
                ],
              ),
            ),

          // アイテムグリッド
          Expanded(
            child: groupState.groups.isEmpty && !groupState.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE3F2FD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.group_add_rounded,
                            size: 56,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'グループに参加しよう！',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'まずグループを作成または参加してください',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/groups'),
                          icon: const Icon(Icons.group_rounded),
                          label: const Text('グループを管理'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : itemState.isLoading && itemState.items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : itemState.items.isEmpty
                        ? Center(
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
                                    Icons.inventory_2_rounded,
                                    size: 48,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '商品がありません',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(itemListProvider.notifier).refresh(),
                            child: GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: itemState.items.length +
                                  (itemState.hasMore ? 1 : 0),
                              itemBuilder: (ctx, i) {
                                if (i == itemState.items.length) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                return _ItemCard(item: itemState.items[i]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isAvailable = item.status == 'AVAILABLE';

    return GestureDetector(
      onTap: () => context.push('/items/${item.id}'),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像エリア
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: item.images.isNotEmpty
                        ? Image.network(
                            item.images.first.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => _PlaceholderImage(),
                          )
                        : _PlaceholderImage(),
                  ),
                  // ステータスバッジ（売り切れのみ表示）
                  if (!isAvailable)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.statusDisplay,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // カテゴリバッジ
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        item.category.name,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // テキストエリア
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? const Color(0xFF4CAF50)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.seller.name,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ..._buildDeliveryIcons(item.deliveryMethods),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDeliveryIcons(List<String> methods) {
    final icons = <Widget>[];
    for (final m in methods.take(2)) {
      final IconData icon = switch (m) {
        'HAND_DELIVERY' => Icons.handshake_rounded,
        'POSTAL' => Icons.mail_rounded,
        'COURIER' => Icons.local_shipping_rounded,
        _ => Icons.more_horiz_rounded,
      };
      icons.add(Icon(icon, size: 12, color: Colors.grey));
    }
    return icons;
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE3F2FD),
      child: const Center(
        child: Icon(Icons.image_rounded, size: 40, color: Color(0xFF90CAF9)),
      ),
    );
  }
}
