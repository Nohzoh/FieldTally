/// Period covered by a snapshot, as declared by the `Time Span` column of the
/// Ingress export (§3.1.3).
///
/// The guiding principle is an **allowlist**: only `ALL TIME` is accepted. Any
/// other value — known (`WEEK`, `MONTH`, `NOW`) or unknown, including a
/// granularity Ingress might add tomorrow — is treated as a partial period and
/// blocks the import. A denylist would let every novelty through, silently
/// skewing the history.
enum TimeSpan {
  /// All time total: the only value usable for history.
  allTime,

  /// Known partial periods.
  week,
  month,
  now,

  /// Unrecognised value. Handled exactly like a partial period: refuse by
  /// default rather than assume it means `ALL TIME`.
  unknown;

  /// Recognises the raw value from an export, ignoring case and stray spacing.
  ///
  /// Ingress writes `ALL TIME` with a space, but `ALLTIME` and `ALL_TIME` are
  /// tolerated too: those variants do not change the meaning, and being overly
  /// strict would turn a valid export into a false positive.
  factory TimeSpan.parse(String raw) {
    final normalized =
        raw.trim().toUpperCase().replaceAll(RegExp(r'[\s_-]+'), '');
    return switch (normalized) {
      'ALLTIME' => TimeSpan.allTime,
      'WEEK' || 'THISWEEK' => TimeSpan.week,
      'MONTH' || 'THISMONTH' => TimeSpan.month,
      'NOW' => TimeSpan.now,
      _ => TimeSpan.unknown,
    };
  }

  /// True only for `ALL TIME`. This is the declarative guard of §3.1.3 reduced
  /// to its simplest expression.
  bool get isCumulative => this == TimeSpan.allTime;
}
