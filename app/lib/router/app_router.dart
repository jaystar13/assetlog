import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_state.dart';
import '../core/providers.dart';
import '../screens/home_screen.dart';
import '../screens/cashflow_screen.dart';
import '../screens/asset_tracker_screen.dart';
import '../screens/overview_screen.dart';
import '../screens/share_groups_screen.dart';
import '../screens/share_group_detail_screen.dart';
import '../screens/more_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../widgets/bottom_nav.dart';

/// AuthNotifier의 상태 변경을 GoRouter에 알리는 Listenable 어댑터.
///
/// GoRouter가 한 번만 생성되면서도 auth 상태 변경 시
/// redirect 로직이 재실행되도록 합니다.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authNotifierProvider, (_, _) {
      notifyListeners();
    });
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);

      if (authState.status == AuthStatus.unknown) return null;

      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isOnLogin) return '/login';
      if (isAuthenticated && isOnLogin) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cashflow',
                builder: (context, state) => const CashFlowScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assets',
                builder: (context, state) => const AssetTrackerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/overview',
                builder: (context, state) => const OverviewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const ProfileScreen(),
                  ),
                  GoRoute(
                    path: 'groups',
                    builder: (context, state) => const ShareGroupsScreen(),
                    routes: [
                      GoRoute(
                        path: ':groupId',
                        builder: (context, state) => ShareGroupDetailScreen(
                          groupId: state.pathParameters['groupId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
