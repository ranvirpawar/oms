import 'package:get/get.dart';
import 'package:lifenity_connect/features/auth/model/login_response_model.dart';
import 'package:lifenity_connect/features/auth/model/profile_model.dart';
import 'package:lifenity_connect/services/auth_manager.dart';
import 'package:lifenity_connect/services/user_service.dart';

import '../../../constants/app_assets.dart';
import '../../../constants/app_strings.dart';
import '../../../routes/route_manager.dart';
import '../../../utils/helper_functions/helper_methods.dart';
import '../../runner_boy/collected_sample_bags/service/collected_bags_service.dart';
import '../model/dashboard_summary_model.dart';
import '../service/dashboard_service.dart';
import '../view/widget/dashboard_tile_card.dart';
import '../../../utils/widgets/metrics_data.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DashboardController
// ─────────────────────────────────────────────────────────────────────────────

class   DashboardController extends GetxController {
  final AuthManager _authManager = Get.find<AuthManager>();
  final UserService _userService = Get.put(UserService());
  final CollectedBagsService _bagsService = CollectedBagsService();

  // ── Observables ──────────────────────────────────────────────────────────────

  final RxString userName = ''.obs;
  final Rx<UserModel?> userData = Rx<UserModel?>(null);
  final Rx<UserRole?> userRole = Rx<UserRole?>(null);
  final Rx<ProfileData?> userProfile = Rx<ProfileData?>(null);
  final RxInt collectedBagsCount = 0.obs;
  final RxBool isLoadingBagCount = false.obs;
  final RxInt assignedPatientsCount = 0.obs;
  final RxInt testCollectedCount = 0.obs;
  final RxInt handoverCount = 0.obs;
  final RxInt pendingHandoverCount = 0.obs;
  final RxBool isLoadingStats = false.obs;

  // ── Role-specific Metric Observables (API pending - kept at 0) ──────────────
  // Runner-Boy
  final RxInt runnerPickupCount = 0.obs;
  final RxInt runnerSubmitToLabCount = 0.obs;
  final RxInt runnerAcceptedByLabCount = 0.obs;

  // Lab Accession / Technician
  final RxInt labBagsSubmittedCount = 0.obs;
  final RxInt labAcceptedBagsCount = 0.obs;

