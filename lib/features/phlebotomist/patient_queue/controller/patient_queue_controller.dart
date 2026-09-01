import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../model/patient_queue_model.dart';
import '../service/patient_queue_service.dart';

/// Filter options surfaced via the summary bar at the top of the screen.
enum QueueFilter { all, homeVisit, clinicVisit, rescheduled }

/// Screen-level load state. Kept explicit (rather than inferring from
/// isLoading/hasError booleans) so the view can switch on a single value.
enum QueueLoadState { initial, loading, loaded, empty, error }

/// Controller for the Assigned Patients screen.
///
/// Owns all UI state: the patient list, loading/error/empty state,
/// active filter, search query, and per-card "processing" flags used to
/// prevent duplicate taps on action buttons. All business logic lives
/// here — the view only observes and calls these methods.
class PatientQueueController extends GetxController {
  final PatientQueueService _service;

  PatientQueueController({PatientQueueService? service})
      : _service = service ?? PatientQueueService();

  // ---------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------
  final RxList<AssignedPatient> _patients = <AssignedPatient>[].obs;
  final Rx<QueueLoadState> loadState = QueueLoadState.initial.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;

  final Rx<QueueFilter> activeFilter = QueueFilter.all.obs;
  final RxString searchQuery = ''.obs;

  /// IDs currently mid-action (accept/reject/reschedule/start) — used to
  /// disable buttons and show inline spinners so rapid double taps can't
  /// fire duplicate requests.
  final RxSet<String> processingIds = <String>{}.obs;

  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchPatients();
    searchController.addListener(() {
      searchQuery.value = searchController.text.trim();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------
  // Derived state
  // ---------------------------------------------------------------------

  /// Patients matching the active filter + search query, sorted so the
  /// most urgent / soonest / actionable items surface first.
  List<AssignedPatient> get filteredPatients {
    Iterable<AssignedPatient> result = _patients;

    switch (activeFilter.value) {
      case QueueFilter.homeVisit:
        result = result.where((p) => p.visitType == VisitType.home);
        break;
      case QueueFilter.clinicVisit:
        result = result.where((p) => p.visitType == VisitType.clinic);
        break;
      case QueueFilter.rescheduled:
        result = result.where((p) => p.status == PatientStatus.rescheduled);
        break;
      case QueueFilter.all:
        break;
    }

    final query = searchQuery.value.toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.orderId.toLowerCase().contains(query) ||
          p.tests.any((t) => t.toLowerCase().contains(query)));
    }

    final list = result.toList()
      ..sort((a, b) {
        // Terminal statuses (completed/cancelled/failed) sink to the bottom.
        final aTerminal = a.status.isTerminal;
        final bTerminal = b.status.isTerminal;
        if (aTerminal != bTerminal) return aTerminal ? 1 : -1;

        // Then by priority: urgent > high > normal.
        final priorityRank = {
          PriorityLevel.urgent: 0,
          PriorityLevel.high: 1,
          PriorityLevel.normal: 2,
        };
        final pCompare =
            priorityRank[a.priority]!.compareTo(priorityRank[b.priority]!);
        if (pCompare != 0) return pCompare;

        // Then by slot time — patients without a slot go last.
        if (a.slotDateTime == null && b.slotDateTime == null) return 0;
        if (a.slotDateTime == null) return 1;
        if (b.slotDateTime == null) return -1;
        return a.slotDateTime!.compareTo(b.slotDateTime!);
      });

    return list;
  }

  int get totalCount => _patients.length;
  int get homeVisitCount =>
      _patients.where((p) => p.visitType == VisitType.home).length;
  int get clinicVisitCount =>
      _patients.where((p) => p.visitType == VisitType.clinic).length;
  int get rescheduledCount =>
      _patients.where((p) => p.status == PatientStatus.rescheduled).length;

  bool get isSearching => searchQuery.value.isNotEmpty;

  // ---------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------

  Future<void> fetchPatients() async {
    loadState.value = QueueLoadState.loading;
    errorMessage.value = '';
    try {
      final result = await _service.fetchAssignedPatients();
      _patients.assignAll(result);
      loadState.value = result.isEmpty
          ? QueueLoadState.empty
          : QueueLoadState.loaded;
    } on PatientQueueException catch (e) {
      errorMessage.value = e.message;
      loadState.value = QueueLoadState.error;
    } catch (_) {
      errorMessage.value = 'Something went wrong. Please try again.';
      loadState.value = QueueLoadState.error;
    }
  }

  /// Pull-to-refresh — keeps the current list visible while refreshing
  /// rather than showing a full-screen loader, and is a no-op if a
  /// refresh is already in flight.
  Future<void> refreshPatients() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      final result = await _service.fetchAssignedPatients();
      _patients.assignAll(result);
      loadState.value =
          result.isEmpty ? QueueLoadState.empty : QueueLoadState.loaded;
      errorMessage.value = '';
    } on PatientQueueException catch (e) {
      Get.snackbar(
        'Refresh failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'Refresh failed',
        'Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  void retry() => fetchPatients();

  void setFilter(QueueFilter filter) => activeFilter.value = filter;

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  // ---------------------------------------------------------------------
  // Actions (guarded against duplicate taps via processingIds)
  // ---------------------------------------------------------------------

  Future<void> acceptAndStart(String patientId) => _runAction(
        patientId,
        () => _service.acceptAndStart(patientId),
        PatientStatus.inProgress,
        successMessage: 'Visit started',
      );

  Future<void> startRoute(String patientId) => _runAction(
        patientId,
        () => _service.startRoute(patientId),
        PatientStatus.inProgress,
        successMessage: 'Route started',
      );

  Future<void> reject(String patientId) => _runAction(
        patientId,
        () => _service.reject(patientId),
        PatientStatus.cancelled,
        successMessage: 'Assignment rejected',
      );

  Future<void> reschedule(String patientId) => _runAction(
        patientId,
        () => _service.reschedule(patientId),
        PatientStatus.rescheduled,
        successMessage: 'Visit rescheduled',
      );

  Future<void> _runAction(
    String patientId,
    Future<bool> Function() action,
    PatientStatus nextStatus, {
    required String successMessage,
  }) async {
    if (processingIds.contains(patientId)) return; // already in flight
    processingIds.add(patientId);
    try {
      final success = await action();
      if (success) {
        final index = _patients.indexWhere((p) => p.id == patientId);
        if (index != -1) {
          _patients[index] = _patients[index].copyWith(status: nextStatus);
        }
        Get.snackbar(
          successMessage,
          '',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Action failed',
          'Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Action failed',
        'Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      processingIds.remove(patientId);
    }
  }
}
