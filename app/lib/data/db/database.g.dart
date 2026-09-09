// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SnapshotsTable extends Snapshots
    with TableInfo<$SnapshotsTable, Snapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agentNameMeta = const VerificationMeta(
    'agentName',
  );
  @override
  late final GeneratedColumn<String> agentName = GeneratedColumn<String>(
    'agent_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _factionMeta = const VerificationMeta(
    'faction',
  );
  @override
  late final GeneratedColumn<String> faction = GeneratedColumn<String>(
    'faction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeSpanMeta = const VerificationMeta(
    'timeSpan',
  );
  @override
  late final GeneratedColumn<String> timeSpan = GeneratedColumn<String>(
    'time_span',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    agentName,
    faction,
    timeSpan,
    recordedAt,
    level,
    importedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<Snapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('agent_name')) {
      context.handle(
        _agentNameMeta,
        agentName.isAcceptableOrUnknown(data['agent_name']!, _agentNameMeta),
      );
    } else if (isInserting) {
      context.missing(_agentNameMeta);
    }
    if (data.containsKey('faction')) {
      context.handle(
        _factionMeta,
        faction.isAcceptableOrUnknown(data['faction']!, _factionMeta),
      );
    } else if (isInserting) {
      context.missing(_factionMeta);
    }
    if (data.containsKey('time_span')) {
      context.handle(
        _timeSpanMeta,
        timeSpan.isAcceptableOrUnknown(data['time_span']!, _timeSpanMeta),
      );
    } else if (isInserting) {
      context.missing(_timeSpanMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Snapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Snapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      agentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_name'],
      )!,
      faction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}faction'],
      )!,
      timeSpan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_span'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  $SnapshotsTable createAlias(String alias) {
    return $SnapshotsTable(attachedDatabase, alias);
  }
}

class Snapshot extends DataClass implements Insertable<Snapshot> {
  final String id;
  final String agentName;
  final String faction;

  /// Period declared at import time, kept verbatim: it documents where the
  /// snapshot came from, including when the user overrode a guard.
  final String timeSpan;
  final DateTime recordedAt;
  final int level;

