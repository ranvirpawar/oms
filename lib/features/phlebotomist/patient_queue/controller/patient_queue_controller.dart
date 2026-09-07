import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lifenity_connect/services/auth_manager.dart';

import '../../../../services/location_tracking_service.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../../sample_collection/model/sample_collection_models.dart';
import '../../sample_collection/service/sample_collection_service.dart';
import '../model/patient_queue_model.dart';
import '../service/patient_queue_service.dart';
import '../../../../utils/ui_designs/liquid_snackbar.dart' hide SnackPosition;

/// Filter options surfaced via the summary bar at the top of the screen.
enum QueueFilter { all, homeVisit, clinicVisit, rescheduled }

/// Screen-level load state. Kept explicit (rather than inferring from
/// isLoading/hasError booleans) so the view can switch on a single value.
enum QueueLoadState { initial, loading, loaded, empty, error }

class PatientQueueController extends GetxController {
  final PatientQueueService _service;
  final SampleCollectionService _sampleCollectionService;
  AuthManager authManager = Get.find<AuthManager>();

  PatientQueueController({
    PatientQueueService? service,
    SampleCollectionService? sampleCollectionService,
    this.isCollectionMode = false,
  }) : _service = service ?? PatientQueueService(),
       _sampleCollectionService =
           sampleCollectionService ?? SampleCollectionService();

  /// True when the queue was opened from the bag-registration dashboard's
  /// "Collect" action. Bag collection is only possible for patients who
  /// are physically present, so the queue is narrowed down to orders whose
  /// status is [PatientStatus.arrived].
  final bool isCollectionMode;

  /// Shared [SampleCollectionService] instance owned by this controller —
  /// reused by the queue's "Sync to LIS" action and the reject sheet so
  /// only one HTTP client/service lives for the whole screen.
  SampleCollectionService get sampleCollectionService =>
      _sampleCollectionService;

  /// Pushes the START tracking ping when the phlebotomist begins the route.
  final LocationTrackingService _locationTrackingService =
      LocationTrackingService();

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

  // ---------------------------------------------------------------------
  // Derived state
  // ---------------------------------------------------------------------

  /// Base pool every view of the queue renders from. In collection mode
  /// (bag registration entry point) only ARRIVED orders are eligible for
  /// bag collection, so everything else is dropped up-front — filter
  /// chips, search, summary counts and the list itself all operate on
  /// this narrowed set.
  Iterable<AssignedPatient> get _visiblePatients => isCollectionMode
      ? _patients.where((p) => p.status == PatientStatus.arrived)
      : _patients;

  /// Patients matching the active filter + search query, sorted so the
  /// most urgent / soonest / actionable items surface first.
  List<AssignedPatient> get filteredPatients {
    Iterable<AssignedPatient> result = _visiblePatients;

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
        // LIS sync failures ("collect") still need manual action — pin them
        // to the very top of the queue, above everything else.
        final aNeedsSync = a.status.isLisSyncFailed;
        final bNeedsSync = b.status.isLisSyncFailed;
        if (aNeedsSync != bNeedsSync) return aNeedsSync ? -1 : 1;

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

  int get totalCount => _visiblePatients.length;

  int get homeVisitCount =>
      _visiblePatients.where((p) => p.visitType == VisitType.home).length;

  int get clinicVisitCount =>
      _visiblePatients.where((p) => p.visitType == VisitType.clinic).length;

  int get rescheduledCount => _visiblePatients
      .where((p) => p.status == PatientStatus.rescheduled)
      .length;

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
        LiquidSnack.error(e.message, title: 'Refresh failed');
      }
    } catch (_) {
      LiquidSnack.error(
        'Please check your connection and try again.',
        title: 'Refresh failed',
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
        LiquidSnack.quick('Visit accepted');
        await fetchPatients(); // refresh from server
      } else {
        LiquidSnack.error('Please try again.', title: 'Action failed');
      }
    } on PatientQueueException catch (e) {
      LiquidSnack.error(e.message, title: 'Action failed');
    } catch (_) {
      LiquidSnack.error(
        'Please check your connection and try again.',
        title: 'Action failed',
      );
    } finally {
      processingIds.remove(patient.id);
    }
  }

  /// Sends the START tracking ping with the device's current GPS fix and
  /// refreshes the queue so the order flips to "En Route".
  Future<void> startRoute(AssignedPatient patient) async {
    if (processingIds.contains(patient.id)) return;
    processingIds.add(patient.id);
    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        LiquidSnack.warning(
          'Please enable location access to start the route.',
          title: 'Location required',
        );
        return;
      }
      final success = await _locationTrackingService.sendTracking(
        orderAssignDetailId: patient.orderAssignDetailId ?? 0,
        sampleCollectionOrderId: patient.sampleCollectionOrderId,
        userId: int.tryParse(empId.value) ?? 0,
        action: TrackingAction.start,
        latitude: position.latitude,
        longitude: position.longitude,
        createdBy: int.tryParse(empId.value) ?? 0,
      );
      if (success) {
        LiquidSnack.quick('Route started');
        await fetchPatients();
      } else {
        LiquidSnack.error('Please try again.', title: 'Action failed');
      }
    } on LocationTrackingException catch (e) {
      LiquidSnack.error(e.message, title: 'Action failed');
    } catch (_) {
      LiquidSnack.error(
        'Please check your connection and try again.',
        title: 'Action failed',
      );
    } finally {
      processingIds.remove(patient.id);
    }
  }

  /// Best-effort current position — returns null (instead of throwing)
  /// when permission, service or hardware isn't available.
  Future<Position?> _getCurrentPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  /// Re-pushes a "collect" (LIS sync failed) order to Disha from the queue.
  ///
  /// The API call itself lives in [SampleCollectionService.resubmitToDisha]
  /// (whose instance this controller owns); only the order id is needed.
  /// On success the queue is refreshed so the resolved order is removed /
  /// re-sorted by the server's new status.
  Future<void> syncToLis(AssignedPatient patient) async {
    if (processingIds.contains(patient.id)) return;
    processingIds.add(patient.id);
    try {
      await _sampleCollectionService.resubmitToDisha(orderId: patient.orderId,userId: empId.value);
      LiquidSnack.success(
        'Order ${patient.orderId} was pushed to Disha successfully.',
        title: 'Synced to LIS',
      );
      await fetchPatients(); // refresh from server
    } on SampleCollectionException catch (e) {
      LiquidSnack.error(e.message, title: 'Sync failed');
    } catch (_) {
      LiquidSnack.error(
        'Please check your connection and try again.',
        title: 'Sync failed',
      );
    } finally {
      processingIds.remove(patient.id);
    }
  }

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
        LiquidSnack.quick(successMessage);

        await fetchPatients();
      } else {
        LiquidSnack.error('Please try again.', title: 'Action failed');
      }
    } catch (_) {
      LiquidSnack.error(
        'Please check your connection and try again.',
        title: 'Action failed',
      );
    } finally {
      processingIds.remove(patientId);
    }
  }
}