  final RxBool isAvailable = true.obs;
  final RxString currentLocation = 'Fetching location…'.obs;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
    // Register route-pop listener so bag count refreshes every time the user
    // returns from any screen — no changes to RouteManager needed.
    DashboardRouteObserver.instance.addListener(_onRoutePopped);
  }

  @override
  void onClose() {
    DashboardRouteObserver.instance.removeListener(_onRoutePopped);
    super.onClose();
  }

  void _onRoutePopped() {
    // Only act for roles that track bags
    if (_shouldTrackBags) {
      kPrint('🔄 Route popped — refreshing bag count');
      refreshBagCount();
    }
  }

  // ── Bootstrap ─────────────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    await _loadUserData(); // fast — reads local/cached data
    await Future.wait([
      _loadUserProfile(), // non-blocking profile fetch
      _fetchCollectedBagsCount(),
      _fetchDashboardStats(),
      _fetchCurrentLocation(),
      _fetchNotices(),
    ]);
  }

  // ── Data Loading ──────────────────────────────────────────────────────────────

  Future<void> _loadUserData() async {
    try {
      final data = await _authManager.getUserData();
      if (data == null) {
        kPrint('❌ AuthManager returned null');
        return;
      }

      final userMap = data['user'];
      if (userMap == null || userMap is! Map<String, dynamic>) {
        kPrint('❌ "user" key missing or invalid');
        return;
      }

      final parsed = UserModel.fromJson(userMap);
      userData.value = parsed;
      userName.value = parsed.name;
      userRole.value = _authManager.getUserRole();

      kPrint('✅ User: ${userName.value} | Role: ${userRole.value}');
    } catch (e) {
      kPrint('❌ _loadUserData: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      userProfile.value = await _userService.getUserProfile();
    } catch (e) {
      kPrint('❌ _loadUserProfile: $e');
    }
  }

  // ── Bag Count ─────────────────────────────────────────────────────────────────

  bool get _shouldTrackBags =>
      const [UserRole.runnerBoy, UserRole.connector].contains(userRole.value);

  Future<void> _fetchCollectedBagsCount() async {
    if (!_shouldTrackBags) return;

    try {
      isLoadingBagCount.value = true;

      final user = await _userService.getUser();
      if (user == null) {
        kPrint('❌ getUser() null — cannot fetch bag count');
        return;
      }

      final response = await _bagsService.getCollectedQRBagDetails(
        user.empCode,
      );

      if (response.isSuccess && response.output != null) {
        collectedBagsCount.value = response.output!.length;
        kPrint('✅ Bag count: ${collectedBagsCount.value}');
      } else {
        collectedBagsCount.value = 0;
        kPrint('⚠️ Bag count fetch: no data');
      }
    } catch (e) {
      collectedBagsCount.value = 0;
      kPrint('❌ _fetchCollectedBagsCount: $e');
    } finally {
      isLoadingBagCount.value = false;
    }
  }

  /// Public — can be called manually if needed.
  Future<void> refreshBagCount() => _fetchCollectedBagsCount();

  // ── Role-based Cards ──────────────────────────────────────────────────────────

  List<DashboardTileCard> getRoleBasedStatCards() {
    switch (userRole.value) {
      case UserRole.phlebotomist:
      case UserRole.paramedic:
        return _phlebotomistCards();
      case UserRole.runnerBoy:
        return _runnerBoyCards();

      case UserRole.labTechnician:
      case UserRole.labAccession:
        return _labTechnicianCards();
      case UserRole.teamLead:
        return _teamLeadCards();

      default:
        return _defaultCards();
    }
  }

  List<DashboardTileCard> _phlebotomistCards() => [
    DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: AppStrings.manageBags,
      subtitle: 'Open, close, re-open,\nview bags',
      icon: AppAssets.collectSampleIcon,
      borderColor: const Color(0xFF3B82F6),
      // blue
      onTap: RouteManager.navigateToBagStatusDashboard,
    ),
    DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: AppStrings.orderManagement,
      subtitle: 'View and manage\nsample collection orders',
      icon: AppAssets.manageOrderIcon,
      borderColor: const Color(0xFF14B8A6),
      // teal
      onTap: RouteManager.navigateToPatientQueue,
    ),
    DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: AppStrings.manageSampleRecollections,
      subtitle: 'View & manage sample\n re-collection orders',
      icon: AppAssets.sampleRecollectionIconOg,
      borderColor: Colors.purple,
      onTap: RouteManager.navigateToSampleRecollection,
    ),
    DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: 'Bag\nHistory',
      subtitle: 'Track bag movement',
      icon: AppAssets.bagHistoryIcon,
      borderColor: const Color(0xFF22C55E),
      // green
      onTap: RouteManager.navigateToBagStatus,
    ),
  ];

  List<DashboardTileCard> _runnerBoyCards() => [
    DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: AppStrings.collectDestinationBag,
      icon: AppAssets.collectDestinationBag,
      subtitle: 'Pick up empty bags',
      iconBottom: -8,
      iconRight: -9,

      onTap: RouteManager.navigateToCollectEmptyBag,
    ),
    DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: 'Collect Bag From\nPhlebotomist',
      subtitle: 'Receive samples for transfer',

      icon: AppAssets.collectBagIcon,
      onTap: RouteManager.navigateToCollectBagsFromPhlebotomist,
      iconBottom: -4,
      iconRight: -6,
    ),
    DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: 'Handover\nBags',
      subtitle: 'Hand over samples to lab',
      icon: AppAssets.collectedBagsIcon,
      onTap: RouteManager.navigateToCollectedBags,
      iconBottom: -4,
      iconRight: -6,
    ),
    DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: 'Bag\nHistory',
      subtitle: 'Track bag movement',
      icon: AppAssets.bagHistoryIcon,
      borderColor: const Color(0xFF22C55E),
      onTap: RouteManager.navigateToBagStatus,
    ),
    // DashboardTileCard( variant: DashboardTileVariant.grid,title: AppStrings.samplePickup, icon: AppAssets.bagFilledWithSamples, onTap: RouteManager.navigateToSamplePickupDashboard),
  ];

  List<DashboardTileCard> _labTechnicianCards() => [
    DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: AppStrings.acceptBagInLab,
      icon: AppAssets.acceptInLabIcon,
      subtitle: 'Accept submitted bags',
      onTap: RouteManager.navigateToAcceptBagInLaboratory,
      iconRight: 4,
      iconBottom: 2,
    ),

    DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: 'Bag\nHistory',
      subtitle: 'Track bag movement',
      icon: AppAssets.bagHistoryIcon,
      onTap: RouteManager.navigateToBagStatus,
    ),
  ];

  List<DashboardTileCard> _teamLeadCards() => [
    DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: AppStrings.sampleLiveTracking,
      icon: AppAssets.liveTrackingIcon,
      onTap: RouteManager.navigateToSampleLiveTracking,
    ),
  ];

  List<DashboardTileCard> _defaultCards() => [
    DashboardTileCard(
      variant: DashboardTileVariant.grid,
      title: 'Please Connect with support team',
      icon: AppAssets.deliveryBoyIcon,
      onTap: () {},
    ),
    DashboardTileCard(
      variant: DashboardTileVariant.grid,
      title: AppStrings.sampleLiveTracking,
      icon: AppAssets.liveTrackingIcon,
      onTap: RouteManager.navigateToSampleLiveTracking,
    ),
  ];

  // ── Role-based Metrics ────────────────────────────────────────────────────────

  List<MetricData> getRoleBasedMetrics() {
    switch (userRole.value) {
      case UserRole.phlebotomist:
      case UserRole.paramedic:
        return _phlebotomistMetrics();

      case UserRole.runnerBoy:
        return _runnerBoyMetrics();

      case UserRole.labTechnician:
      case UserRole.labAccession:
        return _labTechnicianMetrics();

      default:
        return const [];
    }
  }

  List<MetricData> _phlebotomistMetrics() => [
    MetricData(
      value: assignedPatientsCount.value.toString().padLeft(2, '0'),
      label: 'Assigned\nPatients',
      icon: Icons.people_alt_rounded,
      dot: const Color(0xFF3B82F6),
    ),
    MetricData(
      value: testCollectedCount.value.toString().padLeft(2, '0'),
      label: 'Clinic\nCollections',
      icon: Icons.science_rounded,
      dot: const Color(0xFF22C55E),
    ),
    MetricData(
      value: handoverCount.value.toString().padLeft(2, '0'),
      label: 'Home\nCollections',
      icon: Icons.swap_horiz_rounded,
      dot: const Color(0xFF8B5CF6),
    ),
    MetricData(
      value: pendingHandoverCount.value.toString().padLeft(2, '0'),
      label: 'Served\nRequests',
      icon: Icons.hourglass_bottom_rounded,
      dot: const Color(0xFFF59E0B),
    ),
  ];

  List<MetricData> _runnerBoyMetrics() => [
    MetricData(
      value: runnerPickupCount.value.toString().padLeft(2, '0'),
      label: 'Pick Up',
      icon: Icons.local_shipping_rounded,
      dot: const Color(0xFF3B82F6),
    ),
    MetricData(
      value: runnerSubmitToLabCount.value.toString().padLeft(2, '0'),
      label: 'Submit to lab',
      icon: Icons.send_rounded,
      dot: const Color(0xFF8B5CF6),
    ),
    MetricData(
      value: runnerAcceptedByLabCount.value.toString().padLeft(2, '0'),
      label: 'Accepted by lab',
      icon: Icons.task_alt_rounded,
      dot: const Color(0xFF22C55E),
    ),
  ];

  List<MetricData> _labTechnicianMetrics() => [
    MetricData(
      value: labBagsSubmittedCount.value.toString().padLeft(2, '0'),
      label: 'Bags submitted\nto lab',
      icon: Icons.inventory_2_outlined,
      dot: const Color(0xFF3B82F6),
    ),
    MetricData(
      value: labAcceptedBagsCount.value.toString().padLeft(2, '0'),
      label: 'Bags accepted\nby lab',
      icon: Icons.task_alt_rounded,
      dot: const Color(0xFF22C55E),
    ),
  ];

  void _fetchRunnerBoyStats() {
    // API pending — keep zero for now
    runnerPickupCount.value = 0;
    runnerSubmitToLabCount.value = 0;
    runnerAcceptedByLabCount.value = 0;
  }

  void _fetchLabStats() {
    // API pending — keep zero for now
    labBagsSubmittedCount.value = 0;
    labAcceptedBagsCount.value = 0;
  }

  /// Call this to signal a rebuild-triggered refresh
  void onDashboardBuild() {
    // Debounce: only re-fetch if not already loading
    if (!isLoadingBagCount.value && _shouldTrackBags) {
      refreshBagCount();
    }
  }

  final RxInt refreshTick = 0.obs;

  final DashboardStatsService _dashboardStatsService = DashboardStatsService();

  void tickRefresh() => refreshTick.value++;

  /// Fetches the "orders board" numbers shown in the header stat strip.
  Future<void> _fetchDashboardStats() async {
    // Only phlebotomist and paramedic currently have dashboard summary API
    if (userRole.value != UserRole.phlebotomist &&
        userRole.value != UserRole.paramedic) {
      if (userRole.value == UserRole.runnerBoy) {
        _fetchRunnerBoyStats();
      } else if (userRole.value == UserRole.labTechnician ||
          userRole.value == UserRole.labAccession) {
        _fetchLabStats();
      }
      return;
    }

    try {
      isLoadingStats.value = true;

      final user = await _userService.getUser();

      if (user == null) {
        kPrint('❌ getUser() null — cannot fetch dashboard stats');
        return;
      }

      final PhleboDashboardSummary response = await _dashboardStatsService
          .fetchDashboardCount(userId: user.empCode.toString());

      if (response.status.toLowerCase() != 'success') {
        kPrint('❌ Dashboard API failed: ${response.message}');
        return;
      }

      // Reset values
      assignedPatientsCount.value = 0;
      testCollectedCount.value = 0;
      handoverCount.value = 0;
      pendingHandoverCount.value = 0;

      for (final item in response.output) {
        switch (item.assignStatusName.toLowerCase().trim()) {
          case 'assigned':
            assignedPatientsCount.value = item.assignstatusCount;
            break;

          case 'sample collected':
            testCollectedCount.value = item.assignstatusCount;
            break;

          case 'handovers':
            handoverCount.value = item.assignstatusCount;
            break;

          case 'pending handovers':
            pendingHandoverCount.value = item.assignstatusCount;
            break;
        }
      }

      kPrint(
        'Dashboard Stats: '
        'Assigned=${assignedPatientsCount.value}, '
        'Collected=${testCollectedCount.value}, '
        'Handovers=${handoverCount.value}, '
        'Pending=${pendingHandoverCount.value}',
      );
    } catch (e) {
      kPrint('❌ _fetchDashboardStats: $e');
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// Public — call after a collection/handover action completes so the
  /// header numbers update immediately, same pattern as refreshBagCount().
  Future<void> refreshDashboardStats() => _fetchDashboardStats();

  /// Toggles the phlebotomist's availability. Optimistic update with revert
  /// on failure — swap the TODO for your real endpoint when ready.
  Future<void> toggleAvailability() async {
    final previous = isAvailable.value;
    isAvailable.value = !previous;

    try {
      // TODO: await _userService.updateAvailability(isAvailable.value);
    } catch (e) {
      isAvailable.value = previous; // revert on failure
      kPrint('❌ toggleAvailability: $e');
    }
  }

  /// TODO: integrate a geolocation package (e.g. geolocator) + reverse
  /// geocoding to resolve a human-readable label here.
  Future<void> _fetchCurrentLocation() async {
    try {
      // final pos = await Geolocator.getCurrentPosition();
      // final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      // currentLocation.value = '${placemarks.first.subLocality}, ${placemarks.first.locality}';
      currentLocation.value = 'Kothrud, Pune';
    } catch (e) {
      currentLocation.value = 'Location unavailable';
      kPrint('❌ _fetchCurrentLocation: $e');
    }
  }

  Future<void> refreshLocation() => _fetchCurrentLocation();

  Future<void> _fetchNotices() async {
    // notices.value = await _notificationsService.getForToday();
  }
}

class DashboardRouteObserver extends NavigatorObserver {
  DashboardRouteObserver._();

  static final instance = DashboardRouteObserver._();

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback cb) {
    if (!_listeners.contains(cb)) _listeners.add(cb);
  }

  void removeListener(VoidCallback cb) => _listeners.remove(cb);

  void _notify() {
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _notify();
  }
}
