import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/router.dart';
import '../../domain/agent_comparison.dart';
import '../../domain/comparison_payload.dart';
import '../../domain/models/counter_registry.dart';
import '../../domain/models/stat_snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../faction.dart';
import '../providers/providers.dart';

/// Two agents in the same room, numbers side by side (#64).
///
/// §13 kept head-to-head comparison out of v1 because it needed a shared
/// backend. Proximity removes that premise: the totals travel as text through
/// the share sheet the app already listens on (§3.1), so there is still no
/// server and nothing leaves by itself.
///
/// **Nothing received here is stored.** The other agent's snapshot lives as
/// long as this screen does. Writing it to the history would corrupt every
/// derived view — deltas, projections, goals — and the behavioural guard would
/// be right to refuse it, since a stranger's numbers look exactly like the
/// wrong-period import it exists to catch (§3.1.3).
class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key, this.incoming});

  /// Raw text of a comparison another agent sent, or null when the screen was
  /// opened to send rather than to read.
  ///
  /// Decoded here rather than by the listener that routed it: the failure
  /// modes are worth showing, and this is the screen that can show them.
  final String? incoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final snapshots = ref.watch(snapshotsProvider).asData?.value ?? const [];
    final mine = snapshots.isEmpty ? null : snapshots.first.snapshot;

    StatSnapshot? theirs;
    ComparisonPayloadError? error;
    if (incoming != null) {
      try {
        theirs = const ComparisonPayload().decode(incoming!);
      } on ComparisonPayloadException catch (e) {
        error = e.error;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.compareTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (error != null) ...[
            _ErrorCard(error: error),
            const SizedBox(height: 16),
          ],
          if (mine == null)
            _Empty(
              title: l10n.compareEmptyTitle,
              detail: l10n.compareEmptyDetail,
            )
          else if (theirs != null)
            ..._comparison(
              context: context,
              mine: mine,
              theirs: theirs,
              registry: registry,
              language: language,
            )
          else
            ..._sending(
              context: context,
              mine: mine,
              registry: registry,
              language: language,
            ),
        ],
      ),
      // Pinned rather than sitting at the end of the list: the comparison runs
      // to sixty rows, and the one action on this screen should not be
      // something to scroll past all of them to reach.
      bottomNavigationBar: mine == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: () => _send(context, mine),
                  icon: const Icon(Icons.ios_share),
                  label: Text(
                    theirs == null ? l10n.compareSend : l10n.compareSendBack,
                  ),
                ),
              ),
            ),
    );
  }

  /// The side-by-side.
  List<Widget> _comparison({
    required BuildContext context,
    required StatSnapshot mine,
    required StatSnapshot theirs,
    required CounterRegistry? registry,
    required String language,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(language);
    final sections = AgentComparisonBuilder(
      registry: registry,
    ).build(mine: mine, theirs: theirs);

    return [
      _AgentHeader(
        snapshot: theirs,
        heading: l10n.compareAgainst(theirs.agentName),
      ),
      const SizedBox(height: 12),
      // Said plainly rather than left to be inferred: an agent handed someone
      // else's numbers deserves to know they are not being kept.
      Text(
        l10n.compareNotKept,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      const SizedBox(height: 8),
      for (final section in sections) ...[
        const SizedBox(height: 16),
        Text(
          section.categoryKey == null
              ? l10n.fallbackCategory
              : registry?.categories[section.categoryKey]?.label(language) ??
                    l10n.fallbackCategory,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        // Repeated under every heading rather than pinned at the top: the list
        // runs to sixty counters, and a legend scrolled off the screen tells
        // nobody which column is whose.
        const _ColumnLegend(),
        for (final row in section.rows)
          _Row(
            label:
                registry?.forExportHeader(row.exportHeader)?.label(language) ??
                row.exportHeader,
            row: row,
            numbers: numbers,
          ),
      ],
    ];
  }

  /// What will leave the phone, before it does.
  List<Widget> _sending({
    required BuildContext context,
    required StatSnapshot mine,
    required CounterRegistry? registry,
    required String language,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(language);
    final headers =
        registry?.sortHeaders(mine.counters.keys) ??
        (mine.counters.keys.toList()..sort());

    return [
      Text(l10n.compareIntro, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 20),
      Text(l10n.comparePreviewTitle, style: theme.textTheme.titleSmall),
      const SizedBox(height: 4),
      Text(
        l10n.comparePreviewCount(mine.counters.length),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      const SizedBox(height: 12),
      // My own card, so it is named rather than announced as an opponent.
      _AgentHeader(snapshot: mine, heading: mine.agentName),
      const SizedBox(height: 8),
      // Every value, not a summary: "the agent should read it before it goes
      // anywhere" only means something if all of it is on screen.
      for (final header in headers)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  registry?.forExportHeader(header)?.label(language) ?? header,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                numbers.format(mine.counters[header]),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Future<void> _send(BuildContext context, StatSnapshot mine) async {
    final l10n = AppLocalizations.of(context);
    await SharePlus.instance.share(
      ShareParams(
        subject: l10n.compareSubject,
        text: const ComparisonPayload().encode(mine),
      ),
    );
  }
}

/// Codename, faction, level and date of a snapshot — mine or theirs.
class _AgentHeader extends StatelessWidget {
  const _AgentHeader({required this.snapshot, required this.heading});

  final StatSnapshot snapshot;

  /// The other agent's codename is announced as one ("Against Rival"); mine is
  /// simply named, since this screen is not where I am my own opponent.
  final String heading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final dates = DateFormat(l10n.shortDateFormat, locale);
    final colour = factionColour(snapshot.faction);
    final date = dates.format(snapshot.recordedAt);
    // Our own payloads always carry one; a hand-edited one may not, and a
    // dangling separator reads worse than the app's usual "not known".
    final faction = snapshot.faction.trim().isEmpty
        ? l10n.unknownValue
        : snapshot.faction;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // A dot, never on its own: the faction is written out beside it
            // (§3.9), and an unrecognised one simply has no dot rather than
            // being painted as one of the two.
            if (colour != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colour,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(heading, style: theme.textTheme.titleMedium),
                  Text(
                    snapshot.level == null
                        ? l10n.compareAgentLine(faction, date)
                        : l10n.compareAgentLineWithLevel(
                            '${l10n.fieldLevel} ${snapshot.level}',
                            faction,
                            date,
                          ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColumnLegend extends StatelessWidget {
  const _ColumnLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.outline,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.compareColumnMine,
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              l10n.compareColumnTheirs,
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              l10n.compareColumnDifference,
              textAlign: TextAlign.end,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// One counter: its name, then the two totals and the gap between them.
///
/// Two lines rather than four columns. `XM Recharged` runs to nine digits, and
/// a name-plus-three-numbers row squeezed every one of them into an ellipsis
/// on a 360pt phone.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.row, required this.numbers});

  final String label;
  final ComparisonRow row;
  final NumberFormat numbers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final figures = theme.textTheme.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Row(
            children: [
              Expanded(
                child: Text(
                  _value(l10n, row.mine),
                  textAlign: TextAlign.end,
                  style: figures,
                ),
              ),
              Expanded(
                child: Text(
                  _value(l10n, row.theirs),
                  textAlign: TextAlign.end,
                  style: figures,
                ),
              ),
              Expanded(
                child: Text(
                  _difference(l10n),
                  textAlign: TextAlign.end,
                  style: figures?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _value(AppLocalizations l10n, int? value) =>
      value == null ? l10n.compareNoValue : numbers.format(value);

  /// A signed number, so who is ahead is carried by the text and not by a
  /// colour or an arrow (§3.9). Blank on either side means no gap to state,
  /// because a missing counter is not a zero (§3.1.2).
  String _difference(AppLocalizations l10n) {
    final difference = row.difference;
    if (difference == null) return l10n.compareNoValue;
    if (difference == 0) return l10n.compareTied;
    final formatted = numbers.format(difference.abs());
    return difference > 0 ? '+$formatted' : '−$formatted';
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final ComparisonPayloadError error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.compareErrorTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              switch (error) {
                ComparisonPayloadError.unsupportedVersion =>
                  l10n.compareErrorUnsupportedVersion,
                ComparisonPayloadError.notCumulative =>
                  l10n.compareErrorNotCumulative,
                ComparisonPayloadError.malformed => l10n.compareErrorMalformed,
              },
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Icon(
            Icons.group_outlined,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