  /// Insertion date, distinct from [recordedAt]: a migration import can create
  /// a snapshot today that is dated two years ago.
  final DateTime importedAt;
  const Snapshot({
    required this.id,
    required this.agentName,
    required this.faction,
    required this.timeSpan,
    required this.recordedAt,
    required this.level,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['agent_name'] = Variable<String>(agentName);
    map['faction'] = Variable<String>(faction);
    map['time_span'] = Variable<String>(timeSpan);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['level'] = Variable<int>(level);
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  SnapshotsCompanion toCompanion(bool nullToAbsent) {
    return SnapshotsCompanion(
      id: Value(id),
      agentName: Value(agentName),
      faction: Value(faction),
      timeSpan: Value(timeSpan),
      recordedAt: Value(recordedAt),
      level: Value(level),
      importedAt: Value(importedAt),
    );
  }

  factory Snapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Snapshot(
      id: serializer.fromJson<String>(json['id']),
      agentName: serializer.fromJson<String>(json['agentName']),
      faction: serializer.fromJson<String>(json['faction']),
      timeSpan: serializer.fromJson<String>(json['timeSpan']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      level: serializer.fromJson<int>(json['level']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'agentName': serializer.toJson<String>(agentName),
      'faction': serializer.toJson<String>(faction),
      'timeSpan': serializer.toJson<String>(timeSpan),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'level': serializer.toJson<int>(level),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  Snapshot copyWith({
    String? id,
    String? agentName,
    String? faction,
    String? timeSpan,
    DateTime? recordedAt,
    int? level,
    DateTime? importedAt,
  }) => Snapshot(
    id: id ?? this.id,
    agentName: agentName ?? this.agentName,
    faction: faction ?? this.faction,
    timeSpan: timeSpan ?? this.timeSpan,
    recordedAt: recordedAt ?? this.recordedAt,
    level: level ?? this.level,
    importedAt: importedAt ?? this.importedAt,
  );
  Snapshot copyWithCompanion(SnapshotsCompanion data) {
    return Snapshot(
      id: data.id.present ? data.id.value : this.id,
      agentName: data.agentName.present ? data.agentName.value : this.agentName,
      faction: data.faction.present ? data.faction.value : this.faction,
      timeSpan: data.timeSpan.present ? data.timeSpan.value : this.timeSpan,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      level: data.level.present ? data.level.value : this.level,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Snapshot(')
          ..write('id: $id, ')
          ..write('agentName: $agentName, ')
          ..write('faction: $faction, ')
          ..write('timeSpan: $timeSpan, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('level: $level, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    agentName,
    faction,
    timeSpan,
    recordedAt,
    level,
    importedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Snapshot &&
          other.id == this.id &&
          other.agentName == this.agentName &&
          other.faction == this.faction &&
          other.timeSpan == this.timeSpan &&
          other.recordedAt == this.recordedAt &&
          other.level == this.level &&
          other.importedAt == this.importedAt);
}

class SnapshotsCompanion extends UpdateCompanion<Snapshot> {
  final Value<String> id;
  final Value<String> agentName;
  final Value<String> faction;
  final Value<String> timeSpan;
  final Value<DateTime> recordedAt;
  final Value<int> level;
  final Value<DateTime> importedAt;
  final Value<int> rowid;
  const SnapshotsCompanion({
    this.id = const Value.absent(),
    this.agentName = const Value.absent(),
    this.faction = const Value.absent(),
    this.timeSpan = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.level = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnapshotsCompanion.insert({
    required String id,
    required String agentName,
    required String faction,
    required String timeSpan,
    required DateTime recordedAt,
    required int level,
    required DateTime importedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       agentName = Value(agentName),
       faction = Value(faction),
       timeSpan = Value(timeSpan),
       recordedAt = Value(recordedAt),
       level = Value(level),
       importedAt = Value(importedAt);
  static Insertable<Snapshot> custom({
    Expression<String>? id,
    Expression<String>? agentName,
    Expression<String>? faction,
    Expression<String>? timeSpan,
    Expression<DateTime>? recordedAt,
    Expression<int>? level,
    Expression<DateTime>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (agentName != null) 'agent_name': agentName,
      if (faction != null) 'faction': faction,
      if (timeSpan != null) 'time_span': timeSpan,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (level != null) 'level': level,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnapshotsCompanion copyWith({
    Value<String>? id,
    Value<String>? agentName,
    Value<String>? faction,
    Value<String>? timeSpan,
    Value<DateTime>? recordedAt,
    Value<int>? level,
    Value<DateTime>? importedAt,
    Value<int>? rowid,
  }) {
    return SnapshotsCompanion(
      id: id ?? this.id,
      agentName: agentName ?? this.agentName,
      faction: faction ?? this.faction,
      timeSpan: timeSpan ?? this.timeSpan,
      recordedAt: recordedAt ?? this.recordedAt,
      level: level ?? this.level,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (agentName.present) {
      map['agent_name'] = Variable<String>(agentName.value);
    }
    if (faction.present) {
      map['faction'] = Variable<String>(faction.value);
    }
    if (timeSpan.present) {
      map['time_span'] = Variable<String>(timeSpan.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('agentName: $agentName, ')
          ..write('faction: $faction, ')
          ..write('timeSpan: $timeSpan, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('level: $level, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CounterValuesTable extends CounterValues
    with TableInfo<$CounterValuesTable, CounterValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CounterValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _snapshotIdMeta = const VerificationMeta(
    'snapshotId',
  );
  @override
  late final GeneratedColumn<String> snapshotId = GeneratedColumn<String>(
    'snapshot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES snapshots (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exportHeaderMeta = const VerificationMeta(
    'exportHeader',
  );
  @override
  late final GeneratedColumn<String> exportHeader = GeneratedColumn<String>(
    'export_header',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [snapshotId, exportHeader, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'counter_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<CounterValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('snapshot_id')) {
      context.handle(
        _snapshotIdMeta,
        snapshotId.isAcceptableOrUnknown(data['snapshot_id']!, _snapshotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotIdMeta);
    }
    if (data.containsKey('export_header')) {
      context.handle(
        _exportHeaderMeta,
        exportHeader.isAcceptableOrUnknown(
          data['export_header']!,
          _exportHeaderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exportHeaderMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {snapshotId, exportHeader};
  @override
  CounterValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CounterValue(
      snapshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_id'],
      )!,
      exportHeader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}export_header'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $CounterValuesTable createAlias(String alias) {
    return $CounterValuesTable(attachedDatabase, alias);
  }
}

class CounterValue extends DataClass implements Insertable<CounterValue> {
  final String snapshotId;

  /// Stable identity of the counter: its export header.
  final String exportHeader;
  final int value;
  const CounterValue({
    required this.snapshotId,
    required this.exportHeader,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['snapshot_id'] = Variable<String>(snapshotId);
    map['export_header'] = Variable<String>(exportHeader);
    map['value'] = Variable<int>(value);
    return map;
  }

  CounterValuesCompanion toCompanion(bool nullToAbsent) {
    return CounterValuesCompanion(
      snapshotId: Value(snapshotId),
      exportHeader: Value(exportHeader),
      value: Value(value),
    );
  }

  factory CounterValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CounterValue(
      snapshotId: serializer.fromJson<String>(json['snapshotId']),
      exportHeader: serializer.fromJson<String>(json['exportHeader']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'snapshotId': serializer.toJson<String>(snapshotId),
      'exportHeader': serializer.toJson<String>(exportHeader),
      'value': serializer.toJson<int>(value),
    };
  }

  CounterValue copyWith({
    String? snapshotId,
    String? exportHeader,
    int? value,
  }) => CounterValue(
    snapshotId: snapshotId ?? this.snapshotId,
    exportHeader: exportHeader ?? this.exportHeader,
    value: value ?? this.value,
  );
  CounterValue copyWithCompanion(CounterValuesCompanion data) {
    return CounterValue(
      snapshotId: data.snapshotId.present
          ? data.snapshotId.value
          : this.snapshotId,
      exportHeader: data.exportHeader.present
          ? data.exportHeader.value
          : this.exportHeader,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CounterValue(')
          ..write('snapshotId: $snapshotId, ')
          ..write('exportHeader: $exportHeader, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(snapshotId, exportHeader, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CounterValue &&
          other.snapshotId == this.snapshotId &&
          other.exportHeader == this.exportHeader &&
          other.value == this.value);
}

class CounterValuesCompanion extends UpdateCompanion<CounterValue> {
  final Value<String> snapshotId;
  final Value<String> exportHeader;
  final Value<int> value;
  final Value<int> rowid;
  const CounterValuesCompanion({
    this.snapshotId = const Value.absent(),
    this.exportHeader = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CounterValuesCompanion.insert({
    required String snapshotId,
    required String exportHeader,
    required int value,
    this.rowid = const Value.absent(),
  }) : snapshotId = Value(snapshotId),
       exportHeader = Value(exportHeader),
       value = Value(value);
  static Insertable<CounterValue> custom({
    Expression<String>? snapshotId,
    Expression<String>? exportHeader,
    Expression<int>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (exportHeader != null) 'export_header': exportHeader,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CounterValuesCompanion copyWith({
    Value<String>? snapshotId,
    Value<String>? exportHeader,
    Value<int>? value,
    Value<int>? rowid,
  }) {
    return CounterValuesCompanion(
      snapshotId: snapshotId ?? this.snapshotId,
      exportHeader: exportHeader ?? this.exportHeader,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (snapshotId.present) {
      map['snapshot_id'] = Variable<String>(snapshotId.value);
    }
    if (exportHeader.present) {
      map['export_header'] = Variable<String>(exportHeader.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CounterValuesCompanion(')
          ..write('snapshotId: $snapshotId, ')
          ..write('exportHeader: $exportHeader, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$FieldTallyDatabase extends GeneratedDatabase {
  _$FieldTallyDatabase(QueryExecutor e) : super(e);
  $FieldTallyDatabaseManager get managers => $FieldTallyDatabaseManager(this);
  late final $SnapshotsTable snapshots = $SnapshotsTable(this);
  late final $CounterValuesTable counterValues = $CounterValuesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    snapshots,
    counterValues,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'snapshots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('counter_values', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SnapshotsTableCreateCompanionBuilder =
    SnapshotsCompanion Function({
      required String id,
      required String agentName,
      required String faction,
      required String timeSpan,
      required DateTime recordedAt,
      required int level,
      required DateTime importedAt,
      Value<int> rowid,
    });
typedef $$SnapshotsTableUpdateCompanionBuilder =
    SnapshotsCompanion Function({
      Value<String> id,
      Value<String> agentName,
      Value<String> faction,
      Value<String> timeSpan,
      Value<DateTime> recordedAt,
      Value<int> level,
      Value<DateTime> importedAt,
      Value<int> rowid,
    });

final class $$SnapshotsTableReferences
    extends BaseReferences<_$FieldTallyDatabase, $SnapshotsTable, Snapshot> {
  $$SnapshotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CounterValuesTable, List<CounterValue>>
  _counterValuesRefsTable(_$FieldTallyDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.counterValues,
        aliasName: 'snapshots__id__counter_values__snapshot_id',
      );

  $$CounterValuesTableProcessedTableManager get counterValuesRefs {
    final manager = $$CounterValuesTableTableManager(
      $_db,
      $_db.counterValues,
    ).filter((f) => f.snapshotId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_counterValuesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SnapshotsTableFilterComposer
    extends Composer<_$FieldTallyDatabase, $SnapshotsTable> {
  $$SnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentName => $composableBuilder(
    column: $table.agentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get faction => $composableBuilder(
    column: $table.faction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeSpan => $composableBuilder(
    column: $table.timeSpan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> counterValuesRefs(
    Expression<bool> Function($$CounterValuesTableFilterComposer f) f,
  ) {
    final $$CounterValuesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.counterValues,
      getReferencedColumn: (t) => t.snapshotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CounterValuesTableFilterComposer(
            $db: $db,
            $table: $db.counterValues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SnapshotsTableOrderingComposer
    extends Composer<_$FieldTallyDatabase, $SnapshotsTable> {
  $$SnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentName => $composableBuilder(
    column: $table.agentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get faction => $composableBuilder(
    column: $table.faction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeSpan => $composableBuilder(
    column: $table.timeSpan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SnapshotsTableAnnotationComposer
    extends Composer<_$FieldTallyDatabase, $SnapshotsTable> {
  $$SnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentName =>
      $composableBuilder(column: $table.agentName, builder: (column) => column);

  GeneratedColumn<String> get faction =>
      $composableBuilder(column: $table.faction, builder: (column) => column);

  GeneratedColumn<String> get timeSpan =>
      $composableBuilder(column: $table.timeSpan, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  Expression<T> counterValuesRefs<T extends Object>(
    Expression<T> Function($$CounterValuesTableAnnotationComposer a) f,
  ) {
    final $$CounterValuesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.counterValues,
      getReferencedColumn: (t) => t.snapshotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CounterValuesTableAnnotationComposer(
            $db: $db,
            $table: $db.counterValues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SnapshotsTableTableManager
    extends
        RootTableManager<
          _$FieldTallyDatabase,
          $SnapshotsTable,
          Snapshot,
          $$SnapshotsTableFilterComposer,
          $$SnapshotsTableOrderingComposer,
          $$SnapshotsTableAnnotationComposer,
          $$SnapshotsTableCreateCompanionBuilder,
          $$SnapshotsTableUpdateCompanionBuilder,
          (Snapshot, $$SnapshotsTableReferences),
          Snapshot,
          PrefetchHooks Function({bool counterValuesRefs})
        > {
  $$SnapshotsTableTableManager(_$FieldTallyDatabase db, $SnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> agentName = const Value.absent(),
                Value<String> faction = const Value.absent(),
                Value<String> timeSpan = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotsCompanion(
                id: id,
                agentName: agentName,
                faction: faction,
                timeSpan: timeSpan,
                recordedAt: recordedAt,
                level: level,
                importedAt: importedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String agentName,
                required String faction,
                required String timeSpan,
                required DateTime recordedAt,
                required int level,
                required DateTime importedAt,
                Value<int> rowid = const Value.absent(),
              }) => SnapshotsCompanion.insert(
                id: id,
                agentName: agentName,
                faction: faction,
                timeSpan: timeSpan,
                recordedAt: recordedAt,
                level: level,
                importedAt: importedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SnapshotsTable, Snapshot>(table),
                  $$SnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({counterValuesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (counterValuesRefs) db.counterValues,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (counterValuesRefs)
                    await $_getPrefetchedData<
                      Snapshot,
                      $SnapshotsTable,
                      CounterValue
                    >(
                      currentTable: table,
                      referencedTable: $$SnapshotsTableReferences
                          ._counterValuesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SnapshotsTableReferences(
                            db,
                            table,
                            p0,
                          ).counterValuesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.snapshotId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$FieldTallyDatabase,
      $SnapshotsTable,
      Snapshot,
      $$SnapshotsTableFilterComposer,
      $$SnapshotsTableOrderingComposer,
      $$SnapshotsTableAnnotationComposer,
      $$SnapshotsTableCreateCompanionBuilder,
      $$SnapshotsTableUpdateCompanionBuilder,
      (Snapshot, $$SnapshotsTableReferences),
      Snapshot,
      PrefetchHooks Function({bool counterValuesRefs})
    >;
typedef $$CounterValuesTableCreateCompanionBuilder =
    CounterValuesCompanion Function({
      required String snapshotId,
      required String exportHeader,
      required int value,
      Value<int> rowid,
    });
typedef $$CounterValuesTableUpdateCompanionBuilder =
    CounterValuesCompanion Function({
      Value<String> snapshotId,
      Value<String> exportHeader,
      Value<int> value,
      Value<int> rowid,
    });

final class $$CounterValuesTableReferences
    extends
        BaseReferences<
          _$FieldTallyDatabase,
          $CounterValuesTable,
          CounterValue
        > {
  $$CounterValuesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SnapshotsTable _snapshotIdTable(_$FieldTallyDatabase db) =>
      db.snapshots.createAlias('counter_values__snapshot_id__snapshots__id');

  $$SnapshotsTableProcessedTableManager get snapshotId {
    final $_column = $_itemColumn<String>('snapshot_id')!;

    final manager = $$SnapshotsTableTableManager(
      $_db,
      $_db.snapshots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_snapshotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CounterValuesTableFilterComposer
    extends Composer<_$FieldTallyDatabase, $CounterValuesTable> {
  $$CounterValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get exportHeader => $composableBuilder(
    column: $table.exportHeader,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$SnapshotsTableFilterComposer get snapshotId {
    final $$SnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.snapshotId,
      referencedTable: $db.snapshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.snapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CounterValuesTableOrderingComposer
    extends Composer<_$FieldTallyDatabase, $CounterValuesTable> {
  $$CounterValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get exportHeader => $composableBuilder(
    column: $table.exportHeader,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$SnapshotsTableOrderingComposer get snapshotId {
    final $$SnapshotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.snapshotId,
      referencedTable: $db.snapshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SnapshotsTableOrderingComposer(
            $db: $db,
            $table: $db.snapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CounterValuesTableAnnotationComposer
    extends Composer<_$FieldTallyDatabase, $CounterValuesTable> {
  $$CounterValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get exportHeader => $composableBuilder(
    column: $table.exportHeader,
    builder: (column) => column,
  );

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$SnapshotsTableAnnotationComposer get snapshotId {
    final $$SnapshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.snapshotId,
      referencedTable: $db.snapshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SnapshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.snapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CounterValuesTableTableManager
    extends
        RootTableManager<
          _$FieldTallyDatabase,
          $CounterValuesTable,
          CounterValue,
          $$CounterValuesTableFilterComposer,
          $$CounterValuesTableOrderingComposer,
          $$CounterValuesTableAnnotationComposer,
          $$CounterValuesTableCreateCompanionBuilder,
          $$CounterValuesTableUpdateCompanionBuilder,
          (CounterValue, $$CounterValuesTableReferences),
          CounterValue,
          PrefetchHooks Function({bool snapshotId})
        > {
  $$CounterValuesTableTableManager(
    _$FieldTallyDatabase db,
    $CounterValuesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CounterValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CounterValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CounterValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> snapshotId = const Value.absent(),
                Value<String> exportHeader = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CounterValuesCompanion(
                snapshotId: snapshotId,
                exportHeader: exportHeader,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String snapshotId,
                required String exportHeader,
                required int value,
                Value<int> rowid = const Value.absent(),
              }) => CounterValuesCompanion.insert(
                snapshotId: snapshotId,
                exportHeader: exportHeader,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CounterValuesTable, CounterValue>(table),
                  $$CounterValuesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({snapshotId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (snapshotId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.snapshotId,
                                referencedTable: $$CounterValuesTableReferences
                                    ._snapshotIdTable(db),
                                referencedColumn: $$CounterValuesTableReferences
                                    ._snapshotIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CounterValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$FieldTallyDatabase,
      $CounterValuesTable,
      CounterValue,
      $$CounterValuesTableFilterComposer,
      $$CounterValuesTableOrderingComposer,
      $$CounterValuesTableAnnotationComposer,
      $$CounterValuesTableCreateCompanionBuilder,
      $$CounterValuesTableUpdateCompanionBuilder,
      (CounterValue, $$CounterValuesTableReferences),
      CounterValue,
      PrefetchHooks Function({bool snapshotId})
    >;

class $FieldTallyDatabaseManager {
  final _$FieldTallyDatabase _db;
  $FieldTallyDatabaseManager(this._db);
  $$SnapshotsTableTableManager get snapshots =>
      $$SnapshotsTableTableManager(_db, _db.snapshots);
  $$CounterValuesTableTableManager get counterValues =>
      $$CounterValuesTableTableManager(_db, _db.counterValues);
}
