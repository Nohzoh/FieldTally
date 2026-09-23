import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/parsing/parse_exception.dart';
import '../../domain/csv_import.dart';
import '../../l10n/app_localizations.dart';
import '../messages.dart';
import '../providers/providers.dart';

/// Why a file could not be read at all.
///
/// Shared by both import screens (#191): the failure is the same shape
/// whichever format was being read, and two copies of it would be two places
/// to forget.
class ImportErrorCard extends StatelessWidget {
  const ImportErrorCard({super.key, required this.error});

  final ExportParseException error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.parseErrorTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.message(l10n),
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}

/// What a file would do that stops it being imported unasked (§3.1.3).
///
/// Both guards land here. A migration file can only ever trip the behavioural
/// one, since Appendix B declares no period; a FieldTally export can trip
/// either.
class ImportAnomalyCard extends ConsumerWidget {
  const ImportAnomalyCard({super.key, required this.plan, required this.dates});

  final CsvImportPlan plan;
  final DateFormat dates;

  static const _maxListed = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final extra = plan.regressions.length - _maxListed;

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report_problem, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.importCsvAnomalyTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (plan.hasPartialPeriods) ...[
              const SizedBox(height: 8),
              Text(
                l10n.importPartialPeriod(plan.partialPeriods.length),
                style: TextStyle(color: scheme.onErrorContainer),
              ),
              const SizedBox(height: 4),
              for (final at in plan.partialPeriods.take(_maxListed))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• ${dates.format(at)}',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
            ],
            if (plan.hasRegressions) ...[
              const SizedBox(height: 8),
              Text(
                l10n.importCsvAnomaly(plan.regressions.length),
                style: TextStyle(color: scheme.onErrorContainer),
              ),
              const SizedBox(height: 12),
              for (final found in plan.regressions.take(_maxListed))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• ${l10n.importCsvAnomalyLine(dates.format(found.at), registry?.forExportHeader(found.regression.exportHeader)?.label(language) ?? found.regression.exportHeader, found.regression.previous, found.regression.current)}',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              if (extra > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.anomalyRegressionMore(extra),
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
