import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/repositories/drift_pinned_counter_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FieldTallyDatabase db;
  late DriftPinnedCounterRepository repository;

  setUp(() {
    db = FieldTallyDatabase(NativeDatabase.memory());
    repository = DriftPinnedCounterRepository(db);
  });

  tearDown(() => db.close());

  test('a fresh install has nothing pinned', () async {
    // Empty rather than pre-seeded: the defaults are applied at the provider
    // level, so choosing nothing stays distinguishable from choosing nothing yet.
    expect(await repository.pinned(), isEmpty);
  });

  test('stores the selection and its order', () async {
    await repository.setPinned(['Recursions', 'Hacks', 'Level']);

    expect(await repository.pinned(), ['Recursions', 'Hacks', 'Level']);
  });

  test('replacing the selection drops what was there before', () async {
    await repository.setPinned(['Hacks', 'Level']);
    await repository.setPinned(['Recursions']);

    expect(await repository.pinned(), ['Recursions']);
  });

  test('reordering the same counters is preserved', () async {
    await repository.setPinned(['Hacks', 'Level']);
    await repository.setPinned(['Level', 'Hacks']);

    expect(await repository.pinned(), ['Level', 'Hacks']);
  });

  test('clearing the selection is allowed', () async {
    await repository.setPinned(['Hacks']);
    await repository.setPinned([]);

    expect(await repository.pinned(), isEmpty);
  });

  test('the stream emits after each change', () async {
    final emissions = <List<String>>[];
    final subscription = repository.watchPinned().listen(emissions.add);

    await repository.setPinned(['Hacks']);
    await repository.setPinned(['Hacks', 'Level']);
    await Future<void>.delayed(Duration.zero);

    await subscription.cancel();
    expect(emissions.last, ['Hacks', 'Level']);
  });
}
