import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';

/// Preferences (§3.1.4).
///
/// One setting so far, and it is the one the spec insists on: the single
/// network request the app makes must be switchable off, so anyone who wants a
/// strictly offline app can have one. The wording states plainly what is
/// downloaded and that nothing is sent.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final enabled = ref.watch(onlineRegistryUpdatesProvider).asData?.value ?? true;
    final registry = ref.watch(counterRegistryProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.settingsDataSection),
          SwitchListTile(
            value: enabled,
            title: Text(l10n.settingsOnlineUpdates),
            subtitle: Text(l10n.settingsOnlineUpdatesDetail),
            isThreeLine: true,
            onChanged: (value) => ref
                .read(counterRegistryServiceProvider)
                .setOnlineUpdatesEnabled(value),
          ),
          if (registry != null)
            ListTile(
              dense: true,
              title: Text(l10n.settingsRegistryCounters(registry.length)),
              subtitle: registry.updatedAt.isEmpty
                  ? null
                  : Text(l10n.settingsRegistryUpdatedAt(registry.updatedAt)),
            ),
          const Divider(),
          _SectionHeader(title: l10n.settingsAboutSection),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              l10n.disclaimer,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall
            ?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}
