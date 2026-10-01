import 'package:get/get.dart';
import 'package:lifenity_connect/features/auth/model/login_response_model.dart';
import 'package:lifenity_connect/features/auth/model/profile_model.dart';
import 'package:lifenity_connect/services/auth_manager.dart';
import 'package:lifenity_connect/services/user_service.dart';

import '../../../constants/app_assets.dart';
import '../../../constants/app_strings.dart';
import '../../../routes/route_manager.dart';
import '../../../utils/helper_functions/helper_methods.dart';
import 'package:intl/intl.dart';
import '../model/dashboard_summary_model.dart';
import '../service/dashboard_service.dart';
import '../view/widget/dashboard_tile_card.dart';
import '../../../utils/widgets/metrics_data.dart';
import 'package:flutter/material.dart';

import '../view/widget/runner_action.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DashboardController
// ─────────────────────────────────────────────────────────────────────────────

class DashboardController extends GetxController {
  final AuthManager _authManager = Get.find<AuthManager>();
  final UserService _userService = Get.put(UserService());

  // ── Observables ──────────────────────────────────────────────────────────────

  final RxString userName = ''.obs;
  final Rx<UserModel?> userData = Rx<UserModel?>(null);
  final Rx<UserRole?> userRole = Rx<UserRole?>(null);
  final Rx<ProfileData?> userProfile = Rx<ProfileData?>(null);
  final RxInt assignedPatientsCount = 0.obs;
  final RxInt clinicCollectionRequestCount = 0.obs;
  final RxInt homeRequestCount = 0.obs;
  final RxInt servedRequestsCount = 0.obs;
  final RxBool isLoadingStats = true.obs;

  // ── Role-specific Metric Observables ──────────────
  // Runner-Boy
  final RxInt runnerReadyForPickupCount = 0.obs;
  final RxInt runnerPickupCount = 0.obs;
  final RxInt runnerSubmitToLabCount = 0.obs;
  final RxInt runnerAcceptedByLabCount = 0.obs;

  // Lab Accession / Technician
  final RxInt labBagsSubmittedCount = 0.obs;
  final RxInt labAcceptedBagsCount = 0.obs;

