import 'package:go_router/go_router.dart';

import '../presentation/screens/add_snapshot_screen.dart';
import '../presentation/screens/counter_detail_screen.dart';
import '../presentation/screens/counter_list_screen.dart';
import '../presentation/screens/customise_pins_screen.dart';
import '../presentation/screens/dashboard_screen.dart';
import '../presentation/screens/edit_snapshot_screen.dart';
import '../presentation/screens/import_csv_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/snapshot_list_screen.dart';

/// Application routes (§5.1: go_router).
///
/// The per-counter charts (§3.5) will be added here.
abstract final class Routes {
  /// The dashboard (§3.3) is the home screen; the snapshot list moved to its
  /// own route once it stopped being the first thing an agent sees.
  static const home = '/';
  static const addSnapshot = '/add';
  static const counters = '/counters';
  static const snapshots = '/snapshots';
  static const customisePins = '/pins';
  static const settings = '/settings';
  static const importCsv = '/import';

  /// Correcting a snapshot (§3.2) addresses it by its stored id.
  static String editSnapshot(String id) => '/snapshots/$id';

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
          builder: (context, state) => const DashboardScreen(),
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
              path: 'snapshots',
              builder: (context, state) => const SnapshotListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => EditSnapshotScreen(
                    snapshotId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'pins',
              builder: (context, state) => const CustomisePinsScreen(),
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: 'import',
              builder: (context, state) => const ImportCsvScreen(),
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
