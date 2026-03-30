import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import '../../widgets/main_scaffold.dart';
import '../auth/auth_provider.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/users/me');
      final user = User.fromJson(response.data as Map<String, dynamic>);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              e.response?.data?['message']?.toString() ?? 'プロフィールの読み込みに失敗しました';
        });
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    // isAuthenticated: false になったことをルーターが検知して /login へリダイレクト
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('再試行'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
              label: const Text(
                'ログアウト',
                style: TextStyle(color: Color(0xFFD32F2F)),
              ),
            ),
          ],
        ),
      );
    } else if (_user == null) {
      body = const Center(child: Text('ユーザー情報が見つかりません'));
    } else {
      final user = _user!;
      body = SingleChildScrollView(
        child: Column(
          children: [
            // ユーザー情報ヘッダー
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.accountId}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfileEditScreen(initialName: user.name),
                        ),
                      );
                      if (updated == true) _loadProfile();
                    },
                    icon: const Icon(Icons.edit_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('編集',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ショートカットメニュー
            _SectionHeader(title: 'アクティビティ'),
            _MenuTile(
              icon: Icons.storefront_rounded,
              iconColor: const Color(0xFF0288D1),
              bgColor: const Color(0xFFE1F5FE),
              title: '自分の出品',
              subtitle: '出品した商品を管理',
              onTap: () => context.push('/my-items'),
            ),
            _MenuTile(
              icon: Icons.inbox_rounded,
              iconColor: const Color(0xFF1976D2),
              bgColor: const Color(0xFFE3F2FD),
              title: '申し込み一覧',
              subtitle: '自分の申し込み状況を確認',
              onTap: () => context.go('/requests'),
            ),
            _MenuTile(
              icon: Icons.history_rounded,
              iconColor: const Color(0xFF43A047),
              bgColor: const Color(0xFFE8F5E9),
              title: '取引履歴',
              subtitle: '完了した取引を確認',
              onTap: () => context.push('/history'),
            ),
            _MenuTile(
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFFE53935),
              bgColor: const Color(0xFFFFEBEE),
              title: 'お気に入り',
              subtitle: 'いいねした商品を確認',
              onTap: () => context.go('/favorites'),
            ),
            _MenuTile(
              icon: Icons.card_giftcard_rounded,
              iconColor: const Color(0xFFF57C00),
              bgColor: const Color(0xFFFFF3E0),
              title: 'ほしい物リスト',
              subtitle: 'グループ内のほしい物を管理',
              onTap: () => context.go('/wishlist'),
            ),

            const SizedBox(height: 8),

            _SectionHeader(title: 'グループ'),
            _MenuTile(
              icon: Icons.group_rounded,
              iconColor: const Color(0xFF7B1FA2),
              bgColor: const Color(0xFFF3E5F5),
              title: 'グループ管理',
              subtitle: 'グループの作成・参加・招待',
              onTap: () => context.push('/groups'),
            ),

            const SizedBox(height: 8),

            _SectionHeader(title: 'アカウント'),
            _MenuTile(
              icon: Icons.edit_rounded,
              iconColor: const Color(0xFF546E7A),
              bgColor: const Color(0xFFECEFF1),
              title: 'プロフィール編集',
              subtitle: '名前・パスワードを変更',
              onTap: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileEditScreen(initialName: user.name),
                  ),
                );
                if (updated == true) _loadProfile();
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
                label: const Text(
                  'ログアウト',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD32F2F)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return MainScaffold(
      selectedIndex: 4,
      title: 'マイページ',
      body: body,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
