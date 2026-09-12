import 'package:flutter/material.dart';

import '../../domain/models/changelog_release.dart';
import '../../l10n/app_localizations.dart';

/// Shows what changed, grouped as features and fixes rather than by release:
/// someone who skipped versions should read one sober list of everything they
/// missed, not a wall of per-version headings.
///
/// The emoji marks each group without being the only thing distinguishing
/// them (§3.9) — the heading text carries the meaning — and there is one per
/// group rather than one per line, since a screen reader announces it too.
Future<void> showChangelogDialog(
  BuildContext context, {
  required List<ChangelogRelease> releases,
  required String languageCode,
}) {
  final l10n = AppLocalizations.of(context);

  final features = [
    for (final release in releases) ...release.features(languageCode),
  ];
  final fixes = [
    for (final release in releases) ...release.fixes(languageCode),
  ];
  if (features.isEmpty && fixes.isEmpty) return Future<void>.value();

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.changelogDialogTitle(releases.last.version)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (features.isNotEmpty)
              _ChangelogSection(
                heading: l10n.changelogNewHeading,
                entries: features,
              ),
            if (features.isNotEmpty && fixes.isNotEmpty)
              const SizedBox(height: 16),
            if (fixes.isNotEmpty)
              _ChangelogSection(
                heading: l10n.changelogFixedHeading,
                entries: fixes,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}

class _ChangelogSection extends StatelessWidget {
  const _ChangelogSection({required this.heading, required this.entries});

  final String heading;
  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(heading, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(entry)),
              ],
            ),
          ),
      ],
    );
  }
}
