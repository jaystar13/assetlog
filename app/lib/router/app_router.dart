import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/cashflow_screen.dart';
import '../screens/asset_tracker_screen.dart';
import '../screens/overview_screen.dart';
import '../screens/shared_access_screen.dart';
import '../screens/more_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/bottom_nav.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
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
