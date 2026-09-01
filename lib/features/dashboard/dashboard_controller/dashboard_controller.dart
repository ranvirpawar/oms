import 'package:flutter/cupertino.dart';
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
    await _loadUserData();                    // fast — reads local/cached data
    await Future.wait([
      _loadUserProfile(),                     // non-blocking profile fetch
      _fetchCollectedBagsCount(),             // bag count (runner/connector only)
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
      userName.value = parsed.name ;
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

      final response =
      await _bagsService.getCollectedQRBagDetails(user.empCode);

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

  // ── Card Definitions ──────────────────────────────────────────────────────────
  // Navigation: RouteManager methods are void (they call Get.to internally).
  // Bag-count refresh is handled automatically via DashboardRouteObserver —
  // no .then() wrappers needed here, keeping card definitions clean.

  List<DashboardTileCard> _phlebotomistCards() => [
    const DashboardTileCard(
      title: AppStrings.collectSample,
      backgroundImage: AppAssets.collectSampleCard,
      borderColor: Colors.blue,
      onTap: RouteManager.navigateToPatientRegistrationDashboard,
    ),
    const DashboardTileCard(
      title: AppStrings.assignedPatient,
      backgroundImage: AppAssets.assignedPatients,
      borderColor: Colors.orange,
      onTap: RouteManager.navigateToSampleRecollection,
    ),
    const DashboardTileCard(
      title: AppStrings.collectedSampleBags,
      backgroundImage: AppAssets.collectedBagsCard,
      borderColor: Colors.green,
      onTap: RouteManager.navigateToCollectedBags,
    ),

    const DashboardTileCard(
      title: AppStrings.sampleRecollection,
      backgroundImage: AppAssets.sampleRecollectionCard,
      borderColor: Colors.purple,
      onTap: RouteManager.navigateToSampleRecollection,
    ),
    const DashboardTileCard(
      title: AppStrings.bagStatus,
      backgroundImage: AppAssets.bagHistoryCard,
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
