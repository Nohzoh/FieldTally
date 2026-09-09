import 'dart:io';

import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/repositories/snapshot_repository.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const allTimePath = 'test/fixtures/sample_export_all_time.tsv';
const weekPath = 'test/fixtures/sample_export_week.tsv';
const seedPath = 'assets/counters_registry_seed.json';

String fixture(String path) => File(path).readAsStringSync();

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  late FieldTallyDatabase db;
  late ProviderContainer container;

  /// Monte l'app entière — routeur compris — sur une base en mémoire et le
  /// registre réel lu depuis le disque, pour ne dépendre d'aucun mock.
  Future<SnapshotRepository> pumpApp(WidgetTester tester) async {
    // La surface par défaut de flutter_test (800x600 logiques) ne correspond à
    // aucun téléphone : elle est trop courte, et une ListView n'y construit
    // pas les enfants situés sous la ligne de flottaison — ce qui rendrait des
    // éléments introuvables pour de mauvaises raisons. On simule un écran
    // ordinaire (360x800 logiques).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    final registry =
        const CounterRegistryLoader().parse(File(seedPath).readAsStringSync());

    final overrides = [
      databaseProvider.overrideWithValue(db),
      counterRegistryProvider.overrideWith((ref) async => registry),
    ];
    container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    addTearDown(db.close);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: createRouter(),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    return container.read(snapshotRepositoryProvider);
  }

  /// Colle un texte dans le champ et lance l'analyse.
  Future<void> analyze(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.widgetWithText(FilledButton, 'Analyser'));
    await tester.pumpAndSettle();
  }

  Future<void> goToAddScreen(WidgetTester tester) async {
    await tester.tap(find.text('Ajouter un relevé'));
    await tester.pumpAndSettle();
  }

  group('écran d\'accueil', () {
    testWidgets('affiche un état vide quand aucun relevé n\'existe',
        (tester) async {
      await pumpApp(tester);

      expect(find.text('Aucun relevé pour l\'instant'), findsOneWidget);
    });

    testWidgets('mène à l\'écran d\'ajout', (tester) async {
      await pumpApp(tester);
      await goToAddScreen(tester);

      expect(find.text('Texte exporté par Ingress'), findsOneWidget);
    });
  });

  group('aperçu avant enregistrement (§3.1)', () {
    testWidgets('un export valide affiche les valeurs détectées', (tester) async {
      await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(allTimePath));

      expect(find.text('Aperçu'), findsOneWidget);
      expect(find.text('AgentDemo'), findsOneWidget);
      expect(find.text('ALL TIME'), findsOneWidget);
      // Les 59 compteurs sont annoncés avant tout enregistrement.
      expect(find.text('59'), findsOneWidget);
      expect(find.textContaining('Rien n\'est enregistré'), findsOneWidget);
    });

    testWidgets('les compteurs sont groupés par catégorie du jeu', (tester) async {
      await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(allTimePath));

      // Catégories reprises de l'écran de stats d'Ingress (Annexe A).
      expect(find.text('Découverte'), findsOneWidget);
      expect(find.text('Combat'), findsOneWidget);
      expect(find.text('Événements'), findsOneWidget);
    });

    testWidgets('rien n\'est enregistré tant qu\'on n\'a pas confirmé',
        (tester) async {
      final repository = await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(allTimePath));

      expect(await repository.all(), isEmpty);
    });

    testWidgets('un texte illisible affiche une erreur explicite et rien d\'autre',
        (tester) async {
      await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, 'ceci n\'est pas un export Ingress');

      expect(find.text('Lecture impossible'), findsOneWidget);
      expect(find.text('Aperçu'), findsNothing);
    });
  });

  group('enregistrement', () {
    testWidgets('confirmer enregistre le relevé et revient à l\'accueil',
        (tester) async {
      final repository = await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(allTimePath));

      await tester.tap(find.text('Enregistrer ce relevé'));
      await tester.pumpAndSettle();

      final all = await repository.all();
      expect(all, hasLength(1));
      expect(all.single.snapshot.counters, hasLength(59));
      expect(find.text('Aucun relevé pour l\'instant'), findsNothing);
    });
  });

  group('garde-fous à l\'écran (§3.1.3)', () {
    testWidgets('un export WEEK est signalé et le bouton principal refuse',
        (tester) async {
      await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(weekPath));

      expect(find.text('Période partielle détectée'), findsOneWidget);
      expect(find.textContaining('WEEK'), findsWidgets);

      // L'action mise en avant est celle qui protège l'historique ; le
      // contournement n'est pas un bouton posé à côté du message.
      expect(find.widgetWithText(FilledButton, 'Ne pas enregistrer'),
          findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Enregistrer ce relevé'),
          findsNothing);
      expect(find.text('Enregistrer quand même…'), findsOneWidget);
    });

    testWidgets(
      'sur un petit écran, la raison du blocage reste visible sans défiler',
      (tester) async {
        // Régression constatée sur l'émulateur (320x640) : la consigne et le
        // champ de collage occupaient tout l'écran, si bien qu'on voyait les
        // boutons de décision sans le message qui les justifie.
        await pumpApp(tester);
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;

        await goToAddScreen(tester);
        await analyze(tester, fixture(weekPath));

        final card = find.text('Période partielle détectée');
        expect(card, findsOneWidget);

        final rect = tester.getRect(card);
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(640),
            reason: 'le message de blocage doit tenir dans l\'écran');
      },
    );

    testWidgets('passer outre demande une confirmation explicite', (tester) async {
      final repository = await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(weekPath));

      await tester.tap(find.text('Enregistrer quand même…'));
      await tester.pumpAndSettle();

      expect(find.text('Enregistrer malgré l\'anomalie ?'), findsOneWidget);

      // Annuler ne doit rien enregistrer.
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(await repository.all(), isEmpty);
    });

    testWidgets('confirmer le contournement enregistre malgré tout',
        (tester) async {
      final repository = await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(weekPath));

      await tester.tap(find.text('Enregistrer quand même…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer quand même'));
      await tester.pumpAndSettle();

      expect(await repository.all(), hasLength(1));
    });

    testWidgets(
      'un WEEK importé après un ALL TIME déclenche le garde-fou comportemental',
      (tester) async {
        await pumpApp(tester);

        // Premier relevé, légitime.
        await goToAddScreen(tester);
        await analyze(tester, fixture(allTimePath));
        await tester.tap(find.text('Enregistrer ce relevé'));
        await tester.pumpAndSettle();

        // Second relevé, mauvaise période : les deux garde-fous sautent.
        await goToAddScreen(tester);
        await analyze(tester, fixture(weekPath));

        expect(find.text('Période partielle détectée'), findsOneWidget);

        // La liste nominative des reculs est affichée pour que l'utilisateur
        // juge par lui-même — les dix plus gros, le plus spectaculaire en
        // tête, avec un décompte du reste plutôt qu'un mur de 55 lignes.
        expect(find.textContaining('XM collecté'), findsOneWidget);
        expect(find.textContaining('et 45 autres'), findsOneWidget);
      },
    );
  });

  group('suppression', () {
    testWidgets('supprimer un relevé demande confirmation puis le retire',
        (tester) async {
      final repository = await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(allTimePath));
      await tester.tap(find.text('Enregistrer ce relevé'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer ce relevé ?'), findsOneWidget);

      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(await repository.all(), isEmpty);
      expect(find.text('Aucun relevé pour l\'instant'), findsOneWidget);
    });
  });
}
