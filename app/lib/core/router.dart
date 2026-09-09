import 'package:go_router/go_router.dart';

import '../presentation/screens/add_snapshot_screen.dart';
import '../presentation/screens/counter_detail_screen.dart';
import '../presentation/screens/counter_list_screen.dart';
import '../presentation/screens/home_screen.dart';

/// Application routes (§5.1: go_router).
///
/// The customisable dashboard (§3.3) and the per-counter charts (§3.5) will be
/// added here.
abstract final class Routes {
  static const home = '/';
  static const addSnapshot = '/add';
  static const counters = '/counters';

  /// A counter is addressed by its export header, which is its stable identity
  /// (§3.1.2). Headers carry spaces and parentheses, so the segment is
  /// percent-encoded; none of them contains a slash.
  static String counterDetail(String exportHeader) =>
      '$counters/${Uri.encodeComponent(exportHeader)}';
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
            GoRoute(
              path: 'counters',
              builder: (context, state) => const CounterListScreen(),
              routes: [
                GoRoute(
                  path: ':header',
                  builder: (context, state) => CounterDetailScreen(
                    exportHeader:
                        Uri.decodeComponent(state.pathParameters['header']!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

/// Instance used by the application.
final router = createRouter();
