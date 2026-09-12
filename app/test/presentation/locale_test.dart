import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/repositories/settings_repository.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldtally/core/locale_resolution.dart';
import 'package:fieldtally/l10n/app_localizations.dart';

import '../support/fake_notification_service.dart';

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = FieldTallyDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ]);
    // Dispose the container before closing the database: Drift hangs on close
    // while a stream query is still subscribed.
    addTearDown(db.close);
    addTearDown(container.dispose);
  });

  Future<void> warm() async {
    final sub = container.listen(localeProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(localeProvider.future);
  }

  group('language (§3.10)', () {
    test('follows the system until the agent chooses one', () async {
      await warm();

      // Null is what MaterialApp reads as "use the device locale". For a long
      // while this was hardcoded to French, so the English translation was
      // shown to nobody.
      expect(container.read(localeProvider).requireValue, isNull);
    });

    test('an explicit choice is kept', () async {
      await container
          .read(settingsRepositoryProvider)
          .write(SettingKeys.locale, 'en');
      await warm();

      expect(
        container.read(localeProvider).requireValue,
        const Locale('en'),
      );
    });

    test('going back to the system clears the override', () async {
      final settings = container.read(settingsRepositoryProvider);
      await settings.write(SettingKeys.locale, 'fr');
      await warm();
      expect(container.read(localeProvider).requireValue, const Locale('fr'));

      await settings.write(SettingKeys.locale, '');
      await Future<void>.delayed(Duration.zero);

      expect(container.read(localeProvider).requireValue, isNull);
    });
  });
  group('resolving the device locale (§3.10)', () {
    final supported = AppLocalizations.supportedLocales;

    test('a supported language is used', () {
      expect(resolveLocale(const Locale('fr'), supported), const Locale('fr'));
      expect(resolveLocale(const Locale('en'), supported), const Locale('en'));
    });

    test('a regional variant still matches its language', () {
      // fr_CA and fr_BE are the same translation here.
      expect(
        resolveLocale(const Locale('fr', 'CA'), supported),
        const Locale('fr'),
      );
    });

    test('an unsupported language falls back to English', () {
      // Explicitly English rather than "whatever is first in the list", so the
      // fallback does not change the day a translation is added.
      expect(resolveLocale(const Locale('es'), supported), const Locale('en'));
      expect(resolveLocale(const Locale('ja'), supported), const Locale('en'));
    });

    test('no device locale at all falls back too', () {
      expect(resolveLocale(null, supported), const Locale('en'));
    });
  });
}
