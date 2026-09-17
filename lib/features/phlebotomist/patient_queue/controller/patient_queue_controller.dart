import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lifenity_connect/services/auth_manager.dart';

import '../service/location_tracking_service.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../../sample_collection/model/sample_collection_models.dart';
import '../../sample_collection/service/sample_collection_service.dart';
import '../model/patient_queue_model.dart';
import '../service/patient_queue_service.dart';
import '../../../../utils/ui_designs/liquid_snackbar.dart' hide SnackPosition;

import '../view/widgets/queue_date_filter.dart';

import 'package:intl/intl.dart';



/// Filter options surfaced via the summary bar at the top of the screen.
enum QueueFilter { all, homeVisit, clinicVisit, rescheduled }

/// Screen-level load state. Kept explicit (rather than inferring from
/// isLoading/hasError booleans) so the view can switch on a single value.
enum QueueLoadState { initial, loading, loaded, empty, error }

/// A resolved [from, to] window (inclusive) sent to the assigned-patients
/// endpoint for a given [QueueDateFilter]. The endpoint now requires both
/// bounds, so every filter — including the previously-unbounded "Upcoming"
/// and "Past" — is capped to a fixed-size window.
class _DateRange {
  final DateTime from;
  final DateTime to;

  const _DateRange(this.from, this.to);

  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');

