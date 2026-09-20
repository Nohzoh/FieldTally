import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Never called from here: WidgetConfigureActivity (native side) looks
// `configureWidgetMain` up by name at runtime, as a second Dart entry point
// (#181). Unimported, that file would never reach the AOT compiler's kernel
// at all, and `@pragma('vm:entry-point')` has nothing to protect from
// tree-shaking if the code was never compiled in to begin with.
// ignore: unused_import
import 'configure_widget_main.dart';
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

    return IncomingShareListener(
      router: router,
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        // Light/dark theme following the system unless the agent overrode
        // it, generated from the app's own colour or from their faction
        // (§3.9).
        themeMode: mode,
        theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
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
        // Inside the routed content rather than wrapping it, and that
        // placement is load-bearing (#154): `Localizations` is installed by
        // `MaterialApp` itself, as an ancestor of `builder`'s context but a
        // descendant of `MaterialApp`'s own position. `StartupTasks` reads
        // `AppLocalizations.of(context)` for both the reminder and the home
        // screen widget, so it has to sit where that resolves. It used to
        // wrap `MaterialApp.router` instead — one layer higher, where the
        // same lookup throws and is swallowed by `_armReminder`'s own
        // `catch`. That silently kept the startup reminder re-arm from ever
        // running; confirmed by probing the exact same call in a throwaway
        // widget test outside this tree, in each position, before moving it.
        builder: (context, child) => StartupTasks(child: child!),
      ),
    );
  }
}
