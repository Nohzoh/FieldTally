import 'models/counter_registry.dart';
import 'models/stat_snapshot.dart';

/// One counter, as it stands for each of the two agents (#64).
class ComparisonRow {
  const ComparisonRow({
    required this.exportHeader,
    required this.mine,
    required this.theirs,
  });

  final String exportHeader;

  /// Null when that agent's snapshot does not carry this counter at all.
  ///
  /// A gap is not a zero (§3.1.2), and it is a normal case here: two agents
  /// who last imported either side of an anomaly do not have the same columns.
  final int? mine;
  final int? theirs;

  /// Positive when I am ahead. Null when either side has no value, since
  /// there is nothing to subtract.
  int? get difference =>
      mine == null || theirs == null ? null : mine! - theirs!;

  /// True only when both sides are known and equal.
  bool get isTied => difference == 0;
}

/// A block of rows, in the order and grouping of the in-game stats screen.
class ComparisonSection {
  const ComparisonSection({required this.categoryKey, required this.rows});

  /// Null for counters the registry does not know (§3.1.2).
  final String? categoryKey;

  final List<ComparisonRow> rows;
}

/// Puts two agents' numbers side by side (#64).
///
/// Pure, and takes two [StatSnapshot]s rather than reading anything: the
/// received one is never stored. §13 kept head-to-head comparison out of v1
/// because it needed a backend; two phones in the same room do not, and this
/// is what stands in for one — held in memory, shown, and gone when the screen
/// is.
///
/// It also never touches the history. Another agent's numbers look exactly
/// like the wrong-period import the guards exist to refuse (§3.1.3), and they
/// would be right: nothing here goes near the repository.
class AgentComparisonBuilder {
  const AgentComparisonBuilder({this.registry});

  /// Only used to group and order the rows the way the counter list does.
  /// Without it they come out in one alphabetical block.
  final CounterRegistry? registry;

  /// Every counter either agent has, so a counter only one of them tracks is
  /// visible rather than quietly dropped.
  List<ComparisonSection> build({
    required StatSnapshot mine,
    required StatSnapshot theirs,
  }) {
    final headers = <String>{...mine.counters.keys, ...theirs.counters.keys};
    final ordered =
        registry?.sortHeaders(headers) ?? (headers.toList()..sort());

    final sections = <ComparisonSection>[];
    for (final header in ordered) {
      final categoryKey = registry == null
          ? null
          : registry!.forExportHeader(header)?.categoryKey ??
                CounterRegistry.fallbackCategoryKey;

      final row = ComparisonRow(
        exportHeader: header,
        mine: mine.counters[header],
        theirs: theirs.counters[header],
      );

      // sortHeaders already grouped them, so a new section starts wherever the
      // category changes rather than needing a second pass.
      if (sections.isEmpty || sections.last.categoryKey != categoryKey) {
        sections.add(ComparisonSection(categoryKey: categoryKey, rows: [row]));
      } else {
        sections.last.rows.add(row);
      }
    }
    return sections;
  }
}
