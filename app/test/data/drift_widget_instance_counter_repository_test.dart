import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/repositories/drift_widget_instance_counter_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FieldTallyDatabase db;
  late DriftWidgetInstanceCounterRepository repository;

  setUp(() {
    db = FieldTallyDatabase(NativeDatabase.memory());
    repository = DriftWidgetInstanceCounterRepository(db);
  });

  tearDown(() => db.close());

  test('a freshly placed instance has nothing selected', () async {
    expect(await repository.pinnedFor(1), isEmpty);
  });

  test('stores the selection and its order', () async {
    await repository.setPinnedFor(1, ['Recursions', 'Hacks', 'Level']);

    expect(await repository.pinnedFor(1), ['Recursions', 'Hacks', 'Level']);
  });

  test('replacing the selection drops what was there before', () async {
    await repository.setPinnedFor(1, ['Hacks', 'Level']);
    await repository.setPinnedFor(1, ['Recursions']);

    expect(await repository.pinnedFor(1), ['Recursions']);
  });

  test('clearing the selection is allowed', () async {
    await repository.setPinnedFor(1, ['Hacks']);
    await repository.setPinnedFor(1, []);

    expect(await repository.pinnedFor(1), isEmpty);
  });

  test('the stream emits after each change', () async {
    final emissions = <List<String>>[];
    final subscription = repository.watchPinnedFor(1).listen(emissions.add);

    await repository.setPinnedFor(1, ['Hacks']);
    await repository.setPinnedFor(1, ['Hacks', 'Level']);
    await Future<void>.delayed(Duration.zero);

    await subscription.cancel();
    expect(emissions.last, ['Hacks', 'Level']);
  });

  group('more than one instance (#181)', () {
    test('each keeps an entirely separate selection', () async {
      await repository.setPinnedFor(1, ['Hacks']);
      await repository.setPinnedFor(2, ['Unique Portals Visited']);

      expect(await repository.pinnedFor(1), ['Hacks']);
      expect(await repository.pinnedFor(2), ['Unique Portals Visited']);
    });

    test('replacing one instance leaves another untouched', () async {
      await repository.setPinnedFor(1, ['Hacks']);
      await repository.setPinnedFor(2, ['Unique Portals Visited']);
      await repository.setPinnedFor(1, ['Recursions']);

      expect(await repository.pinnedFor(1), ['Recursions']);
      expect(await repository.pinnedFor(2), ['Unique Portals Visited']);
    });

    test('deleting one instance leaves another untouched', () async {
      await repository.setPinnedFor(1, ['Hacks']);
      await repository.setPinnedFor(2, ['Unique Portals Visited']);

      await repository.deleteFor(1);

      expect(await repository.pinnedFor(1), isEmpty);
      expect(await repository.pinnedFor(2), ['Unique Portals Visited']);
    });
  });
}
