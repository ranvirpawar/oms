// facility_detail_providers.dart
// facility_detail_providers.dart
//
// Providers for the FacilityDetailScreen.
//
//  1. financialYearsProvider       → loads year list once (cached)
//  2. selectedYearProvider         → which year is currently selected
//  3. DetailArg                    → args bundle passed to the screen
//  4. FacilityDetailState          → state class for the notifier
//  5. FacilityDetailNotifier       → fetches type-2 data
//  6. facilityDetailProvider       → family provider keyed by (fTypeId, yearId)
//  7. detailSortOptionProvider     → sort option for detail screen
//  8. detailSearchQueryProvider    → search query for detail screen
//  9. filteredDetailProvider       → filtered + sorted facility list
// 10. wardGroupedDetailProvider    → ward-wise aggregated groups
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';

import '../model/facility_detail_model.dart';
import 'consumption_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ward aggregate — a roll-up of all rows that share the same ward code
// ─────────────────────────────────────────────────────────────────────────────
class WardAggregate {
  final String ward;
  final int totalTarget;
  final int totalPatients;
  final List<FacilityDetailModel> items;

  const WardAggregate({
    required this.ward,
    required this.totalTarget,
    required this.totalPatients,
    required this.items,
  });

  double get completionPercent =>
      totalTarget > 0 ? (totalPatients / totalTarget * 100).clamp(0.0, 999.9) : 0.0;

  int get diff => totalPatients - totalTarget;
}

// ── 1. FINANCIAL YEARS ────────────────────────────────────────────────────────
final financialYearsProvider =
FutureProvider<List<ProjectFinancialYear>>((ref) async {
  final service = ref.read(consumptionServiceProvider);
  try {
    return await service.fetchFinancialYears();
  } catch (e) {
    debugPrint('[financialYearsProvider] Error: $e');
    return [
      const ProjectFinancialYear(yearId: 1, yearDescription: 'Current'),
    ];
  }
});

// ── 2. SELECTED YEAR ──────────────────────────────────────────────────────────
final selectedYearProvider = StateProvider<int>((ref) => 1);

// ── 3. STATE ──────────────────────────────────────────────────────────────────
class FacilityDetailState {
  final bool isLoading;
  final List<FacilityDetailModel> data;
  final String? error;

  const FacilityDetailState({
    this.isLoading = true,
    this.data = const [],
    this.error,
  });

  FacilityDetailState copyWith({
    bool? isLoading,
    List<FacilityDetailModel>? data,
    String? error,
  }) =>
      FacilityDetailState(
        isLoading: isLoading ?? this.isLoading,
        data: data ?? this.data,
        error: error,
      );
}

// ── 4. ARG — simple equatable value class ─────────────────────────────────────
class DetailArg {
  final int fTypeId;
  final int yearId;

  const DetailArg({required this.fTypeId, required this.yearId});

  @override
  bool operator ==(Object other) =>
      other is DetailArg &&
          other.fTypeId == fTypeId &&
          other.yearId == yearId;

  @override
  int get hashCode => Object.hash(fTypeId, yearId);
}

// ── 5. STATE NOTIFIER ─────────────────────────────────────────────────────────
class FacilityDetailNotifier extends StateNotifier<FacilityDetailState> {
  final Ref _ref;
  final DetailArg _arg;

  FacilityDetailNotifier(this._ref, this._arg)
      : super(const FacilityDetailState()) {
    _fetch();
  }

  Future<void> _fetch() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _ref.read(userProfileProvider.future);

      if (profile == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User profile not found.',
        );
        return;
      }

      final service = _ref.read(consumptionServiceProvider);
      final result = await service.fetchDetail(
        desgId: profile.desgId,
        fTypeId: _arg.fTypeId,
        yearId: _arg.yearId,
      );

      state = state.copyWith(isLoading: false, data: result);
    } catch (e, stacktrace) {
      debugPrint('[FacilityDetailNotifier] Error: $e');
      debugPrint('[FacilityDetailNotifier] stacktrace: $stacktrace');
      state = state.copyWith(isLoading: false, error: parseError(e.toString()));
    }
  }

  Future<void> refresh() => _fetch();
}

