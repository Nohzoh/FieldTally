import 'package:go_router/go_router.dart';

import '../presentation/screens/add_snapshot_screen.dart';
import '../presentation/screens/home_screen.dart';

/// Application routes (§5.1: go_router).
///
/// Two screens at this stage. The customisable dashboard (§3.3), the detailed
/// view (§3.4) and the charts (§3.5) will be added here.
abstract final class Routes {
  static const home = '/';
  static const addSnapshot = '/add';
}

/// Builds a fresh router.
///
/// A factory rather than a global constant: a `GoRouter` holds navigation
/// state, and sharing it across widget tests would make them depend on their
/// execution order.
GoRouter createRouter() => GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => AddSnapshotScreen(
                // Incoming shares (§3.1) will drop the text received from
                // Ingress here, landing straight on the preview.
                initialText: state.extra as String?,
              ),
            ),
          ],
        ),
      ],
    );

/// Instance used by the application.
final router = createRouter();
