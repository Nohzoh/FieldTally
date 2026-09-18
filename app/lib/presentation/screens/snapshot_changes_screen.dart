import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/counter_registry.dart';
import '../../domain/snapshot_changes.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';

/// What one snapshot recorded that the one before it had not (#147).
///
/// The rest of the app answers "where do I stand". This screen answers "what
/// did that afternoon produce" — the same history, read between two points
/// rather than at one.
class SnapshotChangesScreen extends ConsumerWidget {
  const SnapshotChangesScreen({required this.snapshotId, super.key});

  final String snapshotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final changes = ref.watch(snapshotChangesProvider(snapshotId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.snapshotChangesTitle)),
      body: switch (changes) {
        // The earliest snapshot has nothing before it. Said plainly rather
        // than shown as an empty list, which would read as a bug.
        null => _Message(text: l10n.snapshotChangesNoPrevious),
        final c when c.isEmpty => _Message(text: l10n.snapshotChangesNone),
        final c => _Changes(changes: c),
      },
    );
  }
}

class _Changes extends ConsumerWidget {
  const _Changes({required this.changes});

  final SnapshotChanges changes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final language = Localizations.localeOf(context).languageCode;

    final rows = <Widget>[_Header(changes: changes)];
    for (final section in changes.sections) {
      rows.add(
        _CategoryHeading(
          categoryKey: section.categoryKey,
          registry: registry,
          language: language,
        ),
      );
      for (final change in section.changes) {
        rows.add(
          _ChangeTile(
            change: change,
            label:
                registry
                    ?.forExportHeader(change.exportHeader)
                    ?.label(language) ??
                change.exportHeader,
          ),
        );
      }
    }

    return ListView(padding: const EdgeInsets.only(bottom: 24), children: rows);
  }
}

/// The interval itself: both moments, how long it lasted, how much moved.
class _Header extends StatelessWidget {
  const _Header({required this.changes});

  final SnapshotChanges changes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat(l10n.snapshotDateFormat, locale);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.snapshotChangesInterval(
              format.format(changes.from),
              format.format(changes.to),
            ),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            // Two facts about the interval, and neither is a claim about what
            // happened during it: the app knows when the agent recorded, not
            // when they played.
            '${l10n.snapshotChangesSpan(changes.span.inDays)}'
            ' · '
            '${l10n.snapshotChangesCount(changes.changedCount)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeading extends StatelessWidget {
  const _CategoryHeading({
    required this.categoryKey,
    required this.registry,
    required this.language,
  });

  final String categoryKey;
  final CounterRegistry? registry;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        registry?.categories[categoryKey]?.label(language) ??
            l10n.fallbackCategory,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ChangeTile extends StatelessWidget {
  const _ChangeTile({required this.change, required this.label});

  final CounterChange change;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final numbers = NumberFormat.decimalPattern(locale);

    final delta = change.delta;
    final formatted = numbers.format(delta.abs());

    return ListTile(
      title: Text(label),
      subtitle: Text(
        l10n.snapshotChangesValues(
          numbers.format(change.from),
          numbers.format(change.to),
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      // The sign is a character, never a colour on its own (§3.9): a counter
      // that went down on a recursion reads as "−15" whatever the theme does.
      trailing: Text(
        delta >= 0 ? '+$formatted' : '−$formatted',
        style: theme.textTheme.titleMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
          color: delta >= 0
              ? theme.colorScheme.primary
              : theme.colorScheme.error,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
