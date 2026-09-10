import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../../domain/dashboard.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/sparkline.dart';

/// Home screen: a handful of pinned counters (§3.3).
///
/// This exists to fix the problem the audit found in Agent Stats — one
/// catch-all chart nobody can read. A few cards the agent chose, each with its
/// own value, its diff and its own sparkline, beats sixty series on one axis.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cards = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.customise,
            onPressed: () => context.go(Routes.customisePins),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: l10n.countersTitle,
            onPressed: () => context.go(Routes.counters),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.snapshotsTitle,
            onPressed: () => context.go(Routes.snapshots),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(Routes.addSnapshot),
        icon: const Icon(Icons.add),
        label: Text(l10n.addSnapshotAction),
      ),
      body: cards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (list) => list.isEmpty
            ? _Empty(title: l10n.dashboardEmptyTitle, detail: l10n.dashboardEmptyDetail)
            : GridView.count(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                crossAxisCount: 2,
                // Cells are deliberately tall: the card carries a label that
                // may wrap, a large number, a diff and a sparkline, and §3.9
                // requires honouring the system text size — a tight ratio
                // overflows as soon as someone scales their fonts up.
                childAspectRatio: 0.78,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [for (final card in list) _Card(card: card)],
              ),
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.card});

  final DashboardCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(language);

    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final label =
        registry?.forExportHeader(card.counter.exportHeader)?.label(language) ??
            card.counter.exportHeader;
    final delta = card.counter.delta;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.go(Routes.counterDetail(card.counter.exportHeader)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              // The number is the point of the card, so it shrinks to fit
              // rather than wrapping or being clipped.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  numbers.format(card.counter.lastValue),
                  maxLines: 1,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Text(
                delta == null
                    ? l10n.noDelta
                    : '${delta >= 0 ? '+' : '−'}${numbers.format(delta.abs())}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              // A sparkline needs two points; with a single snapshot the card
              // says so rather than drawing a flat line that means nothing.
              // Expanded rather than a fixed height: the trend line is what
              // gives way when space runs short, never the numbers.
              Expanded(
                child: card.hasSparkline
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          height: 30,
                          width: double.infinity,
                          child: Sparkline(values: card.series),
                        ),
                      )
                    : Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          l10n.notEnoughHistory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ),
              ),
            ],
          ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_outlined,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
