import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'presentation/screens/configure_widget_screen.dart';

/// Entry point for the small, separate Flutter engine Android starts to run
/// `WidgetConfigureActivity` (#181) — the `APPWIDGET_CONFIGURE` flow the
/// launcher drives when a widget instance is first placed, or reopened later
/// from its own long-press → Configure. Deliberately not `main()`:
/// `WidgetConfigureActivity.getDartEntrypointFunctionName()` names this
/// function instead, so an ordinary app launch never touches this file.
///
/// `@pragma('vm:entry-point')` is what keeps the AOT compiler from
/// tree-shaking a function main.dart's own `main()` never calls — it is only
/// ever looked up by name, from the native side.
@pragma('vm:entry-point')
void configureWidgetMain() {
  runApp(const ProviderScope(child: ConfigureWidgetApp()));
}

/// A separate, minimal `MaterialApp` rather than `FieldTallyApp` itself: this
/// engine exists to show exactly one screen before finishing immediately, has
/// no navigation stack worth a router, and none of `StartupTasks`'
/// standing work belongs to a screen that outlives its own save button.
class ConfigureWidgetApp extends StatelessWidget {
  const ConfigureWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    // WidgetConfigureActivity.getInitialRoute() hands this engine
    // "/configure-widget/<appWidgetId>", optionally with a
    // "?preselect=<counter>" query when placed from CounterDetailScreen
    // (#181, path B) — read directly, since there is no router here to parse
    // it for us.
    final route = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    final uri = Uri.parse(route);
    // 0, not -1: that is AppWidgetManager.INVALID_APPWIDGET_ID's real value.
    // Unreachable in practice — WidgetConfigureActivity never starts this
    // engine at all once it has read an invalid id from its own intent — but
    // worth naming correctly rather than inventing a sentinel of its own.
    final appWidgetId = int.tryParse(uri.pathSegments.lastOrNull ?? '') ?? 0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ConfigureWidgetScreen(
        appWidgetId: appWidgetId,
        preselectedCounter: uri.queryParameters['preselect'],
      ),
    );
  }
}
