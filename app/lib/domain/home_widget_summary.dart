import 'badge_projection.dart';
import 'dashboard.dart';
import 'models/counter_registry.dart';
import 'models/stat_snapshot.dart';

/// One line the home screen widget shows for one pinned counter (#154).
typedef HomeWidgetLine = ({
  String exportHeader,
  int value,

  /// Since the previous snapshot. Null when there is nothing to compare
  /// against, same as [DashboardCard]'s own reading of that gap.
  int? delta,

  /// The tier still ahead, or null: no thresholds at all, or past onyx —
  /// where the game counts in multiples rather than towards a next name, and
  /// a widget has no room to say which multiple.
  String? nextTier,

  /// How much is left to [nextTier]. Present exactly when [nextTier] is.
  int? remainingToNextTier,
});

/// What the widget has to say, or why it has nothing to.
class HomeWidgetSummary {
  const HomeWidgetSummary({required this.lines, required this.hasAnyPinned});

  /// Zero, one or two lines — never more, however many are pinned.
  final List<HomeWidgetLine> lines;

  /// False only when nothing is pinned at all, which is a different state
  /// from "pinned but no snapshot exists yet": the first asks the agent to
  /// pin something, the second asks them to import.
  ///
  /// Not reachable through the app's own `homeWidgetSummaryProvider` today:
  /// `pinnedCountersProvider` substitutes `PinnedCounterRepository.defaults`
  /// for a genuinely empty selection, and the customise-pins screen enforces
  /// a floor of `minPinned` besides. Kept anyway, because this builder takes
  /// whatever list of pinned headers it is handed rather than assuming one
  /// caller's habits — `DashboardBuilder` makes the same call for the same
  /// reason, and its own "nothing pinned" branch is equally unreachable
  /// through `dashboardProvider` today.
  final bool hasAnyPinned;
}

/// Turns pinned counters into what a home screen widget can show (#154).
///
/// Reuses [DashboardBuilder] rather than re-deriving its rules: the pinned
/// order, a counter absent from every snapshot producing no card, the "a gap
/// in the imports is not a dip to zero" guard already tested there. A widget
/// disagreeing with the dashboard about which counters are shown, or about
/// what counts as progress, would be a second copy of a rule the app already
/// got right once.
class HomeWidgetSummaryBuilder {
  const HomeWidgetSummaryBuilder({this.registry, this.maxLines = 4});

  /// Gives each line its next tier and how far it is. Without one, every line
  /// carries a value and a delta and nothing about a medal — which is exactly
  /// what the dashboard itself does before the registry has loaded.
  final CounterRegistry? registry;

  /// The native layout's own plafond (#177) — four rows is what the widget
  /// supports at its largest, not what shows at any given size. How many of
  /// these actually render is decided natively, from the widget's current
  /// on-screen size; this only bounds how much Dart ever precomputes, so a
  /// resize needs no recomputation, just more of what is already written.
  final int maxLines;

  /// A fixed instant, not the wall clock, used only to satisfy
  /// [BadgeProjector]'s signature. Only [BadgeProjection.next] and
  /// [BadgeProjection.remaining] are read below, and neither depends on it —
  /// passing this rather than `DateTime.now()` is what keeps this builder
  /// pure and its output independent of when it happens to run.
  static final _unusedInstant = DateTime(0);

  HomeWidgetSummary build({
    required List<StatSnapshot> snapshots,
    required List<String> pinned,
  }) {
    if (pinned.isEmpty) {
      return const HomeWidgetSummary(lines: [], hasAnyPinned: false);
    }

    final cards = const DashboardBuilder().build(
      snapshots: snapshots,
      pinned: pinned,
    );

    final lines = [for (final card in cards.take(maxLines)) _lineFor(card)];

    return HomeWidgetSummary(lines: lines, hasAnyPinned: true);
  }

  HomeWidgetLine _lineFor(DashboardCard card) {
    final enrichment = registry?.forExportHeader(card.counter.exportHeader);
    final projection = const BadgeProjector().project(
      points: [(at: _unusedInstant, value: card.counter.lastValue)],
      enrichment: enrichment,
    );

    return (
      exportHeader: card.counter.exportHeader,
      value: card.counter.lastValue,
      delta: card.counter.delta,
      nextTier: projection?.next?.name,
      remainingToNextTier: projection?.next == null
          ? null
          : projection!.remaining,
    );
  }
}
