import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'l10n/app_localizations.dart';
import 'presentation/incoming_share_listener.dart';
import 'presentation/startup_tasks.dart';

void main() {
  runApp(const ProviderScope(child: FieldTallyApp()));
}

class FieldTallyApp extends StatelessWidget {
  const FieldTallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StartupTasks(
      child: IncomingShareListener(
        router: router,
        child: MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          // Light/dark theme following the system (§3.9).
          theme: ThemeData(
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark,
          ),
          // French is the default for now; the locale follows the device once more
          // translations land (§3.10).
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
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
