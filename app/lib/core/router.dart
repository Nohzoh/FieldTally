import 'package:go_router/go_router.dart';

import '../presentation/screens/add_snapshot_screen.dart';
import '../presentation/screens/compare_screen.dart';
import '../presentation/screens/counter_detail_screen.dart';
import '../presentation/screens/counter_list_screen.dart';
import '../presentation/screens/customise_pins_screen.dart';
import '../presentation/screens/customise_widget_pins_screen.dart';
import '../presentation/screens/dashboard_screen.dart';
import '../presentation/screens/edit_snapshot_screen.dart';
import '../presentation/screens/import_csv_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/snapshot_changes_screen.dart';
import '../presentation/screens/share_card_screen.dart';
import '../presentation/screens/snapshot_list_screen.dart';
import '../presentation/screens/within_reach_screen.dart';
import '../presentation/screens/year_in_review_screen.dart';

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

  /// The widget's own counter selection (#174) — a sibling of
  /// [customisePins], not nested under it: the two selections are
  /// independent, and this one is reached from Settings.
  static const customiseWidgetPins = '/widget-pins';
  static const settings = '/settings';
  static const importCsv = '/import';

  /// Badges ranked by how long each would take (#148).
  static const withinReach = '/reach';

  /// A year read back (#153).
  static const yearInReview = '/year';

  /// The shareable stats card (§3.8).
  static const shareCard = '/share';

  /// Putting two agents' numbers side by side (#64). Reached with no extra to
  /// send, or with the text another agent shared to read it.
  static const compare = '/compare';

  /// What a snapshot recorded that the one before it had not (#147).
  ///
  /// A sibling of the correction route rather than a child of it, although it
  /// reads as one: nesting would put the edit screen between this one and the
  /// list, so backing out of a reading would land on a form the agent never
  /// asked for. Both are one step from the list, which is where both came
  /// from.
  static String snapshotChanges(String id) => '/snapshots/changes/$id';

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
            // Before ':id', so the literal segment is never read as an id.
            GoRoute(
              path: 'changes/:id',
              builder: (context, state) => SnapshotChangesScreen(
                snapshotId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) =>
                  EditSnapshotScreen(snapshotId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: 'pins',
          builder: (context, state) => const CustomisePinsScreen(),
        ),
        GoRoute(
          path: 'widget-pins',
          builder: (context, state) => const CustomiseWidgetPinsScreen(),
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
          path: 'reach',
          builder: (context, state) => const WithinReachScreen(),
        ),
        GoRoute(
          path: 'year',
          builder: (context, state) => const YearInReviewScreen(),
        ),
        GoRoute(
          path: 'share',
          builder: (context, state) => const ShareCardScreen(),
        ),
        GoRoute(
          path: 'compare',
          builder: (context, state) => CompareScreen(
            // Set when a share brought another agent's totals in; null
            // when the agent opened the screen to send their own.
            incoming: state.extra as String?,
          ),
        ),
        GoRoute(
          path: 'counters',
          builder: (context, state) => const CounterListScreen(),
          routes: [
            GoRoute(
              path: ':header',
              builder: (context, state) => CounterDetailScreen(
                exportHeader: Uri.decodeComponent(
                  state.pathParameters['header']!,
                ),
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