// ── 6. FAMILY PROVIDER ────────────────────────────────────────────────────────
final facilityDetailProvider = StateNotifierProvider.autoDispose
    .family<FacilityDetailNotifier, FacilityDetailState, DetailArg>(
      (ref, arg) => FacilityDetailNotifier(ref, arg),
);

// ── 7. DETAIL SORT OPTION ─────────────────────────────────────────────────────
final detailSortOptionProvider =
StateProvider<SortOption>((ref) => SortOption.facilityName);

// ── 8. DETAIL SEARCH QUERY ────────────────────────────────────────────────────
final detailSearchQueryProvider = StateProvider<String>((ref) => '');

// ── 9. FILTERED + SORTED DETAIL DATA (By Facility tab) ───────────────────────
final filteredDetailProvider =
Provider.family<List<FacilityDetailModel>, DetailArg>((ref, arg) {
  final raw = ref.watch(facilityDetailProvider(arg)).data;
  final query = ref.watch(detailSearchQueryProvider).trim().toLowerCase();
  final sort = ref.watch(detailSortOptionProvider);

  // ── filter ─────────────────────────────────────────────────────────────────
  final filtered = query.isEmpty
      ? raw
      : raw
      .where(
        (e) =>
    e.facilityName.toLowerCase().contains(query) ||
        e.catName.toLowerCase().contains(query),
  )
      .toList();

  // ── sort ───────────────────────────────────────────────────────────────────
  int pct(FacilityDetailModel e) =>
      e.yearlyTarget > 0 ? (e.patCount * 100 ~/ e.yearlyTarget) : 0;

  final sorted = [...filtered];
  switch (sort) {
    case SortOption.facilityName:
      sorted.sort((a, b) => a.facilityName.compareTo(b.facilityName));
    case SortOption.highestCompletion:
      sorted.sort((a, b) => pct(b).compareTo(pct(a)));
    case SortOption.lowestCompletion:
      sorted.sort((a, b) => pct(a).compareTo(pct(b)));
    case SortOption.highestTarget:
      sorted.sort((a, b) => b.yearlyTarget.compareTo(a.yearlyTarget));
  }

  return sorted;
});

// ── 10. WARD-WISE AGGREGATED GROUPS (By Ward tab) ────────────────────────────
// Groups all rows by ward, applies search filter on ward / facility / category,
// then sorts the resulting ward aggregates by the active sort option.
final wardGroupedDetailProvider =
Provider.family<List<WardAggregate>, DetailArg>((ref, arg) {
  final raw = ref.watch(facilityDetailProvider(arg)).data;
  final query = ref.watch(detailSearchQueryProvider).trim().toLowerCase();
  final sort = ref.watch(detailSortOptionProvider);

  // ── filter first, then group ───────────────────────────────────────────────
  final filtered = query.isEmpty
      ? raw
      : raw
      .where(
        (e) =>
    e.ward.toLowerCase().contains(query) ||
        e.facilityName.toLowerCase().contains(query) ||
        e.catName.toLowerCase().contains(query),
  )
      .toList();

  // ── group by ward ─────────────────────────────────────────────────────────
  final Map<String, List<FacilityDetailModel>> grouped = {};
  for (final item in filtered) {
    final key = item.ward.isEmpty ? 'Unassigned' : item.ward;
    grouped.putIfAbsent(key, () => []).add(item);
  }

  // ── build aggregates ───────────────────────────────────────────────────────
  final aggregates = grouped.entries.map((entry) {
    final items = entry.value;
    return WardAggregate(
      ward: entry.key,
      totalTarget: items.fold(0, (s, e) => s + e.yearlyTarget),
      totalPatients: items.fold(0, (s, e) => s + e.patCount),
      items: items,
    );
  }).toList();

  // ── sort aggregates ────────────────────────────────────────────────────────
  switch (sort) {
    case SortOption.facilityName:
      aggregates.sort((a, b) => a.ward.compareTo(b.ward));
    case SortOption.highestCompletion:
      aggregates.sort(
            (a, b) => b.completionPercent.compareTo(a.completionPercent),
      );
    case SortOption.lowestCompletion:
      aggregates.sort(
            (a, b) => a.completionPercent.compareTo(b.completionPercent),
      );
    case SortOption.highestTarget:
      aggregates.sort((a, b) => b.totalTarget.compareTo(a.totalTarget));
  }

  return aggregates;
});