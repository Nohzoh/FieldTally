// Point d'entrée FieldTally — squelette.
//
// Aucune fonctionnalité n'est encore branchée : ni parsing, ni base locale, ni
// écrans. Ce fichier existe pour que le projet compile et que la CI ait quelque
// chose à construire. Les écrans arrivent à l'itération suivante (spec §3.3+).

import 'package:flutter/material.dart';

void main() => runApp(const FieldTallyApp());

class FieldTallyApp extends StatelessWidget {
  const FieldTallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldTally',
      debugShowCheckedModeBanner: false,
      // Thème clair/sombre suivant le système (§3.9).
      theme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
      home: const PlaceholderHomeScreen(),
    );
  }
}

/// Écran d'attente, remplacé par le vrai tableau de bord (§3.3).
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('FieldTally')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('FieldTally', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Squelette du projet — les fonctionnalités arrivent.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Outil non-officiel, sans lien avec Niantic. '
                '« Ingress » est une marque de Niantic, Inc.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
