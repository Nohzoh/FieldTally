import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Entry point for the small, separate Flutter engine Android starts to run
/// `WidgetConfigureActivity` (#181, #189) -- the `APPWIDGET_CONFIGURE` flow
/// the launcher drives when a widget instance is first placed, or reopened
/// later from its own long-press → Configure.
///
/// Declared here, in `main.dart`'s own library, rather than in
/// `configure_widget_main.dart` where [ConfigureWidgetApp] lives: Android
/// only sets `getDartEntrypointFunctionName()`, not
/// `getDartEntrypointLibraryUri()` (#189 first tried adding that override,
/// confirmed via `adb logcat` to still fail identically -- "Could not
/// resolve main entrypoint function" -- against this exact engine version),
/// so the entrypoint is looked up as a top-level member of the *root*
/// library. `@pragma('vm:entry-point')` is what keeps the AOT compiler from
/// tree-shaking a function `main()` itself never calls -- it is only ever
/// looked up by name, from the native side.
@pragma('vm:entry-point')
void configureWidgetMain() {
  runApp(const ProviderScope(child: ConfigureWidgetApp()));
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
