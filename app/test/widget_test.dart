// Test de fumée : l'app se construit et affiche l'écran d'attente.
// À remplacer par de vrais tests widget quand les écrans arriveront (§5.3).

import 'package:flutter_test/flutter_test.dart';

import 'package:fieldtally/main.dart';

void main() {
  testWidgets('l\'app démarre sur l\'écran d\'attente', (tester) async {
    await tester.pumpWidget(const FieldTallyApp());

    expect(find.byType(PlaceholderHomeScreen), findsOneWidget);
    expect(find.text('FieldTally'), findsWidgets);
  });
}
