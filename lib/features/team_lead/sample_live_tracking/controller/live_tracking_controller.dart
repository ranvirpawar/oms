import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../services/user_service.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../../../auth/model/login_response_model.dart';
import '../model/bag_model.dart';
import '../model/facility_model.dart';
import '../model/get_bag_status_event_model.dart';
import '../model/sample_flow_summary_flow.dart';
import '../model/tracking_counts_model.dart';
import '../model/tracking_summary_model.dart';
import '../services/live_tracking_service.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';




class LiveTrackingController extends GetxController {
  final _service = LiveTrackingService();

  // ── Observables ─────────────────────────────────────────────────────────────
  final summary    = Rxn<SampleFlowSummaryModel>();
  final facilities = <FacilityModel>[].obs;
  final bags       = <BagModel>[].obs;

  final isLoading = true.obs;
  final error     = Rxn<String>();
  final user   = Rx<UserModel?>(null);
  final userId = ''.obs;
  final UserService userService = Get.put(UserService());

  // ── Filter / Search (Facilities tab) ───────────────────────────────────────
  final searchQuery      = ''.obs;
  final activeFilter     = 'All'.obs;
  final selectedTabIndex = 0.obs;

  // ── Filter / Search (Bags tab) ───────────────────────────────────────────────
  final bagSearchQuery  = ''.obs;
  final activeBagFilter = 'All'.obs;

  // ── Date range (defaults to today) ─────────────────────────────────────────
  final fromDate = ''.obs;
  final toDate   = ''.obs;

  // ── Bag drill-down (tapping a facility OR bag card) ───────────────────────────
  // Generalized so it works for both FacilityModel (has a facilityCode) and
  // BagModel (which doesn't — the API expects facilitycode: 0 for those).
  final drilldownTitle     = Rxn<String>();
  final drilldownSubtitle  = Rxn<String>();
  final bagDrilldown       = Rxn<BagDrillDownModel>();
  final isDrilldownLoading = false.obs;
  final drilldownError     = Rxn<String>();

  // ── Derived: facility filter chips, built from whatever statuses are live ────
  List<String> get statusFilters {
    final statuses = facilities.map((f) => f.displayStatus).toSet().toList()..sort();
    return ['All', 'Attention', ...statuses];
  }

  // ── Derived: filtered + sorted facility list (attention-needed first) ────────
  List<FacilityModel> get filteredFacilities {
    final q = searchQuery.value.toLowerCase();

    Iterable<FacilityModel> list = facilities;

    if (activeFilter.value == 'Attention') {
      list = list.where(
            (f) => f.urgency == FacilityUrgency.breached || f.urgency == FacilityUrgency.warning,
      );
    } else if (activeFilter.value != 'All') {
      list = list.where((f) => f.displayStatus == activeFilter.value);
    }

    list = list.where(
          (f) => q.isEmpty || f.facilityName.toLowerCase().contains(q) || f.rbName.toLowerCase().contains(q),
    );

    final result = list.toList()..sort((a, b) => a.urgency.priority.compareTo(b.urgency.priority));
    return result;
  }

  int chipCount(String filter) {
    if (filter == 'All') return facilities.length;
    if (filter == 'Attention') {
      return facilities
          .where((f) => f.urgency == FacilityUrgency.breached || f.urgency == FacilityUrgency.warning)
          .length;
    }
    return facilities.where((f) => f.displayStatus == filter).length;
  }

  // ── Derived: bag filter chips + filtered/sorted bag list ───────────────────────
  List<String> get bagStatusFilters {
    final statuses = bags.map((b) => b.displayStatus).toSet().toList()..sort();
    return ['All', 'Attention', ...statuses];
  }

  List<BagModel> get filteredBags {
    final q = bagSearchQuery.value.toLowerCase();

    Iterable<BagModel> list = bags;

    if (activeBagFilter.value == 'Attention') {
      list = list.where(
            (b) => b.urgency == FacilityUrgency.breached || b.urgency == FacilityUrgency.warning,
      );
    } else if (activeBagFilter.value != 'All') {
      list = list.where((b) => b.displayStatus == activeBagFilter.value);
    }

    list = list.where(
          (b) =>
      q.isEmpty ||
          b.bagcode.toLowerCase().contains(q) ||
          (b.contactPersonName?.toLowerCase().contains(q) ?? false),
    );

    final result = list.toList()..sort((a, b) => a.urgency.priority.compareTo(b.urgency.priority));
    return result;
  }

  int bagChipCount(String filter) {
    if (filter == 'All') return bags.length;
    if (filter == 'Attention') {
      return bags.where((b) => b.urgency == FacilityUrgency.breached || b.urgency == FacilityUrgency.warning).length;
    }
    return bags.where((b) => b.displayStatus == filter).length;
  }

  // ── Derived: dashboard stat cards ─────────────────────────────────────────────
  int get attentionCount => facilities.where((f) => f.urgency == FacilityUrgency.breached).length;
  int get warningCount   => facilities.where((f) => f.urgency == FacilityUrgency.warning).length;
  int get inTransitCount => facilities.where((f) => f.displayStatus == 'In Transit').length;
  /// Awaiting pickup: facilities with status "Pending" in the flow
  int get awaitingPickupCount => facilities
      .where((f) => f.displayStatus.trim().toLowerCase() == 'pending')
      .length;

