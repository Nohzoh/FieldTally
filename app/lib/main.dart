import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/locale_resolution.dart';
import 'core/router.dart';
import 'l10n/app_localizations.dart';
import 'presentation/incoming_share_listener.dart';
import 'presentation/providers/providers.dart';
import 'presentation/startup_tasks.dart';

void main() {
  runApp(const ProviderScope(child: FieldTallyApp()));
}

class FieldTallyApp extends ConsumerWidget {
  const FieldTallyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Defaults while the preferences load: one frame of the app's own teal
    // following the system is a better first impression than a blank one.
    final mode = ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;
    final seed = ref.watch(themeSeedProvider);

    return StartupTasks(
      child: IncomingShareListener(
        router: router,
        child: MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          // Light/dark theme following the system unless the agent overrode
          // it, generated from the app's own colour or from their faction
          // (§3.9).
          themeMode: mode,
          theme: ThemeData(
            colorSchemeSeed: seed,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: seed,
            brightness: Brightness.dark,
          ),
          // Null follows the device (§3.10). The app has both translations the
          // specification asks for, and imposing one on a phone set to the
          // other served nobody.
          locale: ref.watch(localeProvider).asData?.value,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: resolveLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
  }
}
