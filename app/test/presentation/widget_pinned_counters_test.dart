// What the home screen widget's counter selection falls back to (#174).

import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/repositories/pinned_counter_repository.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = FieldTallyDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    // Dispose the container before closing the database: Drift hangs on close
    // while a stream query is still subscribed.
    addTearDown(db.close);
    addTearDown(container.dispose);
  });

  // `widgetPinnedCountersProvider` combines two `StreamProvider`s (the
  // widget's own selection and the dashboard's) — both need their first
  // emission before it reads anything but the initial `AsyncLoading` gap.
  Future<void> warm() async {
    final own = container.listen(widgetOwnPinnedCountersProvider, (_, _) {});
    final dashboard = container.listen(pinnedCountersProvider, (_, _) {});
    addTearDown(own.close);
    addTearDown(dashboard.close);
    await container.read(widgetOwnPinnedCountersProvider.future);
    await container.read(pinnedCountersProvider.future);
  }

  test(
    'with nothing chosen anywhere, follows the dashboard defaults',
    () async {
      await warm();

      expect(
        container.read(widgetPinnedCountersProvider),
        PinnedCounterRepository.defaults,
      );
    },
  );

  test('an empty widget selection follows the dashboard pins', () async {
    await container.read(pinnedCounterRepositoryProvider).setPinned([
      'Recursions',
      'Level',
    ]);
    await warm();

    expect(container.read(widgetPinnedCountersProvider), [
      'Recursions',
      'Level',
    ]);
  });

  test('a widget selection of its own overrides the dashboard pins', () async {
    await container.read(pinnedCounterRepositoryProvider).setPinned([
      'Recursions',
      'Level',
    ]);
    await container.read(widgetPinnedCounterRepositoryProvider).setPinned([
      'Hacks',
    ]);
    await warm();

    expect(container.read(widgetPinnedCountersProvider), ['Hacks']);
  });

  test('following the dashboard live, not a one-time copy — a later dashboard '
      'change is picked up without the widget ever being customised', () async {
    await container.read(pinnedCounterRepositoryProvider).setPinned([
      'Recursions',
    ]);
    await warm();
    expect(container.read(widgetPinnedCountersProvider), ['Recursions']);

    await container.read(pinnedCounterRepositoryProvider).setPinned([
      'Hacks',
      'Level',
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(widgetPinnedCountersProvider), ['Hacks', 'Level']);
  });
}