  /// Completed today: facilities with status "Bag Accepted" (or "Accepted")
  int get completedTodayCount => facilities
      .where((f) =>
  f.displayStatus.trim().toLowerCase() == 'bag accepted' ||
      f.displayStatus.trim().toLowerCase() == 'accepted')
      .length;

  /// Worst-first list of facilities needing attention — powers the alerts feed.
  List<FacilityModel> get attentionFeed {
    final list = facilities
        .where((f) => f.urgency == FacilityUrgency.breached || f.urgency == FacilityUrgency.warning)
        .toList()
      ..sort((a, b) {
        final ea = a.tatTimeInHrs ?? a.liveElapsedHours ?? 0;
        final eb = b.tatTimeInHrs ?? b.liveElapsedHours ?? 0;
        return eb.compareTo(ea);
      });
    return list;
  }

  /// Live distribution of current statuses — powers the donut chart.
  Map<String, int> get statusDistribution {
    final map = <String, int>{};
    for (final f in facilities) {
      if (f.status == null) continue;
      map[f.displayStatus] = (map[f.displayStatus] ?? 0) + 1;
    }
    return map;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();

    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');

    fromDate.value = fmt.format(now);
    toDate.value   = fmt.format(now);

    loadUser();
  }

  void loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = user.value?.empCode.toString() ?? '';
        loadAll();
      } else {
        kPrint('❌ Failed to load user data');
      }
    } catch (e) {
      kPrint('❌ Error loading user: $e');
    }
  }

  // ── Load funnel summary + facility list + bag list in parallel ────────────────
  // Type-2 (counts) is intentionally not called — it duplicates data already
  // derivable from the facility list and isn't used anywhere.
  Future<void> loadAll() async {
    isLoading(true);
    error.value = null;

    try {
      final results = await Future.wait([
        _service.fetchStatusSummary(fromDate: fromDate.value, toDate: toDate.value, userId: userId.value),
        _service.fetchFacilities(fromDate: fromDate.value, toDate: toDate.value, userId: userId.value),
        _service.fetchBags(fromDate: fromDate.value, toDate: toDate.value, userId: userId.value),
      ]);

      summary.value = results[0] as SampleFlowSummaryModel;
      facilities.assignAll(results[1] as List<FacilityModel>);
      bags.assignAll(results[2] as List<BagModel>);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading(false);
    }
  }

  // ── Pull-to-refresh ────────────────────────────────────────────────────────
  Future<void> refresh() => loadAll();

  // ── Filter actions (Facilities tab) ──────────────────────────────────────────
  void setFilter(String filter) => activeFilter.value = filter;
  void setSearch(String query)  => searchQuery.value  = query;
  void setTab(int index)        => selectedTabIndex.value = index;

  // ── Filter actions (Bags tab) ────────────────────────────────────────────────
  void setBagFilter(String filter) => activeBagFilter.value = filter;
  void setBagSearch(String query)  => bagSearchQuery.value  = query;

  // ── Drill-down navigation (dashboard cards → facility tab) ───────────────────
  void drillDown(String filter) {
    setFilter(filter);
    setTab(1);
  }

  Future<void> updateDateRange({required String from, required String to}) async {
    fromDate.value = from;
    toDate.value   = to;
    await loadAll(); // reloads all 3 APIs with new dates
  }

  // ── Bag drill-down (facility OR bag card tap) ─────────────────────────────────
  Future<void> _fetchDrilldown({
    required String title,
    String? subtitle,
    required int facilityCode,
    required String bagcode,
  }) async {
    drilldownTitle.value = title;
    drilldownSubtitle.value = subtitle;
    bagDrilldown.value = null;
    drilldownError.value = null;

    isDrilldownLoading(true);
    try {
      final result = await _service.fetchBagDetails(
        facilityCode: facilityCode,
        bagcode: bagcode,
        visitDate: fromDate.value,
      );
      bagDrilldown.value = result;
    } catch (e) {
      drilldownError.value = e.toString();
    } finally {
      isDrilldownLoading(false);
    }
  }

  /// Called from a facility card. Uses the facility's real facilityCode.
  Future<void> openFacilityDetail(FacilityModel facility) async {
    if (!facility.hasBag) {
      drilldownTitle.value = facility.facilityName;
      drilldownSubtitle.value = null;
      bagDrilldown.value = null;
      drilldownError.value = "This facility hasn't generated a sample bag yet.";
      return;
    }

    await _fetchDrilldown(
      title: facility.facilityName,
      subtitle: 'Bag: ${facility.bagcode}',
      facilityCode: facility.facilityCode,
      bagcode: facility.bagcode!,
    );
  }

  /// Called from a bag card (Bags tab). The type-4 list has no facility
  /// code, so per the API's expectation we send facilitycode: 0.
  Future<void> openBagDetail(BagModel bag) async {
    await _fetchDrilldown(
      title: 'Bag ${bag.bagcode}',
      subtitle: bag.contactPersonName,
      facilityCode: 0,
      bagcode: bag.bagcode,
    );
  }

  void clearDrilldown() {
    drilldownTitle.value = null;
    drilldownSubtitle.value = null;
    bagDrilldown.value = null;
    drilldownError.value = null;
  }
}