  String get fromStr => _apiFormat.format(from);
  String get toStr => _apiFormat.format(to);
}

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

  /// Pushes the START/END tracking pings for route + arrival.
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

  /// Which visit-type tab is active — Clinic or Home. This is the screen's
  /// primary context switch, so it lives above the status chips and isn't
  /// treated as a "clearable" filter the way search/status/date are.
  final AuthManager _authManager = Get.find<AuthManager>();

  final Rx<UserRole?> userRole = Rx<UserRole?>(null);

  final Rx<VisitType> activeVisitType = VisitType.clinic.obs;
  /// Date horizon for the queue. Defaults to Today. Unlike before, changing
  /// this now triggers a fresh network fetch scoped to the resolved
  /// from/to window (see [_dateRangeFor]) — the backend filters by date,
  /// the client no longer has (or needs) the full unfiltered patient set.
  final Rx<QueueDateFilter> activeDateFilter = QueueDateFilter.today.obs;

  /// The specific day picked from the calendar, when [activeDateFilter] is
  /// [QueueDateFilter.custom]. Normalized to midnight. Null otherwise.
  /// The specific range picked from the calendar, when [activeDateFilter] is
  /// [QueueDateFilter.custom]. Bounds normalized to midnight. Null otherwise.
  final Rx<DateTimeRange?> customRange = Rx<DateTimeRange?>(null);

  // Session values needed for the accept payload.
  final RxString empId = ''.obs;
  final RxInt unitId = 0.obs;

  /// IDs currently mid-action (accept/reject/reschedule/start/arrive) —
  /// used to disable buttons and show inline spinners so rapid double taps
  /// can't fire duplicate requests.
  final RxSet<String> processingIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    userRole.value = _authManager.getUserRole();

    activeVisitType.value =
    userRole.value == UserRole.phlebotomist
        ? VisitType.home
        : VisitType.clinic;
    getUserdata().then((_) => fetchPatients());
  }

  // ---------------------------------------------------------------------
  // Date range resolution
  // ---------------------------------------------------------------------

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  /// How far "Upcoming" and "Past" look beyond/behind their natural
  /// boundary, now that the API requires a bounded window instead of an
  /// open-ended one.

  static const int _pastWindowDays = 30;

  /// Resolves the active date filter (or an explicit [filter], used when
  /// probing a different one) into a concrete [from, to] window to send to
  /// the API. Boundaries mirror the old client-side semantics: "This week"
  /// is Mon–Sun, "Upcoming" starts the Monday after this week, "Past" ends
  /// yesterday — each of the open-ended ones is then capped to a 90-day
  /// window so the request always has both bounds.
  _DateRange _dateRangeFor(QueueDateFilter filter) {
    final today = _midnight(DateTime.now());

    switch (filter) {
      case QueueDateFilter.today:
        return _DateRange(today, today);

      case QueueDateFilter.thisWeek:
        final weekStart =
        today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));

        return _DateRange(
          weekStart,
          weekEnd.subtract(const Duration(days: 1)),
        );

      case QueueDateFilter.future:
        final tomorrow = today.add(const Duration(days: 1));
        final oneMonthLater = DateTime(
          tomorrow.year,
          tomorrow.month + 1,
          tomorrow.day,
        );

        return _DateRange(
          tomorrow,
          oneMonthLater.subtract(const Duration(days: 1)),
        );

      case QueueDateFilter.past:
        return _DateRange(
          today.subtract(const Duration(days: _pastWindowDays)),
          today.subtract(const Duration(days: 1)),
        );

      case QueueDateFilter.custom:
        final picked = customRange.value;

        if (picked == null) {
          return _DateRange(today, today);
        }

        return _DateRange(
          _midnight(picked.start),
          _midnight(picked.end),
        );
    }
  }

  // ---------------------------------------------------------------------
  // Derived state
  // ---------------------------------------------------------------------

  /// Base pool every view of the queue renders from. In collection mode
  /// (bag registration entry point) only ARRIVED orders are eligible for
  /// bag collection, so everything else is dropped up-front — filter
  /// chips, search, summary counts and the list itself all operate on
  /// this narrowed set.
  ///
  /// Note this set is already scoped to the active date window by the
  /// server (see [fetchPatients]) — no client-side date filtering happens
  /// here any more.
  Iterable<AssignedPatient> get _visiblePatients => isCollectionMode
      ? _patients.where((p) => p.status == PatientStatus.arrived)
      : _patients;

  /// [_visiblePatients] narrowed to the active visit-type tab — the shared
  /// context that both the status chips and the final patient list are
  /// built from. Date narrowing already happened server-side.
  Iterable<AssignedPatient> get _contextPatients =>
      _visiblePatients.where((p) => p.visitType == activeVisitType.value);

  /// Patients matching the active filter + search query, sorted so the
  /// most urgent / soonest / actionable items surface first.

  int get totalCount => _visiblePatients.length;

  /// Clinic-tab badge count, within the currently loaded date window.
  int get clinicVisitCount =>
      _visiblePatients.where((p) => p.visitType == VisitType.clinic).length;

  int get homeVisitCount =>
      _visiblePatients.where((p) => p.visitType == VisitType.home).length;

  int get rescheduledCount => _visiblePatients
      .where((p) => p.status == PatientStatus.rescheduled)
      .length;

  bool get isSearching => searchQuery.value.isNotEmpty;

  /// True when any *clearable* filter is active (search, status, or a
  /// non-default date horizon). The visit-type tab is a context switch,
  /// not a filter, so it's intentionally excluded here.
  bool get hasActiveFilters =>
      isSearching ||
          activeStatusFilter.value != null ||
          activeDateFilter.value != QueueDateFilter.today;

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
      final range = _dateRangeFor(activeDateFilter.value);
      final result = await _service.fetchAssignedPatients(
        userId: empId.value,
        fromDate: range.fromStr,
        toDate: range.toStr,
      );
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
  /// refresh is already in flight. Re-fetches the same date window as the
  /// active filter (it does not change filters).
  Future<void> refreshPatients() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      final range = _dateRangeFor(activeDateFilter.value);
      final result = await _service.fetchAssignedPatients(
        userId: empId.value,
        fromDate: range.fromStr,
        toDate: range.toStr,
      );
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
        'Please  try again.',
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

  /// Switches between the Clinic and Home visit-type tabs. Purely a
  /// client-side re-slice of the already-loaded date window — no refetch.
  void setVisitType(VisitType type) => activeVisitType.value = type;

  /// Switches the date horizon (Today / This week / Upcoming / Past).
  /// Any preset other than [QueueDateFilter.custom] clears a previously
  /// picked calendar date so stale state can't leak back in later. Since
  /// the API is now date-scoped, this triggers a fresh fetch for the new
  /// window rather than just re-filtering in memory.
  void setDateFilter(QueueDateFilter filter) {
    activeDateFilter.value = filter;
    if (filter != QueueDateFilter.custom) {
      customRange.value = null;
    }
    fetchPatients();
  }

  /// Applies a specific day picked from the calendar and fetches that
  /// single day's window from the API.
  /// Applies a date range picked from the calendar and fetches that
  /// window from the API.
  void setCustomRange(DateTimeRange range) {
    customRange.value = DateTimeRange(
      start: _midnight(range.start),
      end: _midnight(range.end),
    );
    activeDateFilter.value = QueueDateFilter.custom;
    fetchPatients();
  }

  void clearSearch() {
    searchQuery.value = '';
  }

  void updateSearch(String value) {
    searchQuery.value = value.trim();
  }

  /// Resets every clearable filter (search, status chip, date horizon)
  /// back to its default — used by the empty state's "Clear filters" action.
  /// Leaves the active visit-type tab untouched since that's context, not
  /// a filter to clear. Resetting the date filter re-fetches (see
  /// [setDateFilter]).
  void clearAllFilters() {
    clearSearch();
    setStatusFilter(null);
    setDateFilter(QueueDateFilter.today);
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
        'Please  try again.',
        title: 'Action failed',
      );
      await fetchPatients();
    } finally {
      processingIds.remove(patient.id);
    }
  }

  /// Sends the START tracking ping with the device's current GPS fix and
  /// refreshes the queue so the order flips to "En Route".
  ///
  /// NOTE: [blockStartRouteReason] only scans [_patients], which is now
  /// scoped to whatever date window is currently loaded (previously it was
  /// the entire unfiltered queue). An active order that falls outside the
  /// active tab's window (e.g. started yesterday while viewing "Today")
  /// will not be detected here.
  Future<void> startRoute(AssignedPatient patient) async {
    if (patient.status == PatientStatus.inRoute) {
      LiquidSnack.warning('This order is already en route.', title: 'Already in progress');
      return;
    }
    final blockReason = blockStartRouteReason(patient);
    if (blockReason != null) {
      LiquidSnack.warning(blockReason, title: 'Route already in progress',  duration: const Duration(seconds: 8));
      return;
    }
    if (processingIds.contains(patient.id)) return;
    // Defensive guard: the UI only renders "Start Route" for accepted
    // orders, but if a stale card/cached list ever lets this through for
    // an order that's already en route, don't fire a second START ping.
    if (patient.status == PatientStatus.inRoute) {
      LiquidSnack.warning(
        'This order is already en route.',
        title: 'Already in progress',
      );
      return;
    }
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
        'Please  try again.',
        title: 'Action failed',
      );
    } finally {
      processingIds.remove(patient.id);
    }
  }

  /// Sends the END tracking ping when the phlebotomist marks arrival at
  /// the patient's location, then refreshes the queue so the order flips
  /// to "Arrived". Mirrors [startRoute]'s guard/GPS/refresh pattern.
  Future<void> markArrived(AssignedPatient patient) async {
    if (processingIds.contains(patient.id)) return;
    processingIds.add(patient.id);
    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        LiquidSnack.warning(
          'Please enable location access to mark arrival.',
          title: 'Location required',
        );
        return;
      }
      final success = await _locationTrackingService.sendTracking(
        orderAssignDetailId: patient.orderAssignDetailId ?? 0,
        sampleCollectionOrderId: patient.sampleCollectionOrderId,
        userId: int.tryParse(empId.value) ?? 0,
        action: TrackingAction.end,
        latitude: position.latitude,
        longitude: position.longitude,
        createdBy: int.tryParse(empId.value) ?? 0,
      );
      if (success) {
        LiquidSnack.quick('Marked as arrived');
        await fetchPatients();
      } else {
        LiquidSnack.error(
          'Unable to mark arrival. Please try again.',
          title: 'Action failed',
        );
      }
    } on LocationTrackingException catch (e) {
      LiquidSnack.error(e.message, title: 'Action failed');
    } catch (_) {
      LiquidSnack.error(
        'Please  try again.',
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
        title: 'Synced to LIMS',
      );
      await fetchPatients(); // refresh from server
    } on SampleCollectionException catch (e) {
      LiquidSnack.error(e.message, title: 'Sync failed');
    } catch (_) {
      LiquidSnack.error(
        'Please  try again.',
        title: 'Sync failed',
      );
    } finally {
      processingIds.remove(patient.id);
    }
  }

  /// Loads the team's available slots for a reschedule date. Errors are
  /// surfaced to the sheet (inline) via [PatientQueueException] — no snackbar
  /// here so the feedback lives where the action is happening.
  Future<List<AvailableSlot>> fetchAvailableSlots(DateTime date) {
    return _service.fetchAvailableSlots(
      userId: empId.value,
      appointmentDate: date,
    );
  }

  /// Loads the selectable reschedule reasons (`GetRescheduleReasone`) shown
  /// as the mandatory dropdown inside the reschedule sheet.
  Future<List<RescheduleReason>> fetchRescheduleReasons() {
    return _service.fetchRescheduleReasons();
  }

  /// Sends an OTP to the patient's mobile for reschedule verification.
  Future<bool> sendRescheduleOtp({
    required String mobileNo,
    required int sampleCollectionOrderId,
  }) {
    return _service.sendRescheduleOtp(
      mobileNo: mobileNo,
      createdBy: int.tryParse(empId.value) ?? 0,
      sampleCollectionOrderId: sampleCollectionOrderId,
    );
  }

  /// Verifies the reschedule OTP entered by the patient.
  Future<bool> verifyRescheduleOtp({
    required String mobileNo,
    required String otp,
    required int sampleCollectionOrderId,
  }) {
    return _service.verifyRescheduleOtp(
      mobileNo: mobileNo,
      otp: otp,
      sampleCollectionOrderId: sampleCollectionOrderId,
      verifyBy: int.tryParse(empId.value) ?? 0,
    );
  }

  Future<bool> reject(AssignedPatient patient, {int? reasonId}) => _runAction(
    patient.id,
        () => _service.reject(
      patient,
      updatedBy: int.tryParse(empId.value) ?? 0,
      reasonId: reasonId,
    ),
    successMessage: 'Assignment rejected',
  );



  /// Reschedules through the shared updateOrder/assign-status flow. Keeps
  /// the same processingIds guard + refresh-on-success behavior as the other
  /// queue actions.
  Future<bool> rescheduleAssignment(
      AssignedPatient patient, {
        required DateTime newDate,
        required AvailableSlot slot,
        required int rescheduleReasonId,
      }) {
    return _runAction(
      patient.id,
          () => _service.rescheduleAssignment(
        patient,
        updatedBy: int.tryParse(empId.value) ?? 0,
        rescheduleDate: newDate,
        slot: slot,
        rescheduleReasonId: rescheduleReasonId,
      ),
      successMessage: 'Visit rescheduled',
    );
  }

  Future<bool> _runAction(
      String patientId,
      Future<bool> Function() action, {
        required String successMessage,
      }) async {
    if (processingIds.contains(patientId)) return false;

    processingIds.add(patientId);

    try {
      final success = await action();

      if (success) {
        LiquidSnack.quick(successMessage);

        await fetchPatients();
        return true;
      }

      LiquidSnack.error('Please try again.', title: 'Action failed');
      return false;
    } on PatientQueueException catch (e) {
      // Surface the backend's actual reason (e.g. the slot got booked by
      // someone else) instead of a generic connection message.
      LiquidSnack.error(e.message, title: 'Action failed');
      return false;
    } catch (_) {
      LiquidSnack.error(
        'Please  try again.',
        title: 'Action failed',
      );
      return false;
    } finally {
      processingIds.remove(patientId);
    }
  }



  /////////// Filter sections ////////////////////////////////
  final Rx<PatientStatus?> activeStatusFilter = Rx<PatientStatus?>(null);

  // ---------------------------------------------------------------------
  // Status filter chips — built from whatever statuses actually exist
  // within the current visit-type tab + date window (not the whole
  // queue), so the counts on the chips always match what's on screen.
  // ---------------------------------------------------------------------
  List<StatusFilterOption> get statusFilters {
    final counts = <PatientStatus, int>{};
    for (final p in _contextPatients) {
      counts[p.status] = (counts[p.status] ?? 0) + 1;
    }

    final statuses = counts.keys.toList()
      ..sort((a, b) => _statusRank(a).compareTo(_statusRank(b)));

    return [
      StatusFilterOption(
        status: null,
        label: 'All',
        count: _contextPatients.length,
      ),
      for (final status in statuses)
        StatusFilterOption(
          status: status,
          label: _statusLabel(status),
          count: counts[status]!,
        ),
    ];
  }

  void setStatusFilter(PatientStatus? status) =>
      activeStatusFilter.value = status;

  /// Human-readable label for a filter chip. Reuse StatusBadge's mapping
  /// here if one already exists, instead of duplicating it.
  String _statusLabel(PatientStatus status) {
    if (status.isLisSyncFailed) return 'Sync Pending';
    switch (status) {
      case PatientStatus.notAssigned:
        return 'Not Assigned';
      case PatientStatus.assigned:
        return 'Assigned';
      case PatientStatus.pending:
        return 'Pending';
      case PatientStatus.accepted:
        return 'Accepted';
      case PatientStatus.rescheduled:
        return 'Rescheduled';
      case PatientStatus.inRoute:
        return 'En Route';
      case PatientStatus.arrived:
        return 'Arrived';
      default:
        return status.toString().split('.').last;
    }
  }

  /// Lower = higher priority = appears first in both the filter bar and
  /// the queue itself.
  ///
  /// Order: orders that need *our* action right now (LIS sync failed /
  /// "Collect") surface above everything else, then the lifecycle marches
  /// forward — Assigned → Accepted → Arrived → En Route → Rescheduled —
  /// with terminal (done/rejected) cards always last.
  int _statusRank(PatientStatus status) {
    if (status.isLisSyncFailed) return 0;
    if (status.isTerminal) return 100;
    switch (status) {
      case PatientStatus.assigned:
      case PatientStatus.pending:
        return 1;
      case PatientStatus.accepted:
        return 2;
      case PatientStatus.arrived:
        return 3;
      case PatientStatus.inRoute:
        return 4;
      case PatientStatus.rescheduled:
        return 5;
      default:
        return 6;
    }
  }

  List<AssignedPatient> get filteredPatients {
    Iterable<AssignedPatient> result = _contextPatients;

    final statusFilter = activeStatusFilter.value;
    if (statusFilter != null) {
      result = result.where((p) => p.status == statusFilter);
    }

    final query = searchQuery.value.toLowerCase();
    if (query.isNotEmpty) {
      // Search covers name, address, and test only (order id / other
      // fields intentionally excluded).
      result = result.where(
            (p) =>
        p.name.toLowerCase().contains(query) ||
            (p.address?.toLowerCase().contains(query) ?? false) ||
            p.tests.any((t) => t.toLowerCase().contains(query)),
      );
    }

    final list = result.toList()
      ..sort((a, b) {
        // Primary: lifecycle-stage rank (action-taken cards first).
        final rankCompare = _statusRank(a.status).compareTo(_statusRank(b.status));
        if (rankCompare != 0) return rankCompare;

        // Tiebreaker within the same status: priority level.
        const priorityRank = {
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
  static const _activeRouteBlockingStatuses = {
    PatientStatus.inRoute,
    PatientStatus.arrived,
    PatientStatus.collect,
  };

  /// Null when it's safe to start a route for [candidate]. Otherwise a
  /// user-facing reason naming the order that's already active.
  ///
  /// Only scans the currently-loaded date window (see [fetchPatients]) —
  /// an active order outside that window won't be caught here.
  String? blockStartRouteReason(AssignedPatient candidate) {
    AssignedPatient? active;
    for (final p in _patients) {
      if (p.id != candidate.id && _activeRouteBlockingStatuses.contains(p.status)) {
        active = p;
        break;
      }
    }
    if (active == null) return null;
    return 'You already have an order for ${active.name} that is '
        '${_activeRouteStatusLabel(active.status)}. Finish or update that '
        'order before starting another route.';
  }

  String _activeRouteStatusLabel(PatientStatus status) {
    switch (status) {
      case PatientStatus.inRoute:
        return 'en route';
      case PatientStatus.arrived:
        return 'arrived, pending collection';
      case PatientStatus.collect:
        return 'ready for collection';
      default:
        return 'in progress';
    }
  }

  /// Called by the card just before it opens the Start Route confirmation.
  /// Shows the warning itself (single place for this messaging) and
  /// returns whether the card may proceed.
  bool canStartRoute(AssignedPatient patient) {
    final reason = blockStartRouteReason(patient);
    if (reason != null) {
      LiquidSnack.warning(reason, title: 'Route already in progress', duration: const Duration(seconds: 8));
      return false;
    }
    return true;
  }
}


class StatusFilterOption {
  final PatientStatus? status; // null = "All"
  final String label;
  final int count;

  const StatusFilterOption({
    required this.status,
    required this.label,
    required this.count,
  });
}
