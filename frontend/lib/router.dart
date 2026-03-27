import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/models/models.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/favorite/favorite_screen.dart';
import 'features/group/group_list_screen.dart';
import 'features/group/group_join_screen.dart';
import 'features/item/item_list_screen.dart';
import 'features/item/item_detail_screen.dart';
import 'features/item/item_create_screen.dart';
import 'features/item/item_edit_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/request/request_list_screen.dart';
import 'features/request/history_screen.dart';

/// authProvider の変化を GoRouter に通知する ChangeNotifier
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (prev, next) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isAuthenticated && !isAuthRoute) return '/login';
    if (isAuthenticated && isAuthRoute) return '/';
    return null;
  }
}

/// フェード + 軽いスライドのカスタムトランジション
Page<dynamic> _fadeSlidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadeSlidePage(const LoginScreen(), state),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _fadeSlidePage(const RegisterScreen(), state),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _fadeSlidePage(const ItemListScreen(), state),
      ),
      GoRoute(
        path: '/items/create',
        pageBuilder: (context, state) => _fadeSlidePage(const ItemCreateScreen(), state),
      ),
      GoRoute(
        path: '/items/:id',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _fadeSlidePage(ItemDetailScreen(itemId: id), state);
        },
      ),
      GoRoute(
        path: '/items/:id/edit',
        pageBuilder: (context, state) {
          final item = state.extra as Item;
          return _fadeSlidePage(ItemEditScreen(item: item), state);
        },
      ),
      GoRoute(
        path: '/groups',
        pageBuilder: (context, state) => _fadeSlidePage(const GroupListScreen(), state),
      ),
      GoRoute(
        path: '/groups/join',
        pageBuilder: (context, state) => _fadeSlidePage(const GroupJoinScreen(), state),
      ),
      GoRoute(
        path: '/requests',
        pageBuilder: (context, state) => _fadeSlidePage(const RequestListScreen(), state),
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) => _fadeSlidePage(const HistoryScreen(), state),
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) => _fadeSlidePage(const FavoriteScreen(), state),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _fadeSlidePage(const ProfileScreen(), state),
      ),
    ],
  );
});