  final RxBool isAvailable = true.obs;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
    // Refresh summary counts when returning from workflow screens.
    DashboardRouteObserver.instance.addListener(_onRoutePopped);
  }

  @override
  void onClose() {
    DashboardRouteObserver.instance.removeListener(_onRoutePopped);
    super.onClose();
  }

  void _onRoutePopped() {
    refreshDashboardStats();
  }

  // ── Bootstrap ─────────────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    await _loadUserData(); // fast — reads local/cached data
    await _loadUserProfile();
    await refreshDashboardStats();
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

  // ── Role-based Cards ──────────────────────────────────────────────────────────

  List<DashboardTileCard> getRoleBasedStatCards() {
    switch (userRole.value) {
      case UserRole.phlebotomist:
      case UserRole.paramedic:
      case UserRole.nurse:
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
   /* DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: AppStrings.collectDestinationBag,
      icon: AppAssets.collectDestinationBag,
      subtitle: 'Pick up empty bags',
      iconBottom: -8,
      iconRight: -9,

      onTap: RouteManager.navigateToCollectEmptyBag,
    ),*/
    DashboardTileCard(
      variant: DashboardTileVariant.modern,
      title: 'Collect Bags',
      subtitle: 'Pickup bags, Sample transfer and add bags',

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
      title: 'Accept Bag In\nLaboratory',
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
      case UserRole.nurse:
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
      value: clinicCollectionRequestCount.value.toString().padLeft(2, '0'),
      label: 'Clinic\nCollections',
      icon: Icons.science_rounded,
      dot: const Color(0xFF22C55E),
    ),
    MetricData(
      value: homeRequestCount.value.toString().padLeft(2, '0'),
      label: 'Home\nRequests',
      icon: Icons.swap_horiz_rounded,
      dot: const Color(0xFF8B5CF6),
    ),
    MetricData(
      value: servedRequestsCount.value.toString().padLeft(2, '0'),
      label: 'Served\nRequests',
      icon: Icons.hourglass_bottom_rounded,
      dot: const Color(0xFFF59E0B),
    ),
  ];

  List<MetricData> _runnerBoyMetrics() => [
    MetricData(
      value: runnerReadyForPickupCount.value.toString().padLeft(2, '0'),
      label: 'Ready for\nPick Up',
      icon: Icons.inventory_2_outlined,
      dot: const Color(0xFFF59E0B),
    ),
    MetricData(
      value: runnerPickupCount.value.toString().padLeft(2, '0'),
      label: 'Picked\nUp',
      icon: Icons.local_shipping_rounded,
      dot: const Color(0xFF3B82F6),
    ),
    MetricData(
      value: runnerSubmitToLabCount.value.toString().padLeft(2, '0'),
      label: 'Submitted\nto Lab',
      icon: Icons.send_rounded,
      dot: const Color(0xFF8B5CF6),
    ),
    MetricData(
      value: runnerAcceptedByLabCount.value.toString().padLeft(2, '0'),
      label: 'Accepted\nin Lab',
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
  List<RunnerAction> getRunnerQuickActions() => [
   /* RunnerAction(
      label: 'Collect Destination Bag',
      subtitle: 'Pick up empty bags',
      icon: Icons.inventory_2_outlined,
      color: const Color(0xFF3B82F6),
      onTap: RouteManager.navigateToCollectEmptyBag,
    ),
    RunnerAction(
      label: 'Collect from Phlebotomist',
      subtitle: 'Receive samples for transfer',
      icon: Icons.local_shipping_rounded,
      color: const Color(0xFF14B8A6),
      onTap: RouteManager.navigateToCollectBagsFromPhlebotomist,
    ),
    RunnerAction(
      label: 'Handover Bags',
      subtitle: 'Hand over samples to lab',
      icon: Icons.send_rounded,
      color: const Color(0xFF8B5CF6),
      onTap: RouteManager.navigateToCollectedBags,
    ),*/
  ];
  final selectedRange = DateTimeRange(
    start: DateUtils.dateOnly(DateTime.now()),
    end: DateUtils.dateOnly(DateTime.now()),
  ).obs;
  final statsError = ''.obs;
  final DashboardStatsService _dashboardStatsService = DashboardStatsService();
  int _statsRequest = 0;

  Future<void> selectDateRange(DateTimeRange range) async {
    selectedRange.value = range;
    await refreshDashboardStats();
  }

  Future<void> refreshDashboardStats() async {
    if (userRole.value == null) return;
    final request = ++_statsRequest;
    final range = selectedRange.value;
    isLoadingStats.value = true;
    statsError.value = '';
    try {
      if (userProfile.value == null) await _loadUserProfile();
      final user = userData.value;
      final profile = userProfile.value;
      if (user == null || profile == null) {
        throw StateError('User profile unavailable');
      }
      final response = await _dashboardStatsService.fetchDashboardCount(
        userId: user.empCode.toString(),
        fromDate: DateFormat('yyyy-MM-dd').format(range.start),
        toDate: DateFormat('yyyy-MM-dd').format(range.end),
        designationId: profile.desgId,
      );
      if (request != _statsRequest || isClosed) return;
      if (response.status.trim().toLowerCase() != 'success' &&
          !response.isEmptyResult) {
        throw StateError(response.message);
      }
      final summary = response.output.isEmpty
          ? const DashboardSummaryItem()
          : response.output.first;
      assignedPatientsCount.value = summary.assignedPatientsCount;
      clinicCollectionRequestCount.value = summary.clinicCollectionRequestCount;
      homeRequestCount.value = summary.homeRequestCount;
      servedRequestsCount.value = summary.servedRequests;
      runnerReadyForPickupCount.value = summary.readyForPickUp;
      runnerPickupCount.value = summary.pickedUp;
      runnerSubmitToLabCount.value = summary.submitToLab;
      runnerAcceptedByLabCount.value = summary.acceptedInLab;
      labBagsSubmittedCount.value = summary.submitToLab;
      labAcceptedBagsCount.value = summary.acceptedInLab;
    } catch (e) {
      if (request == _statsRequest && !isClosed) {
        statsError.value =
            'Unable to load dashboard stats. Pull down to retry.';
        kPrint('Dashboard stats: $e');
      }
    } finally {
      isLoadingStats.value = false;
      // if (request == _statsRequest && !isClosed) isLoadingStats.value = false;
    }
  }

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
    if (route is PageRoute) _notify();
  }
}
