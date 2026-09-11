import '../goal.dart';

/// Personal targets on counters (§3.7).
///
/// Stored rather than derived — a goal is an intention, not something the
/// history can be asked about.
abstract interface class GoalRepository {
  Future<List<Goal>> all();

  Future<Goal?> forCounter(String exportHeader);

  Stream<List<Goal>> watchAll();

  /// Sets or replaces the goal on a counter. One per counter: "reach level 12
  /// before December" is a single intent, and stacking several would ask the
  /// app to decide which one it is reminding about.
  Future<void> set(Goal goal);

  Future<void> remove(String exportHeader);
}
