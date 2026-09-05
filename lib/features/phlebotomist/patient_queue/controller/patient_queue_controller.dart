import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:lifenity_connect/services/auth_manager.dart';

import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/patient_queue_model.dart';
import '../service/patient_queue_service.dart';

/// Filter options surfaced via the summary bar at the top of the screen.
enum QueueFilter { all, homeVisit, clinicVisit, rescheduled }

/// Screen-level load state. Kept explicit (rather than inferring from
/// isLoading/hasError booleans) so the view can switch on a single value.
enum QueueLoadState { initial, loading, loaded, empty, error }

class PatientQueueController extends GetxController {
  final PatientQueueService _service;
  AuthManager authManager = Get.find<AuthManager>();

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

  // Session values needed for the accept payload.
  final RxString empId = ''.obs;
  final RxInt unitId = 0.obs;

  /// IDs currently mid-action (accept/reject/reschedule/start) — used to
  /// disable buttons and show inline spinners so rapid double taps can't
  /// fire duplicate requests.
  final RxSet<String> processingIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    getUserdata().then((_) => fetchPatients());
  }

  @override
  void onClose() {
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
      result = result.where(
        (p) =>
            p.name.toLowerCase().contains(query) ||
            p.orderId.toLowerCase().contains(query) ||
            p.tests.any((t) => t.toLowerCase().contains(query)),
      );
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
        final pCompare = priorityRank[a.priority]!.compareTo(
          priorityRank[b.priority]!,
        );
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

  /// user loading
  Future<void> getUserdata() async {
    authManager
        .getUserData()
        .then((data) {
          if (data != null) {
            final user = data['user'];
            if (user != null && user.containsKey('EmpCode')) {
              empId.value = user['EmpCode'].toString();
            }
          }
        })
        .catchError((_) {});
  }

  // ---------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------

  Future<void> fetchPatients() async {
    loadState.value = QueueLoadState.loading;
    errorMessage.value = '';
    try {
      final result = await _service.fetchAssignedPatients(userId: empId.value);
      _patients.assignAll(result);
      loadState.value = result.isEmpty
          ? QueueLoadState.empty
          : QueueLoadState.loaded;
    } on PatientQueueException catch (e) {
      kPrint(e.message);
      // Defensive: the service already normalises the backend's
      // "No record found" failure into an empty list, but if a variant slips
      // through, treat any "no record" failure as an empty queue — not an
      // error — and surface the real message in the error state otherwise.
      if (_isNoData(e)) {
        _patients.assignAll(const <AssignedPatient>[]);
        loadState.value = QueueLoadState.empty;
      } else {
        errorMessage.value = e.message;
        loadState.value = QueueLoadState.error;
      }
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
      final result = await _service.fetchAssignedPatients(userId: empId.value);
      _patients.assignAll(result);
      loadState.value = result.isEmpty
          ? QueueLoadState.empty
          : QueueLoadState.loaded;
      errorMessage.value = '';
    } on PatientQueueException catch (e) {
      if (_isNoData(e)) {
        _patients.assignAll(const <AssignedPatient>[]);
        loadState.value = QueueLoadState.empty;
        errorMessage.value = '';
      } else {
        Get.snackbar(
          'Refresh failed',
          e.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
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

  /// Whether a service exception represents an empty queue (the backend's
  /// "No record found") rather than a genuine failure — used as a defensive
  /// fallback to the service-level normalisation.
  bool _isNoData(PatientQueueException e) =>
      e.message.trim().toLowerCase().contains('no record');

  void setFilter(QueueFilter filter) => activeFilter.value = filter;

  void clearSearch() {
    searchQuery.value = '';
  }

  void updateSearch(String value) {
    searchQuery.value = value.trim();
  }

  // ---------------------------------------------------------------------
  // Actions (guarded against duplicate taps via processingIds)
  // ---------------------------------------------------------------------

  Future<void> acceptAndStart(AssignedPatient patient) async {
    if (processingIds.contains(patient.id)) return;
    processingIds.add(patient.id);
    try {
      final success = await _service.acceptAndStart(
        patient,
        updatedBy: int.tryParse(empId.value) ?? 0,
      );
      if (success) {
        Get.snackbar(
          'Visit accepted',
          '',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        await fetchPatients(); // refresh from server
      } else {
        Get.snackbar(
          'Action failed',
          'Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on PatientQueueException catch (e) {
      Get.snackbar(
        'Action failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'Action failed',
        'Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      processingIds.remove(patient.id);
    }
  }

  Future<void> startRoute(String patientId) => _runAction(
    patientId,
    () => _service.startRoute(patientId),

    successMessage: 'Route started',
  );

  Future<void> reject(AssignedPatient patient, {int? reasonId}) => _runAction(
    patient.id,
    () => _service.reject(
      patient,
      updatedBy: int.tryParse(empId.value) ?? 0,
      reasonId: reasonId,
    ),
    successMessage: 'Assignment rejected',
  );

  Future<void> reschedule(
    AssignedPatient patient, {
    required DateTime newDate,
    required String startTime,
    required String endTime,
  }) => _runAction(
    patient.id,
    () => _service.reschedule(
      patient,
      updatedBy: int.tryParse(empId.value) ?? 0,
      newDate: newDate,
      startTime: startTime,
      endTime: endTime,
    ),

    successMessage: 'Visit rescheduled',
  );

  Future<void> _runAction(
    String patientId,
    Future<bool> Function() action, {
    required String successMessage,
  }) async {
    if (processingIds.contains(patientId)) return;

    processingIds.add(patientId);

    try {
      final success = await action();

      if (success) {
        Get.snackbar(
          successMessage,
          '',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );

        await fetchPatients();
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
