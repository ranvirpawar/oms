// lib/core/utils/tat_utils.dart
//
// Shared TAT (turnaround-time) logic for Collected Bags. Import this from
// both the controller (filtering/sorting/counts) and the view (display).
//
// BUSINESS RULES
// ───────────────────────────────────────────────────────────────────────
// • Standard TAT for a bag containing samples = 3 hours from the moment the
//   Runner collects it from the phlebotomist (`collectedAt`).
// • A bag with zero samples/tubes is a distinct business state — "Empty
//   Bag" — not a fast/expired SLA bag. Empty bags never get a timer, never
//   show as due/overdue, and are excluded from TAT-based sorting logic.
// • Today the only signal we have for "empty" is `tubeCount == 0`. That is
//   intentionally isolated behind `isEmptyBag()` below so that if/when the
//   backend adds an explicit flag (e.g. `bag.hasSamples` / `bag.bagType`),
//   only this one function needs to change — nothing upstream should ever
//   re-derive emptiness from `tubeCount` directly.

/// Operational status of a bag from the Runner's point of view.
enum TatStatus { onTrack, dueSoon, overdue, empty }

/// Filter chip values shown in the UI. Mirrors [TatStatus] plus `all`.
enum TatFilter { all, overdue, dueSoon, onTrack, empty }

extension TatFilterX on TatFilter {
  TatStatus? get toStatus {
    switch (this) {
      case TatFilter.onTrack:
        return TatStatus.onTrack;
      case TatFilter.dueSoon:
        return TatStatus.dueSoon;
      case TatFilter.overdue:
        return TatStatus.overdue;
      case TatFilter.empty:
        return TatStatus.empty;
      case TatFilter.all:
        return null;
    }
  }

  String get label {
    switch (this) {
      case TatFilter.all:
        return 'All';
      case TatFilter.onTrack:
        return 'On Track';
      case TatFilter.dueSoon:
        return 'Due Soon';
      case TatFilter.overdue:
        return 'Overdue';
      case TatFilter.empty:
        return 'Empty';
    }
  }
}

class TatPolicy {
  /// Sample bags are due this many minutes after collection.
  static const int tatMinutes = 3 * 60;

  /// Bags enter "due soon" this many minutes before the TAT deadline —
  /// i.e. from (tatMinutes - dueSoonWindowMinutes) elapsed onward.
  static const int dueSoonWindowMinutes = 30;
}

class TatInfo {
  final TatStatus status;
  final bool hasSamples;
  final Duration elapsed;

  /// Time left until due. Zero once overdue or for empty bags.
  final Duration remaining;

  /// Time past due. Zero unless [status] is overdue.
  final Duration overdueBy;

  /// Primary line for the card / status chip, e.g. "Due in 1h 42m",
  /// "Overdue by 32m", or "EMPTY BAG".
  final String headline;

  /// Secondary supporting line, e.g. "" for sample bags or
  /// "No samples • No TAT" for empty bags.
  final String subline;

  const TatInfo({
    required this.status,
    required this.hasSamples,
    required this.elapsed,
    required this.remaining,
    required this.overdueBy,
    required this.headline,
    required this.subline,
  });
}

class TatHelper {
  TatHelper._();

  /// Single choke point for "is this bag empty" — see file header.
  static bool isEmptyBag(int tubeCount) => tubeCount <= 0;

  static TatInfo evaluate({
    required DateTime collectedAt,
    required int tubeCount,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final elapsed = currentTime.difference(collectedAt);

    if (isEmptyBag(tubeCount)) {
      return TatInfo(
        status: TatStatus.empty,
        hasSamples: false,
        elapsed: elapsed,
        remaining: Duration.zero,
        overdueBy: Duration.zero,
        headline: 'EMPTY BAG',
        subline: '',
      );
    }

    final deadline = collectedAt.add(const Duration(minutes: TatPolicy.tatMinutes));
    final remaining = deadline.difference(currentTime);
    final elapsedMinutes = elapsed.inMinutes;

    final TatStatus status;
    if (elapsedMinutes >= TatPolicy.tatMinutes) {
      status = TatStatus.overdue;
    } else if (elapsedMinutes >= TatPolicy.tatMinutes - TatPolicy.dueSoonWindowMinutes) {
      status = TatStatus.dueSoon;
    } else {
      status = TatStatus.onTrack;
    }

    final overdueBy = status == TatStatus.overdue
        ? elapsed - const Duration(minutes: TatPolicy.tatMinutes)
        : Duration.zero;

    final headline = status == TatStatus.overdue
        ? 'Overdue by ${_fmt(overdueBy)}'
        : 'Due in ${_fmt(remaining)}';

    return TatInfo(
      status: status,
      hasSamples: true,
      elapsed: elapsed,
      remaining: remaining.isNegative ? Duration.zero : remaining,
      overdueBy: overdueBy,
      headline: headline,
      subline: '',
    );
  }

  static String _fmt(Duration d) {
    final abs = d.abs();
    final h = abs.inHours;
    final m = abs.inMinutes.remainder(60);
    if (h <= 0) return '${m}m';
    return '${h}h ${m}m';
  }
}