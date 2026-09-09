import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Les dates sont formatées en français dès maintenant ; la bascule complète
  // FR/EN par fichiers .arb viendra avec le reste de l'i18n (§3.10).
  await initializeDateFormatting('fr');

  runApp(const ProviderScope(child: FieldTallyApp()));
}

class FieldTallyApp extends StatelessWidget {
  const FieldTallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FieldTally',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // Thème clair/sombre suivant le système (§3.9).
      theme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
