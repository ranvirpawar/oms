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
      case UserRole.teamLead:
        return _teamLeadCards();
      case UserRole.medicalOfficer:
      case UserRole.srMedicalOfficer:
      case UserRole.chiefMedicalOfficer:
        return _medicalOfficerCards();
      case UserRole.bmcAdmin:
        return _bmcAdminCards();
      case UserRole.executiveHealthOfficer:
      case UserRole.chiefMedicalSurgeon:
        return _ehoCards();
      case UserRole.projectManager:
        return _projectManagerCards();
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
      title: AppStrings.patientRegistration,
      icon: AppAssets.registrationIcon,
      onTap: RouteManager.navigateToPatientRegistrationDashboard,
    ),
    const DashboardTileCard(
      title: AppStrings.patientReport,
      icon: AppAssets.patientReport,
      onTap: RouteManager.navigateToPatientReport,
    ),
    const DashboardTileCard(
      title: AppStrings.sampleRecollection,
      icon: AppAssets.sampleRecollection,
      onTap: RouteManager.navigateToSampleRecollection,
    ),
    const DashboardTileCard(
      title: AppStrings.bagStatus,
      icon: AppAssets.bagStatus,
      onTap: RouteManager.navigateToBagStatus,
    ),
    const DashboardTileCard(
      title: AppStrings.invoiceTracking,
      icon: AppAssets.invoiceIcon,
      onTap: RouteManager.navigateToInvoiceTracking,
    ),
    const DashboardTileCard(
      title: AppStrings.mergeBarcode,
      icon: AppAssets.mergeBarcode,
      onTap: RouteManager.navigateToMergeBarcode,
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

  List<DashboardTileCard> _teamLeadCards() => [
    const DashboardTileCard(
      title: AppStrings.visitDetails,
      icon: AppAssets.visitIcon,
      onTap: RouteManager.navigateToVisitDetails,
    ),
    const DashboardTileCard(
      title: AppStrings.sampleLiveTracking,
      icon: AppAssets.liveTrackingIcon,
      onTap: RouteManager.navigateToSampleLiveTracking,
    ),
    const DashboardTileCard(
      title: AppStrings.sampleRemark,
      icon: AppAssets.remarkIcon,
      onTap: RouteManager.navigateToSampleRemark,
    ),
    const DashboardTileCard(
      title: AppStrings.zeroSampleCalendar,
      icon: AppAssets.calendarLogIcon,
      onTap: RouteManager.navigateToZeroSampleCalendar,
    ),
    const DashboardTileCard(
      title: AppStrings.patientReport,
      icon: AppAssets.patientReport,
      onTap: RouteManager.navigateToPatientReport,
    ),
    const DashboardTileCard(
      title: AppStrings.invoiceTracking,
      icon: AppAssets.invoiceIcon,
      onTap: RouteManager.navigateToInvoiceTracking,
    ),
    const DashboardTileCard(
      title: AppStrings.mergeBarcode,
      icon: AppAssets.mergeBarcode,
      onTap: RouteManager.navigateToMergeBarcode,
    ),

  ];

  List<DashboardTileCard> _medicalOfficerCards() => [
    const DashboardTileCard(
      title: AppStrings.patientReport,
      icon: AppAssets.patientReport,
      onTap: RouteManager.navigateToPatientReport,
    ),
  ];

  List<DashboardTileCard> _bmcAdminCards() => [
    const DashboardTileCard(
      title: AppStrings.summaryDashboard,
      icon: AppAssets.kpiDashboard,
      onTap: RouteManager.navigateTOTLDashboard,
    ),
    const DashboardTileCard(
      title: AppStrings.performanceDashboard,
      icon: AppAssets.performanceDashboard,
      onTap: RouteManager.navigateToPerformanceDashboard,
    ),
    const DashboardTileCard(
      title: AppStrings.testAnalysis,
      icon: AppAssets.testDashboard,
      onTap: RouteManager.navigateToTestAnalysisDashboard,
    ),
    const DashboardTileCard(
      title: AppStrings.zeroSampleCalendar,
      icon: AppAssets.calendarLogIcon,
      onTap: RouteManager.navigateToZeroSampleCalendar,
    ),
  ];

  List<DashboardTileCard> _ehoCards() => [
   /* DashboardTileCard(
      title: AppStrings.summaryDashboard,
      icon: AppAssets.kpiDashboard,
      onTap: RouteManager.navigateTOTLDashboard,
    ),
    DashboardTileCard(
      title: AppStrings.performanceDashboard,
      icon: AppAssets.performanceDashboard,
      onTap: RouteManager.navigateToPerformanceDashboard,
    ),
    DashboardTileCard(
      title: AppStrings.testAnalysis,
      icon: AppAssets.testDashboard,
      onTap: RouteManager.navigateToTestAnalysisDashboard,
    ),*/
    // consumption dashboard
    const DashboardTileCard(
      title: AppStrings.consumptionDashboard,
      icon: AppAssets.consumptionDashboard,
      onTap: RouteManager.navigateToConsumptionDashboard,

    )
  ];

  List<DashboardTileCard> _projectManagerCards() => [
    const DashboardTileCard(
      title: AppStrings.performanceDashboard,
      icon: AppAssets.performanceDashboard,
      onTap: RouteManager.navigateToPerformanceDashboard,
    ),
    const DashboardTileCard(
      title: AppStrings.sampleLiveTracking,
      icon: AppAssets.liveTrackingIcon,
      onTap: RouteManager.navigateToSampleLiveTracking,
    ),
    const DashboardTileCard(
      title: AppStrings.visitDetails,
      icon: AppAssets.visitIcon,
      onTap: RouteManager.navigateToVisitDetails,
    ),
    const DashboardTileCard(
      title: AppStrings.zeroSampleCalendar,
      icon: AppAssets.calendarLogIcon,
      onTap: RouteManager.navigateToZeroSampleCalendar,
    ),
    const DashboardTileCard(
      title: AppStrings.patientReport,
      icon: AppAssets.patientReport,
      onTap: RouteManager.navigateToPatientReport,
    ),
  ];

  List<DashboardTileCard> _defaultCards() => [
    DashboardTileCard(
      title: '',
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
/*class DashboardController extends GetxController {
  final AuthManager authManager = Get.put(AuthManager());
  final UserService userService = Get.put(UserService());

  var userName = ''.obs;
  var designation = ''.obs;

  var userData = Rx<UserModel?>(null);
  var userRole = Rx<UserRole?>(null);
  var userProfile = Rx<ProfileData?>(null);

  @override
  void onInit() {
    super.onInit();
    getUserdata();
    loadUser();
  }

  void loadUser() async {
    try {
      final user = await userService.getUser();
      if (user != null) {
        userData.value = user;
      } else {
        kPrint('❌ Failed to load user data');
      }

      final userProfileResponse = await userService.getUserProfile();
      userProfile.value = userProfileResponse;
    } catch (e) {
      kPrint('❌ Error loading user: $e');
    }
  }

  void getUserdata() async {
    try {
      final data = await authManager.getUserData();

      if (data != null) {
        final userMap = data['user'];
        if (userMap != null && userMap is Map<String, dynamic>) {
          // Store parsed model in the Rx variable
          userData.value = UserModel.fromJson(userMap);

          // Update other observables from the model
          userName.value = userData.value?.name ?? '';
          designation.value = userData.value?.designation ?? '';

          // Get and store role reactively
          userRole.value = authManager.getUserRole();
          _fetchCollectedBagsCount();

          kPrint('✅ Name set: ${userName.value}');
          kPrint('✅ Designation set: ${designation.value}');
          kPrint('✅ Role set: ${userRole.value}');
        } else {
          kPrint('❌ "user" data not found or invalid');
        }
      } else {
        kPrint('❌ No user data found');
      }
    } catch (err) {
      kPrint('❌ Error loading user data: $err');
    }
  }

  /// Get role-based stat cards
  List<DashboardTileCard> getRoleBasedStatCards() {
    switch (userRole.value) {
      case UserRole.phlebotomist:
        return _getPhlebotomistStatCards();
      case UserRole.runnerBoy:
        return _getRunnerBoyStatCards();
      case UserRole.labTechnician:
        return _getLabTechnicianStatCards();
      case UserRole.teamLead:
        return _getTeamLeadStatCards();
      case UserRole.medicalOfficer:
        return _getMedicalOfficerStatCards();
      case UserRole.srMedicalOfficer:
        return _getMedicalOfficerStatCards();
      case UserRole.bmcAdmin:
        return _bmcAdminStatCards();
      case UserRole.executiveHealthOfficer:
        return _ehoStatCards();
      case UserRole.chiefMedicalOfficer:
        return _getMedicalOfficerStatCards();
      case UserRole.projectManager:
        return _projectManagerStatCards();
      case UserRole.chiefMedicalSurgeon:
        return _ehoStatCards();

      case UserRole.connector:
        return _getConnectorStatCards();
      default:
        return _getDefaultStatCards();
    }
  }

  // Phlebotomist
  List<DashboardTileCard> _getPhlebotomistStatCards() => [
        DashboardTileCard(
          title: AppStrings.patientRegistration,
          icon: AppAssets.registrationIcon,
          onTap: RouteManager.navigateToPatientRegistrationDashboard,
        ),
        DashboardTileCard(
          title: AppStrings.patientReport,
          icon: AppAssets.patientReport,
          onTap: RouteManager.navigateToPatientReport,
        ),
        DashboardTileCard(
          title: AppStrings.sampleRecollection,
          icon: AppAssets.sampleRecollection,
          onTap: RouteManager.navigateToSampleRecollection,
        ),
        *//*DashboardTileCard(
          title: AppStrings.samplePickup,
          icon: AppAssets.bagFilledWithSamples,
          onTap: RouteManager.navigateToSamplePickupDashboard,
        ),*//*
        *//*DashboardTileCard(
          title: AppStrings.acceptBag,
          icon: AppAssets.acceptBagPhlebotomist,
          onTap: RouteManager.navigateToAcceptBag,
        ),*//*
        DashboardTileCard(
          title: AppStrings.bagStatus,
          icon: AppAssets.bagStatus,
          onTap: RouteManager.navigateToBagStatus,
        ),
       *//* DashboardTileCard(
          title: AppStrings.registeredPatients,
          icon: AppAssets.bagStatus,
          onTap: () {
            *//**//*Get.to(()=> PatientRegistrationDashboardList());*//**//*
          },
        ),*//*
        DashboardTileCard(
          title: AppStrings.invoiceTracking,
          icon: AppAssets.invoiceIcon,
          onTap: RouteManager.navigateToInvoiceTracking,
        ),
      ];

  // Runner Boy
  List<DashboardTileCard> _getRunnerBoyStatCards() => [
        DashboardTileCard(
          title: AppStrings.samplePickup,
          icon: AppAssets.bagFilledWithSamples,
          onTap: RouteManager.navigateToSamplePickupDashboard,
        ),
        DashboardTileCard(
          title: AppStrings.collectDestinationBag,
          icon: AppAssets.backPackIcon,
          onTap: RouteManager.navigateToCollectEmptyBag,
        ),
        DashboardTileCard(
          title: "Collect Bag From Phlebotomist",
          icon: AppAssets.bagFilledWithSamples,
          onTap: RouteManager.navigateToCollectBagsFromPhlebotomist,
        ),

        *//*DashboardTileCard(
          title: "Hand-Over To Connector/ Runner-Boy",
          icon: AppAssets.bagHandOverConnector,
          onTap: RouteManager.navigateToHandoverConnector,
        ),*//*
        DashboardTileCard(
          title: AppStrings.collectedSampleBags,
          icon: AppAssets.bagsCollected,
          onTap: RouteManager.navigateToCollectedBags,
        ),
        DashboardTileCard(
          title: AppStrings.bagStatus,
          icon: AppAssets.bagStatus,
          onTap: RouteManager.navigateToBagStatus,
        ),
      ];

  *//*------------------ Connector --------------------------*//*

  List<DashboardTileCard> _getConnectorStatCards() => [
        DashboardTileCard(
            title: AppStrings.collectDestinationBag,
            icon: AppAssets.backPackIcon,
            onTap: RouteManager.navigateToCollectEmptyBag),
        *//*  DashboardTileCard(
          title: "Hand-Over To Phlebotomist",
          icon: AppAssets.bagHandOverToPhlebo,
          onTap: RouteManager.navigateToHandoverPhlebotomist,
        ),*//*
        *//*   DashboardTileCard(
            title: "Hand-Over To Runner Boy",
            icon: AppAssets.bagHandOverConnector,
            onTap: RouteManager.navigateToHandoverT0RunnerBoy),*//*
        DashboardTileCard(
          title: "Collect Bag From Phlebotomist",
          icon: AppAssets.bagFilledWithSamples,
          onTap: RouteManager.navigateToCollectBagsFromPhlebotomist,
        ),
        DashboardTileCard(
          title: "Collected Sample Bags",
          icon: AppAssets.bagsCollected,
          onTap: RouteManager.navigateToCollectedBags,
        ),
        DashboardTileCard(
          title: AppStrings.bagStatus,
          icon: AppAssets.bagStatus,
          onTap: RouteManager.navigateToBagStatus,
        ),
      ];

  // Lab Technician
  List<DashboardTileCard> _getLabTechnicianStatCards() => [
        DashboardTileCard(
          title: AppStrings.acceptSampleInLab,
          icon: AppAssets.bagAcceptedInLab,
          onTap: RouteManager.navigateToSampleAccept,
        ),
        DashboardTileCard(
          title: AppStrings.acceptBagInLab,
          icon: AppAssets.bagAcceptedInLab,
          onTap: RouteManager.navigateToAcceptBagInLaboratory,
        ),
        DashboardTileCard(
          title: AppStrings.handOverToInventory,
          icon: AppAssets.bagInventory,
          onTap: RouteManager.navigateToHandOverBagToInventory,
        ),
        DashboardTileCard(
          title: AppStrings.bagStatus,
          icon: AppAssets.bagStatus,
          onTap: RouteManager.navigateToBagStatus,
        ),
      ];

  // Team Lead
  List<DashboardTileCard> _getTeamLeadStatCards() => [
        // visit details
        DashboardTileCard(
          title: AppStrings.visitDetails,
          icon: AppAssets.visitIcon,
          onTap: RouteManager.navigateToVisitDetails,
        ),
        // sample remark
        DashboardTileCard(
            title: AppStrings.sampleRemark,
            icon: AppAssets.remarkIcon,
            onTap: RouteManager.navigateToSampleRemark),
        // zero sample calendar
        DashboardTileCard(
          title: AppStrings.zeroSampleCalendar,
          icon: AppAssets.calendarLogIcon,
          onTap: RouteManager.navigateToZeroSampleCalendar,
        ),
        // patient reports
        DashboardTileCard(
          title: AppStrings.patientReport,
          icon: AppAssets.patientReport,
          onTap: RouteManager.navigateToPatientReport,
        ),
        DashboardTileCard(
          title: AppStrings.invoiceTracking,
          icon: AppAssets.invoiceIcon,
          onTap: RouteManager.navigateToInvoiceTracking,
        ),
      ];

  // Default
  List<DashboardTileCard> _getDefaultStatCards() => [
        DashboardTileCard(
          title: "",
          icon: AppAssets.deliveryBoyIcon,
          onTap: () {},
        ),
      ];

  List<DashboardTileCard> _getMedicalOfficerStatCards() => [
        DashboardTileCard(
          title: AppStrings.patientReport,
          icon: AppAssets.patientReport,
          onTap: RouteManager.navigateToPatientReport,
        )
      ];

  List<DashboardTileCard> _bmcAdminStatCards() => [
        DashboardTileCard(
            title: AppStrings.summaryDashboard,
            icon: AppAssets.kpiDashboard,
            onTap: () {
              RouteManager.navigateTOTLDashboard();
            }),
        DashboardTileCard(
            title: AppStrings.performanceDashboard,
            icon: AppAssets.performanceDashboard,
            onTap: () {
              RouteManager.navigateToPerformanceDashboard();
            }),
        DashboardTileCard(
            title: AppStrings.testAnalysis,
            icon: AppAssets.testDashboard,
            onTap: () {
              RouteManager.navigateToTestAnalysisDashboard();
            }),
        DashboardTileCard(
          title: AppStrings.zeroSampleCalendar,
          icon: AppAssets.calendarLogIcon,
          onTap: RouteManager.navigateToZeroSampleCalendar,
        ),
      ];

  List<DashboardTileCard> _ehoStatCards() => [
        DashboardTileCard(
            title: AppStrings.summaryDashboard,
            icon: AppAssets.kpiDashboard,
            onTap: () {
              RouteManager.navigateTOTLDashboard();
            }),
        DashboardTileCard(
            title: AppStrings.performanceDashboard,
            icon: AppAssets.performanceDashboard,
            onTap: () {
              RouteManager.navigateToPerformanceDashboard();
            }),
        DashboardTileCard(
            title: AppStrings.testAnalysis,
            icon: AppAssets.testDashboard,
            onTap: () {
              RouteManager.navigateToTestAnalysisDashboard();
            }),
      ];

  List<DashboardTileCard> _projectManagerStatCards() => [
        DashboardTileCard(
            title: AppStrings.performanceDashboard,
            icon: AppAssets.performanceDashboard,
            onTap: () {
              RouteManager.navigateToPerformanceDashboard();
            }),
        DashboardTileCard(
          title: AppStrings.visitDetails,
          icon: AppAssets.visitIcon,
          onTap: RouteManager.navigateToVisitDetails,
        ),
        DashboardTileCard(
          title: AppStrings.zeroSampleCalendar,
          icon: AppAssets.calendarLogIcon,
          onTap: RouteManager.navigateToZeroSampleCalendar,
        ),
        DashboardTileCard(
          title: AppStrings.patientReport,
          icon: AppAssets.patientReport,
          onTap: RouteManager.navigateToPatientReport,
        )
      ];

  final CollectedBagsService _bagsService = CollectedBagsService();
  final RxInt collectedBagsCount = 0.obs;

  Future<void> _fetchCollectedBagsCount() async {
    try {
      final role = userRole.value;
      if (role == UserRole.runnerBoy || role == UserRole.connector) {
        final user = await userService.getUser();
        if (user == null) return;

        final response =
            await _bagsService.getCollectedQRBagDetails(user.empCode);
        kPrint('✅ Collected bags count: ${response.output?.length}');

        if (response.isSuccess && response.output != null) {
          collectedBagsCount.value = response.output!.length;
        }
      }
    } catch (e) {
      kPrint('❌ Error fetching collected bags count: $e');
    }
  }
}*/
