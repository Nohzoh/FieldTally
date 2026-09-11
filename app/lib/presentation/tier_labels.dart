import '../l10n/app_localizations.dart';

/// The display name of a badge tier (§3.6, §3.7).
///
/// The registry stores tiers under stable lowercase keys (`bronze`, `onyx`);
/// translating them lives here rather than in each widget, so a card and a
/// notification never disagree about what to call the same medal.
String tierLabel(AppLocalizations l10n, String name) => switch (name) {
  'bronze' => l10n.projectionTier_bronze,
  'silver' => l10n.projectionTier_silver,
  'gold' => l10n.projectionTier_gold,
  'platinum' => l10n.projectionTier_platinum,
  'onyx' => l10n.projectionTier_onyx,
  // A tier the app does not know the name of still shows, under whatever
  // the registry called it.
  _ => name,
};
