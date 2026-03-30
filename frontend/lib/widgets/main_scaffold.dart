import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../features/group/group_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget body;
  final int selectedIndex;
  final String? title;
  final bool showGroupSelector;
  final List<Widget>? extraActions;
  final Widget? floatingActionButton;

  const MainScaffold({
    super.key,
    required this.body,
    this.selectedIndex = 0,
    this.title,
    this.showGroupSelector = false,
    this.extraActions,
    this.floatingActionButton,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.showGroupSelector) {
      Future.microtask(() {
        if (!mounted) return;
        final gs = ref.read(groupProvider);
        if (gs.groups.isEmpty && !gs.isLoading) {
          ref.read(groupProvider.notifier).loadMyGroups();
        }
      });
    }
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-2196054972001278/9817878986',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isBannerAdLoaded = true);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.title != null ? Text(widget.title!) : null,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
          ),
        ),
        actions: [
          if (widget.extraActions != null) ...widget.extraActions!,
        ],
        bottom: widget.showGroupSelector
            ? const PreferredSize(
                preferredSize: Size.fromHeight(36),
                child: _GroupSelectorBar(),
              )
            : null,
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomNavigationBar(
        currentIndex: widget.selectedIndex,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        iconSize: 26,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/favorites');
            case 2:
              context.go('/requests');
            case 3:
              context.go('/wishlist');
            case 4:
              context.go('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'いいね',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_rounded),
            label: '申し込み',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard_rounded),
            label: 'ほしい物',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'マイページ',
          ),
        ],
      ),
          if (_isBannerAdLoaded && _bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// グループ選択バー（AppBar の bottom スロット用）
// ─────────────────────────────────────────────

class _GroupSelectorBar extends ConsumerWidget {
  const _GroupSelectorBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(groupProvider);
    final current = groupState.groups
        .where((g) => g.id == groupState.selectedGroupId)
        .firstOrNull;
    final label = current?.name ?? 'グループなし';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSheet(context, ref),
        child: Container(
          height: 36,
          width: double.infinity,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_rounded, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, size: 18, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final groupState = ref.watch(groupProvider);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    'グループを選択',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (groupState.groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        '参加中のグループがありません',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...groupState.groups.map((g) {
                    final isSelected = g.id == groupState.selectedGroupId;
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1976D2)
                              : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.group_rounded,
                          color: isSelected ? Colors.white : const Color(0xFF1976D2),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        g.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF1565C0) : null,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Color(0xFF1976D2))
                          : null,
                      onTap: () {
                        ref.read(groupProvider.notifier).selectGroup(g.id);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Color(0xFF7B1FA2),
                      size: 20,
                    ),
                  ),
                  title: const Text('グループを管理'),
                  subtitle: const Text(
                    '作成・参加・招待',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/groups');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
