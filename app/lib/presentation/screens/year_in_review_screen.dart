import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../../domain/year_in_review.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../tier_labels.dart';
import '../widgets/medal_icon.dart';

/// A year read back, built on the device from the history alone (#153).
///
/// Nothing here is fetched and nothing is sent. The roadmap filed this under
/// "would need a server" and was wrong — the data is on the phone, and so is
/// everything that reads it.
class YearInReviewScreen extends ConsumerStatefulWidget {
  const YearInReviewScreen({super.key});

  @override
  ConsumerState<YearInReviewScreen> createState() => _YearInReviewScreenState();
}

class _YearInReviewScreenState extends ConsumerState<YearInReviewScreen> {
  int? _year;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final years = ref.watch(recordedYearsProvider);

    // The most recent year with any history, until the agent picks another.
    // Not the calendar year: on 2 January there is nothing in it yet, and an
    // empty screen is a poor way to open a recap.
    final year = _year ?? (years.isEmpty ? DateTime.now().year : years.first);
    final review = ref.watch(yearInReviewProvider(year));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.yearInReviewTitle('$year')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
        actions: [
          if (years.length > 1)
            PopupMenuButton<int>(
              icon: const Icon(Icons.calendar_today_outlined),
              onSelected: (value) => setState(() => _year = value),
              itemBuilder: (context) => [
                for (final candidate in years)
                  PopupMenuItem(value: candidate, child: Text('$candidate')),
              ],
            ),
        ],
      ),
      body: review == null
          ? _Empty(year: year)
          : _Review(review: review, year: year),
    );
  }
}

class _Review extends ConsumerWidget {
  const _Review({required this.review, required this.year});

  final YearInReview review;
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final language = Localizations.localeOf(context).languageCode;
    final registry = ref.watch(counterRegistryProvider).asData?.value;

    final dates = DateFormat(l10n.shortDateFormat, locale);
    final numbers = NumberFormat.decimalPattern(language);

    String label(String header) =>
        registry?.forExportHeader(header)?.label(language) ?? header;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          l10n.yearInReviewSpan(
            dates.format(review.from),
            dates.format(review.to),
          ),
          style: theme.textTheme.titleMedium,
        ),
        // Said before anything else it might undercut. Someone who started in
        // September should read "four months" before they read a total.
        if (review.isPartial)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.yearInReviewPartial(dates.format(review.from)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),

        if (review.gains.isNotEmpty) ...[
          _Heading(text: l10n.yearInReviewGains),
          for (final gain in review.gains)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label(gain.exportHeader)),
              trailing: Text(
                l10n.yearInReviewGain(numbers.format(gain.to - gain.from)),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],

        if (review.medals.isNotEmpty) ...[
          _Heading(text: l10n.yearInReviewMedals),
          for (final medal in review.medals)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 28,
                  child: MedalIcon(
                    counterKey:
                        registry?.forExportHeader(medal.exportHeader)?.key ??
                        medal.exportHeader,
                    tierName: medal.tier.name,
                  ),
                ),
              ),
              title: Text(
                l10n.yearInReviewMedal(
                  label(medal.exportHeader),
                  tierLabel(l10n, medal.tier.name),
                ),
              ),
              subtitle: Text(dates.format(medal.seenOn)),
            ),
        ],

        const SizedBox(height: 24),
        if (review.busiestMonth != null)
          Text(
            l10n.yearInReviewBusiest(
              DateFormat.MMMM(
                locale,
              ).format(DateTime(year, review.busiestMonth!)),
            ),
            style: theme.textTheme.bodyMedium,
          ),
        // Last, and never omitted: it is the caveat on everything above.
        if (review.longestGap != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.yearInReviewGap(review.longestGap!.inDays),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.year});

  final int year;

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
              l10n.yearInReviewEmpty('$year'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.yearInReviewEmptyDetail,
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
