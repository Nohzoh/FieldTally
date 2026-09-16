import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/changelog_release.dart';
import '../../l10n/app_localizations.dart';

/// How much the dialog says (#112).
///
/// The two callers want opposite things from the same notes. One interrupts an
/// agent who opened the app to use it; the other was tapped on purpose. So the
/// dialog that arrives uninvited stays to a headline, and the one that was
/// asked for keeps everything.
enum ChangelogDetail {
  /// A line per release, and a link to the rest.
  headlines,

  /// Every note bundled, grouped as features and fixes.
  full,
}

/// Where a release's notes live in full.
///
/// Derived from the version rather than stored: the release workflow creates
/// the tag as `v<version>`, so the two cannot disagree without the tag itself
/// being wrong.
Uri releaseUrl(String version) =>
    Uri.parse('https://github.com/Nohzoh/FieldTally/releases/tag/v$version');

/// Shows what changed since the last version this device saw (§9, #45).
///
/// In [ChangelogDetail.full], notes are grouped as features and fixes rather
/// than by release: someone who skipped versions should read one sober list of
/// everything they missed, not a wall of per-version headings.
///
/// The emoji marks each group without being the only thing distinguishing
/// them (§3.9) — the heading text carries the meaning — and there is one per
/// group rather than one per line, since a screen reader announces it too.
Future<void> showChangelogDialog(
  BuildContext context, {
  required List<ChangelogRelease> releases,
  required String languageCode,
  ChangelogDetail detail = ChangelogDetail.full,
}) {
  final l10n = AppLocalizations.of(context);

  if (detail == ChangelogDetail.headlines) {
    if (releases.isEmpty) return Future<void>.value();
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changelogDialogTitle(releases.last.version)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final release in releases)
                _Headline(release: release, languageCode: languageCode),
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

/// One release, said in a line, with a way to read the rest.
class _Headline extends StatelessWidget {
  const _Headline({required this.release, required this.languageCode});

  final ChangelogRelease release;
  final String languageCode;

  /// Says so rather than failing silently, like the About screen's links: a
  /// device with no browser is rare, but a tap that does nothing at all looks
  /// like a broken app.
  ///
  /// Being offline is not that case. The browser opens and reports it itself,
  /// which is its job — hiding the link would take a connectivity check the
  /// app makes nowhere else, and would hide it exactly when an agent might be
  /// one reconnection away from reading the notes.
  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      releaseUrl(release.version),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsLinkFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final title = release.title(languageCode);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The version alone when no headline was written: a release built
          // before this field existed still has something to show (#112).
          Text(
            title == null
                ? release.version
                : l10n.changelogHeadline(release.version, title),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          InkWell(
            onTap: () => _open(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                l10n.changelogFullNotes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
