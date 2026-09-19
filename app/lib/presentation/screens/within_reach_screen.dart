import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../domain/badges_within_reach.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../tier_labels.dart';
import '../widgets/medal_icon.dart';

/// Which badges the recent pace puts within reach, soonest first (#148).
///
/// The counter list can already sort by proximity to the next tier, but it
/// measures that as the share of the stretch already crossed — a different
/// question, and one that puts a counter four hundred days out above a
/// counter three days out.
class WithinReachScreen extends ConsumerWidget {
  const WithinReachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final badges = ref.watch(withinReachProvider);
    final snapshots = ref.watch(snapshotsProvider).asData?.value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.withinReachTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: badges.isEmpty
          ? _Empty(
              // Two snapshots set a pace. With fewer, nothing here is a
              // statement about the agent's play — there is simply nothing to
              // measure yet, and saying "nothing is within reach" would read
              // as a verdict.
              detail: snapshots.length < 2
                  ? l10n.withinReachNeedsHistory
                  : l10n.withinReachEmptyDetail,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: badges.length + 1,
              itemBuilder: (context, index) => index == 0
                  ? const _Window()
                  : _BadgeTile(badge: badges[index - 1]),
            ),
    );
  }
}

/// States the window the ranking used, rather than leaving it assumed: the
/// whole order changes with it.
class _Window extends StatelessWidget {
  const _Window();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        l10n.withinReachWindow,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}

class _BadgeTile extends ConsumerWidget {
  const _BadgeTile({required this.badge});

  final ReachableBadge badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final language = Localizations.localeOf(context).languageCode;

    final enrichment = registry?.forExportHeader(badge.exportHeader);
    final next = badge.projection.next;

    return ListTile(
      // Straight to the counter, where the projection card says the rest: the
      // date, the pace, how much is left. This list is the ranking, not a
      // second place for the same detail.
      onTap: () => context.go(Routes.counterDetail(badge.exportHeader)),
      // The emblem is the one being chased rather than the one already held,
      // which is what the row is about. It says nothing a screen reader
      // cannot read from the subtitle beside it (§3.9).
      leading: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 28,
          child: enrichment == null || next == null
              ? null
              : MedalIcon(counterKey: enrichment.key, tierName: next.name),
        ),
      ),
      title: Text(enrichment?.label(language) ?? badge.exportHeader),
      subtitle: Text(
        l10n.withinReachDays(
          next == null ? '' : tierLabel(l10n, next.name),
          // Rounded up, and "about" in the wording: a pace measured over a
          // month does not support a number to the day, and printing 6.7
          // would claim a precision the estimate does not have.
          badge.days.ceil(),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.withinReachEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
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
      ),
    );
  }
}
