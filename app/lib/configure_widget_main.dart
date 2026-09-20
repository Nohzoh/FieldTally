import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'presentation/screens/configure_widget_screen.dart';

/// A separate, minimal `MaterialApp` rather than `FieldTallyApp` itself: this
/// engine exists to show exactly one screen before finishing immediately, has
/// no navigation stack worth a router, and none of `StartupTasks`'
/// standing work belongs to a screen that outlives its own save button.
class ConfigureWidgetApp extends StatelessWidget {
  const ConfigureWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    // WidgetConfigureActivity.getInitialRoute() hands this engine
    // "/configure-widget/<appWidgetId>" — read directly, since there is no
    // router here to parse it for us.
    final route = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    // 0, not -1: that is AppWidgetManager.INVALID_APPWIDGET_ID's real value.
    // Unreachable in practice — WidgetConfigureActivity never starts this
    // engine at all once it has read an invalid id from its own intent — but
    // worth naming correctly rather than inventing a sentinel of its own.
    final appWidgetId = int.tryParse(route.split('/').lastOrNull ?? '') ?? 0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ConfigureWidgetScreen(appWidgetId: appWidgetId),
    );
  }
}
