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
import '../model/notice_model.dart';
import '../view/widget/dashboard_tile_card.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DashboardController
// ─────────────────────────────────────────────────────────────────────────────

class DashboardController extends GetxController {
  final AuthManager _authManager = Get.put(AuthManager());
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

  final RxBool isAvailable = true.obs;
  final RxString currentLocation = 'Fetching location…'.obs;

  /// Drives the header's rotating notice banner ("New patient assigned",
  /// "Visit soon" reminders, etc). TODO: populate from a real
  /// notifications/orders API instead of the placeholder list below.
  final RxList<DashboardNotice> notices = <DashboardNotice>[
    const DashboardNotice(
      icon: Icons.person_add_alt_1_rounded,
      message: 'New patient assigned — Rahul Sharma, Bavdhan',
      color: Color(0xFF3B82F6),
    ),
    const DashboardNotice(
      icon: Icons.schedule_rounded,
      message: 'Scheduled collection at 4:30 PM — please visit soon',
      color: Color(0xFFF59E0B),
    ),
    const DashboardNotice(
      icon: Icons.local_shipping_rounded,
      message: '3 bags pending handover to the lab',
      color: Color(0xFF8B5CF6),
    ),
  ].obs;

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
        return _phlebotomistCards();
      case UserRole.runnerBoy:
        return _runnerBoyCards();
      case UserRole.connector:
        return _connectorCards();
      case UserRole.labTechnician:
        return _labTechnicianCards();

      default:
        return _defaultCards();
    }
  }

  List<DashboardTileCard> _phlebotomistCards() => [
    const DashboardTileCard(

      title: AppStrings.collectSample,
      icon: AppAssets.sampleCollection,
      // backgroundImage: AppAssets.collectSampleCard,
      borderColor: Colors.blue,
      onTap: RouteManager.navigateToBagStatusDashboard,
    ),
    const DashboardTileCard(
      title: AppStrings.orderManagement,
      icon: AppAssets.orderManagement,
      // backgroundImage: AppAssets.assignedPatients,
      borderColor: Colors.orange,
      onTap: RouteManager.navigateToPatientQueue,
    ),
    const DashboardTileCard(
      title: AppStrings.collectedSampleBags,
      // backgroundImage: AppAssets.collectedBagsCard,
      icon: AppAssets.bagsCollected,
      borderColor: Colors.green,
      onTap: RouteManager.navigateToCollectedBags,
    ),

    const DashboardTileCard(
      title: AppStrings.sampleRecollection,
      icon: AppAssets.sampleRecollectionIcon,
      // backgroundImage: AppAssets.sampleRecollectionCard,
      borderColor: Colors.purple,
      onTap: RouteManager.navigateToSampleRecollection,
    ),
    const DashboardTileCard(
      title: AppStrings.bagStatus,
      icon: AppAssets.bagStatus,
      // backgroundImage: AppAssets.bagHistoryCard,
      borderColor: Colors.cyan,
      onTap: RouteManager.navigateToBagStatus,
    ),
  ];

  List<DashboardTileCard> _runnerBoyCards() => [
    const DashboardTileCard(
      title: AppStrings.collectDestinationBag,
      icon: AppAssets.backPackIcon,
      onTap: RouteManager.navigateToCollectEmptyBag,
    ),
    const DashboardTileCard(
      title: 'Collect Bag From Phlebotomist',
      icon: AppAssets.bagFilledWithSamples,
      onTap: RouteManager.navigateToCollectBagsFromPhlebotomist,
    ),
    const DashboardTileCard(
      title: AppStrings.collectedSampleBags,
      icon: AppAssets.bagsCollected,
      onTap: RouteManager.navigateToCollectedBags,
    ),
    const DashboardTileCard(
      title: AppStrings.bagStatus,
      icon: AppAssets.bagStatus,
      onTap: RouteManager.navigateToBagStatus,
    ),
    const DashboardTileCard(
      title: AppStrings.samplePickup,
      icon: AppAssets.bagFilledWithSamples,
      onTap: RouteManager.navigateToSamplePickupDashboard,
    ),
  ];

  List<DashboardTileCard> _connectorCards() => [
    const DashboardTileCard(
      title: AppStrings.collectDestinationBag,
      icon: AppAssets.backPackIcon,
      onTap: RouteManager.navigateToCollectEmptyBag,
    ),
    const DashboardTileCard(
      title: 'Collect Bag From Phlebotomist',
      icon: AppAssets.bagFilledWithSamples,
      onTap: RouteManager.navigateToCollectBagsFromPhlebotomist,
    ),
    const DashboardTileCard(
      title: AppStrings.collectedSampleBags,
      icon: AppAssets.bagsCollected,
      onTap: RouteManager.navigateToCollectedBags,
    ),
    const DashboardTileCard(
      title: AppStrings.bagStatus,
      icon: AppAssets.bagStatus,
      onTap: RouteManager.navigateToBagStatus,
    ),
    const DashboardTileCard(
      title: AppStrings.samplePickup,
      icon: AppAssets.bagFilledWithSamples,
      onTap: RouteManager.navigateToSamplePickupDashboard,
    ),
  ];

  List<DashboardTileCard> _labTechnicianCards() => [
    const DashboardTileCard(
      title: AppStrings.acceptSampleInLab,
      icon: AppAssets.bagAcceptedInLab,
      onTap: RouteManager.navigateToSampleAccept,
    ),
    const DashboardTileCard(
      title: AppStrings.acceptBagInLab,
      icon: AppAssets.bagAcceptedInLab,
      onTap: RouteManager.navigateToAcceptBagInLaboratory,
    ),
    /* DashboardTileCard(
      title: AppStrings.handOverToInventory,
      icon: AppAssets.bagInventory,
      onTap: RouteManager.navigateToHandOverBagToInventory,
    ),*/
    const DashboardTileCard(
      title: AppStrings.bagStatus,
      icon: AppAssets.bagStatus,
      onTap: RouteManager.navigateToBagStatus,
    ),
  ];

  List<DashboardTileCard> _defaultCards() => [
    DashboardTileCard(
      title: 'Please Connect with support team',
      icon: AppAssets.deliveryBoyIcon,
      onTap: () {},
    ),
  ];

  /// Call this to signal a rebuild-triggered refresh
  void onDashboardBuild() {
    // Debounce: only re-fetch if not already loading
    if (!isLoadingBagCount.value && _shouldTrackBags) {
      refreshBagCount();
    }
  }

  final RxInt refreshTick = 0.obs;

  void tickRefresh() => refreshTick.value++;
  /// Fetches the "orders board" numbers shown in the header stat strip.
  /// TODO: wire to real API — this only shows the phlebotomist's own counts.
  Future<void> _fetchDashboardStats() async {
    try {
      isLoadingStats.value = true;

      // ── Replace with real call, e.g.:
      // final stats = await _dashboardStatsService.getStats(user.empCode);
      // assignedPatientsCount.value = stats.assigned;
      // testCollectedCount.value    = stats.collected;
      // handoverCount.value         = stats.handedOver;
      // pendingHandoverCount.value  = stats.pendingHandover;

      await Future.delayed(const Duration(milliseconds: 300)); // placeholder
      assignedPatientsCount.value = 12;
      testCollectedCount.value = 45;
      handoverCount.value = 4;
      pendingHandoverCount.value = 9;
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
