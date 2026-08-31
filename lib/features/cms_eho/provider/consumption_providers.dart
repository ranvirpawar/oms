// ─────────────────────────────────────────────────────────────────────────────
// consumption_providers.dart
//
// WHAT IS RIVERPOD?
//   Riverpod is a state management library. Think of it as aollers you create "provide smarter, safer
// //   replacement for GetX. Instead of contrrs" that
//   hold state. Widgets "watch" providers and rebuild automatically when state
//   changes.
//
// HOW IT WORKS HERE:
//   1. consumptionServiceProvider  → provides a single instance of the service
//   2. consumptionNotifierProvider → fetches data & holds UI state
//   3. facilityFilterProvider      → which facility is selected in the dropdown
//   4. sortOptionProvider          → how the cards are sorted
//   5. filteredConsumptionProvider → derived: applies filter + sort to raw data
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../services/user_service.dart';
import '../../auth/model/profile_model.dart';
import '../service/consumption_service.dart';
import '../model/consumption_model.dart';
import 'facility_detail_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// consumption_providers.dart
// ─────────────────────────────────────────────────────────────────────────────


// ── 1. USER PROFILE PROVIDER ──────────────────────────────────────────────────
// FutureProvider is Riverpod's way to load async data once and cache it.
//
// This does EXACTLY what SummaryController.loadUser() does:
//   final userProfile = await userService.getUserProfile();
//
// The difference: Riverpod caches the result. Every provider or widget that
// reads userProfileProvider gets the SAME ProfileData — no duplicate calls.
final userProfileProvider = FutureProvider<ProfileData?>((ref) async {
  final userService = UserService();
  try {
    final profile = await userService.getUserProfile();
    debugPrint(
        '[userProfileProvider] Loaded: ${profile?.name}  desgId=${profile?.desgId}  labCode=${profile?.labCode}  distLgdCode=${profile?.distLgdCode}  divisionId=${profile?.divisionId}');
    return profile;
  } catch (e) {
    debugPrint('[userProfileProvider] Error loading profile: $e');
    return null;
  }
});

// ── 2. SERVICE PROVIDER ───────────────────────────────────────────────────────
final consumptionServiceProvider = Provider<ConsumptionService>((ref) {
  return ConsumptionService();
});

// ── 3. STATE CLASS ────────────────────────────────────────────────────────────
class ConsumptionState {
  final bool isLoading;
  final List<ConsumptionModel> data;
  final String? error;

  const ConsumptionState({
    this.isLoading = true,
    this.data = const [],
    this.error,
  });

  ConsumptionState copyWith({
    bool? isLoading,
    List<ConsumptionModel>? data,
    String? error,
  }) {
    return ConsumptionState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

// ── 4. NOTIFIER ───────────────────────────────────────────────────────────────
// Mirrors SummaryController exactly:
//   1. Load user profile  (was loadUser())
//   2. Use profile fields to call API  (was fetchData())
//
// The key Riverpod rule: build() must return state SYNCHRONOUSLY.
// We use Future.microtask so _fetch() runs AFTER build() completes.
class ConsumptionNotifier extends Notifier<ConsumptionState> {
  @override
  ConsumptionState build() {
    Future.microtask(_fetch);
    ref.watch(selectedYearProvider);
    return const ConsumptionState(); // isLoading: true by default
  }

  Future<void> _fetch({int fTypeId = 0}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // ── Step 1: Load user profile ─────────────────────────────────────────
      // ref.read(userProfileProvider.future) awaits the FutureProvider result.
      // This is identical to: final profile = await userService.getUserProfile()
      // in your SummaryController — but Riverpod caches it automatically.
      final profile = await ref.read(userProfileProvider.future);

      if (profile == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User profile not found. Please log in again.',
        );
        return;
      }

      debugPrint(
          '[ConsumptionNotifier] Using → desgId=${profile.desgId}  labCode=${profile.labCode}  distLgdCode=${profile.distLgdCode}  divisionId=${profile.divisionId}');

      // ── Step 2: Call API with real user fields ────────────────────────────
      final yearId = ref.read(selectedYearProvider); // ✅ read current year

      final service = ref.read(consumptionServiceProvider);
      final result = await service.fetchConsumption(
        desgId: profile.desgId,
        fTypeId: fTypeId,
        year: yearId, // ✅ pass year
      );

      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      debugPrint('[ConsumptionNotifier] Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Pull-to-refresh — called from the UI
  Future<void> refresh() => _fetch();
}

// The provider widgets watch/read
final consumptionNotifierProvider =
NotifierProvider.autoDispose<ConsumptionNotifier, ConsumptionState>(
  ConsumptionNotifier.new,
);

// ── 5. FACILITY FILTER PROVIDER ───────────────────────────────────────────────
final facilityFilterProvider = StateProvider<String>((ref) => 'All');

// ── 6. SORT OPTION PROVIDER ───────────────────────────────────────────────────
enum SortOption {
  facilityName,
  highestCompletion,
  lowestCompletion,
  highestTarget,
}

final sortOptionProvider =
StateProvider<SortOption>((ref) => SortOption.facilityName);

// ── 7. UNIQUE FACILITY NAMES (for dropdown) ───────────────────────────────────
final facilityNamesProvider = Provider<List<String>>((ref) {
  final data = ref.watch(consumptionNotifierProvider).data;
  final names = data.map((e) => e.fType).toSet().toList()..sort();
  return ['All', ...names];
});

// ── 8. GROUPED + FILTERED + SORTED DATA ──────────────────────────────────────
final filteredConsumptionProvider =
Provider<List<MapEntry<String, List<ConsumptionModel>>>>((ref) {
  final data = ref.watch(consumptionNotifierProvider).data;
  final filter = ref.watch(facilityFilterProvider);
  final sort = ref.watch(sortOptionProvider);

  final filtered = filter == 'All'
      ? data
      : data.where((e) => e.fType == filter).toList();

  final Map<String, List<ConsumptionModel>> grouped = {};
  for (final item in filtered) {
    grouped.putIfAbsent(item.fType, () => []).add(item);
  }

  final entries = grouped.entries.toList();

  switch (sort) {
    case SortOption.facilityName:
      entries.sort((a, b) => a.key.compareTo(b.key));
      break;
    case SortOption.highestCompletion:
      entries.sort((a, b) {
        final aAvg = a.value.fold(0.0, (s, e) => s + e.completionPercent) / a.value.length;
        final bAvg = b.value.fold(0.0, (s, e) => s + e.completionPercent) / b.value.length;
        return bAvg.compareTo(aAvg);
      });
      break;
    case SortOption.lowestCompletion:
      entries.sort((a, b) {
        final aAvg = a.value.fold(0.0, (s, e) => s + e.completionPercent) / a.value.length;
        final bAvg = b.value.fold(0.0, (s, e) => s + e.completionPercent) / b.value.length;
        return aAvg.compareTo(bAvg);
      });
      break;
    case SortOption.highestTarget:
      entries.sort((a, b) {
        final aMax = a.value.fold(0, (s, e) => s + e.yearlyTarget);
        final bMax = b.value.fold(0, (s, e) => s + e.yearlyTarget);
        return bMax.compareTo(aMax);
      });
      break;
  }

  return entries;
});