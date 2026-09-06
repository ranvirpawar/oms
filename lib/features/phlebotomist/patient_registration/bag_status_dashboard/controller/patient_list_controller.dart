import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/constants/bag_process_ids.dart';
import 'package:lifenity_connect/routes/route_manager.dart';

import '../../../../../services/user_service.dart';
import '../model/active_bag_model.dart';
import '../service/bag_registration_service.dart';

class PatientListController extends GetxController {
  final BagRegistrationService _service = BagRegistrationService();
  final UserService userService = Get.put(UserService());

  final isLoadingBags = false.obs;
  final isLoadingPatients = false.obs;
  bool isScoped = false;
  final activeBagSessions = <ActiveBagSession>[].obs;
  final selectedSession = Rxn<ActiveBagSession>();
  // change the two Rx lists' generic type
  final patientList = <PatientOrder>[].obs;
  final filteredPatientList = <PatientOrder>[].obs;
  final searchQuery = ''.obs;
  final isSubmittingToLab = false.obs;

  final searchTextController = TextEditingController();

  final userId = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }

  Future<void> _loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        userId.value = userData.empCode;
        // Only auto-fetch all sessions on the standalone PatientListPage.
        // BagDetailView calls preSelectBag() instead, so we skip this if
        // selectedSession is already set at onInit time.
        if (!isScoped && selectedSession.value == null) {
          await fetchActiveBagSessions();
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  // ─── Called by BagDetailView to bypass the dropdown flow ─────────────────
  // Directly sets the session and loads patients for that specific bag.
  // No call to fetchActiveBagSessions() — avoids unnecessary API call.

  Future<void> preSelectBag({
    required int sessionId,
    required int bagId,
    required String bagcode,
  }) async {
    selectedSession.value = ActiveBagSession(
      sessionID: sessionId,
      bagId: bagId,
      bagcode: bagcode,
    );
    await fetchPatients();
  }

  // ─── Full flow used by standalone PatientListPage ─────────────────────────

  Future<void> fetchActiveBagSessions() async {
    try {
      isLoadingBags.value = true;
      patientList.clear();
      filteredPatientList.clear();

      final response = await _service.getActiveQRBagSessions(userId.value);
      final output = response['output'];

      if (response['status'] == 'Success' &&
          output != null &&
          (output as List).isNotEmpty) {
        activeBagSessions.value =
            output.map((e) => ActiveBagSession.fromJson(e)).toList();

        // Check if we were passed a specific bag to pre-select from dashboard
        final args = Get.arguments;
        if (args != null && args['bagId'] != null) {
          final preSelected = activeBagSessions.firstWhereOrNull(
                (s) => s.bagId == args['bagId'],
          );
          selectedSession.value = preSelected ??
              ActiveBagSession(
                sessionID: args['sessionId'],
                bagId: args['bagId'],
                bagcode: args['bagcode'],
              );
        } else {
          selectedSession.value = activeBagSessions.first;
        }

        await fetchPatients();
      } else {
        activeBagSessions.clear();
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingBags.value = false;
    }
  }

  Future<void> onBagSelected(ActiveBagSession session) async {
    selectedSession.value = session;
    _clearSearch();
    await fetchPatients();
  }

  Future<void> fetchPatients() async {
    try {
      if (selectedSession.value == null) return;
      isLoadingPatients.value = true;
      patientList.clear();
      filteredPatientList.clear();

      final response = await _service.getRegistrationDetailsQRBag(
        sessionId: selectedSession.value!.sessionID,
        bagId: selectedSession.value!.bagId,
      );

      final output = response['registrationDetails'];
      if (response['status'] == 'Success' &&
          output != null &&
          (output as List).isNotEmpty) {
        patientList.value = output.map((e) => PatientOrder.fromJson(e)).toList();
        filteredPatientList.value = patientList;
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingPatients.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      filteredPatientList.value = patientList;
      return;
    }
    final lower = query.toLowerCase();
    filteredPatientList.value = patientList.where((o) => o.matchesQuery(lower)).toList();
  }

  void _clearSearch() {
    searchQuery.value = '';
    searchTextController.clear();
    filteredPatientList.value = patientList;
  }

  @override
  Future<void> refresh() async => await fetchActiveBagSessions();


  Future<void> submitToLab() async {
    final session = selectedSession.value;
    if (session == null) return;

    try {
      isSubmittingToLab.value = true;

      final response = await _service.insertQRBagSessionEvent(
        sessionId: session.sessionID,
        processId: int.parse(BagProcessId.endBagSession.processId),
        userId: userId.value,
      );

      if (response['status'] == 'Success') {
        Get.back(); // close bottom sheet
        Get.snackbar(
          'Bag Submitted',
          'Bag ${session.bagcode} has been successfully submitted to the lab.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1DB954),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        // Navigate back — bag is now closed, nothing more to do here.
        RouteManager.redirectToHomeDashboard();
      } else {
        Get.back(); // close bottom sheet
        Get.snackbar(
          'Submission Failed',
          response['message'] ?? 'Unable to submit bag. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // close bottom sheet
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmittingToLab.value = false;
    }
  }

}