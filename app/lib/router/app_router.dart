import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_state.dart';
import '../core/providers.dart';
import '../screens/home_screen.dart';
import '../screens/cashflow_screen.dart';
import '../screens/asset_tracker_screen.dart';
import '../screens/overview_screen.dart';
import '../screens/shared_access_screen.dart';
import '../screens/more_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../screens/shared_asset_detail_screen.dart';
import '../widgets/bottom_nav.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.status == AuthStatus.unknown) return null;

      final isAuthenticated =
          authState.status == AuthStatus.authenticated;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isOnLogin) return '/login';
      if (isAuthenticated && isOnLogin) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/shared-asset/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return SharedAssetDetailScreen(
            accessId: state.pathParameters['id']!,
            ownerName: extra['ownerName'] as String,
            ownerAvatar: extra['ownerAvatar'] as String?,
            cashflowPermission: extra['cashflowPermission'] as String,
            assetPermissions: (extra['assetPermissions'] as Map).cast<String, String>(),
          );
        },
      ),
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
                    path: 'access',
                    builder: (context, state) => const SharedAccessScreen(),
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
