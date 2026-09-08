import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/routes/route_manager.dart';
import 'package:lifenity_connect/utils/ui_designs/liquid_snackbar.dart'
    hide SnackPosition;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../componenents/otp_boxes_input.dart';
import '../../../../services/auth_manager.dart';
import '../../../../services/location_tracking_service.dart';
import '../../../../utils/helper_functions/helper_methods.dart';

import '../../patient_queue/model/patient_queue_model.dart';
import '../../patient_queue/service/patient_queue_service.dart';
import '../../patient_registration/bag_status_dashboard/controller/registrarion_bag_controller.dart';
import '../../patient_registration/bag_status_dashboard/model/qr_bag_details.dart';
import '../../patient_registration/bag_status_dashboard/model/qr_bag_session.dart';
import '../model/barcode_formatter.dart';
import '../model/sample_collection_models.dart';
import '../service/sample_collection_service.dart';
import '../view/widgets/barcode_scanner_sheet.dart';
import '../view/widgets/incomplete_bottom_sheet.dart';
import '../view/widgets/sample_collection_success_page.dart';

/// Per-sample-type UI state: one of these exists for every entry in
/// `orderDetails.sampleRequirements`.
/// One row of a sample-type's incomplete state: which reason, optional note.

class TestIncompleteInfo {
  final IncompleteReasonOption reason;
  final String remarks;

  TestIncompleteInfo({required this.reason, this.remarks = ''});
}

enum SampleCollectionStatus { pending, collected, incomplete }

enum SampleCollectionStep { orderConfirmation, otpVerification, collection }

class SampleCollectionController extends GetxController {
  SampleCollectionController({required this.assignedPatient})
    : orderId = assignedPatient.orderId.toString();

  final SampleCollectionService _service = SampleCollectionService();
  final PatientQueueService _patientQueueService = PatientQueueService();

  final RxBool isRescheduling = false.obs;
  final AuthManager _authManager = AuthManager();

  final AssignedPatient assignedPatient;
  final String orderId;

  bool get isOrderAccepted =>
      assignedPatient.status == PatientStatus.accepted ||
      assignedPatient.status == PatientStatus.rescheduled ||
      assignedPatient.status == PatientStatus.inRoute ||
      assignedPatient.status == PatientStatus.arrived;

  bool get needsToStartRoute =>
      assignedPatient.status == PatientStatus.accepted;
  final RxString empId = ''.obs;

  int get _userId => int.tryParse(empId.value) ?? 0;

  // ─── En-route tracking (live map on the order confirmation screen) ─────────
  /// Sends the END tracking ping when the phlebotomist marks arrival.
  final LocationTrackingService _locationTrackingService =
      LocationTrackingService();

  /// True while the order is "En Route" and the live map should be shown
  /// instead of the sample-collection details.
  final RxBool showRouteMap = false.obs;

  final RxBool isMarkingArrived = false.obs;

  /// Latest GPS fix — drives the blue "you are here" dot and the distance.
  final Rx<Position?> currentPosition = Rx<Position?>(null);

  StreamSubscription<Position>? _positionSub;

  /// Distance from the first GPS fix — the 0% reference for the route
  /// progress bar.
  double? _initialDistanceMeters;

  double? get destinationLat => assignedPatient.destinationLat;

  double? get destinationLng => assignedPatient.destinationLng;

  /// Straight-line distance from the current position to the patient's
  /// destination, or null when either coordinate is unknown.
  double? get distanceToPatientMeters {
    final lat = destinationLat;
    final lng = destinationLng;
    final pos = currentPosition.value;
    if (lat == null || lng == null || pos == null) return null;
    return Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
  }

  /// 0..1 estimate of how much of the route is behind us, based on the
  /// distance covered since the first fix. Clamped so GPS noise at the
  /// start (or overshooting the destination) can't push it out of range.
  double get routeProgress {
    final current = distanceToPatientMeters;
    if (current == null) return 0;
    _initialDistanceMeters ??= current;
    final initial = _initialDistanceMeters!;
    if (initial <= 0) return 1;
    return (1 - (current / initial)).clamp(0.0, 1.0);
  }

  // ─── Open-bag integration (shared BagRegistrationController) ───────────────
  /// Lazily resolves the shared bag controller. When the phlebotomist reaches
  /// this flow straight from the queue (without visiting the bag dashboard
  /// first) the controller is created here; otherwise the instance owned by
  /// the bag dashboard is reused so its live session state stays in sync.
  BagRegistrationController get bagController =>
      Get.isRegistered<BagRegistrationController>()
      ? Get.find<BagRegistrationController>()
      : Get.put(BagRegistrationController());

  /// The single currently-open bag session (or null).
  QRBagSession? get activeBag => bagController.activeBag;

  /// True only while at least one bag is open — enforced server-side too.
  bool get hasOpenBag => bagController.hasOpenBag;

  /// The open bag's identifiers, sent in the collection payload so every
  /// sample is tracked against the exact bag/session it was collected into.
  int get activeBagId => bagController.activeBagId;

  int get activeSessionId => bagController.activeSessionId;

  String get activeBagcode => bagController.activeBagcode;

  QRBagDetails? get activeBagDetails {
    final bag = activeBag;
    if (bag == null) return null;
    return bagController.bagDetailsMap[bag.bagId];
  }

  int get bagCapacity => activeBagDetails?.capacity ?? 0;

  int get bagUsed => activeBagDetails?.patientCount ?? 0;

  int get bagVacant => activeBagDetails?.spaceVacant ?? 0;

  /// 0..1 — drives the capacity bar on the active-bag card.
  double get bagFillRatio {
    final capacity = bagCapacity;
    if (capacity <= 0) return 0;
    return (bagUsed / capacity).clamp(0.0, 1.0);
  }

  bool get isBagFull => activeBagDetails != null && bagUsed >= bagCapacity;

  final Rx<SampleCollectionStep> step =
      SampleCollectionStep.orderConfirmation.obs;

  // ---- Order confirmation -------------------------------------------------
  final Rxn<OrderConfirmationDetails> orderDetails =
      Rxn<OrderConfirmationDetails>();
  final RxBool isLoadingOrder = false.obs;
  final RxString orderLoadError = ''.obs;

  // ---- OTP -----------------------------------------------------------------
  /// Reusable OTP input used by [OtpVerificationScreen]. The widget owns its
  /// controller/focus node internally — no per-digit controllers to leak or be
  /// disposed out of order. Patient OTP must not auto-detect, so the screen
  /// renders it with `enableAutofill: false`.
  final GlobalKey<OtpBoxesInputState> otpInputKey =
      GlobalKey<OtpBoxesInputState>();

  /// Currently entered OTP ('' while the OTP screen isn't mounted).
  String get otpValue => otpInputKey.currentState?.code ?? '';

  final RxBool isSendingOtp = false.obs;
  final RxBool isVerifyingOtp = false.obs;
  final RxString otpError = ''.obs;
  final RxInt resendSecondsLeft = 0.obs;
  Timer? _resendTimer;

  /// Patient's mobile number masked so only the first two and last two digits
  /// are visible — e.g. `7512345689` → `75****89`. Shown on the OTP screen so
  /// the full number is never exposed. Falls back to '' until [orderDetails]
  /// is loaded.
  String get maskedPatientMobileNumber =>
      HelperMethods.maskMobileMiddle(orderDetails.value?.mobileNumber ?? '');

  // ---- Complications ---------------------------------------------------
  final RxList<ComplicationOption> complicationOptions =
      <ComplicationOption>[].obs;
  final RxMap<int, bool?> complicationSelections = <int, bool?>{}.obs;

  // ---- Incomplete reasons ------------------------------------------------
  final RxList<IncompleteReasonOption> incompleteReasonOptions =
      <IncompleteReasonOption>[].obs;

  // ---- Sample collection ---------------------------------------------------
  final RxList<SampleBarcodeEntry> sampleEntries = <SampleBarcodeEntry>[].obs;
  final TextEditingController bagIdController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  MobileScannerController? _scannerController;
  final RxBool isScannerOpen = false.obs;
  final RxBool isSubmitting = false.obs;

  // ---- Submission result / Disha sync -------------------------------------
  final Rxn<SampleSubmissionResult> submissionResult =
      Rxn<SampleSubmissionResult>();
  final RxBool isRetryingDisha = false.obs;
  final RxString dishaRetryMessage = ''.obs;
  final RxBool dishaSyncResolved = false.obs;

  int get collectedCount => sampleEntries
      .where((e) => e.isCollected && !e.hasPartialIncomplete)
      .length;

  int get incompleteCount =>
      sampleEntries.where((e) => e.isFullyUnusable).length;

  int get pendingCount => sampleEntries.where((e) => e.isPending).length;

  bool get allSamplesResolved =>
      sampleEntries.isNotEmpty && sampleEntries.every((e) => e.isResolved);

  final RxBool complicationsExpanded = false.obs;

  int get selectedComplicationsCount =>
      complicationSelections.values.where((v) => v != null).length;

  void toggleComplicationsExpanded() {
    complicationsExpanded.value = !complicationsExpanded.value;
  }

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    _positionSub?.cancel();
    for (final e in sampleEntries) {
      e.dispose();
    }
    bagIdController.dispose();
    notesController.dispose();
    _scannerController?.dispose();
    super.onClose();
  }

  Future<void> _init() async {
    await _loadEmpId();
    if (!isOrderAccepted) {
      return;
    }
    // Accepted but not started yet — nothing to fetch till they arrive.
    if (needsToStartRoute) {
      return;
    }

    // En route — show the live map and start GPS updates instead of the
    // collection details; those only load once arrival is marked.
    if (assignedPatient.status == PatientStatus.inRoute) {
      showRouteMap.value = true;
      _startLocationUpdates();
      return;
    }

    // Load order details, supporting lists and the current open-bag session
    // in parallel. The bag session is what provides the bagId + sessionId
    // that get stamped onto the collection payload.
    await Future.wait([
      fetchOrderDetails(),
      _fetchSupportingLists(),
      bagController.ensureSessionsLoaded(),
    ]);
  }

  /// Starts streaming GPS fixes so the map's blue dot and the distance
  /// readout stay live while the phlebotomist drives to the patient.
  void _startLocationUpdates() {
    _positionSub?.cancel();
    _resolveInitialPosition();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) => currentPosition.value = pos);
  }

  /// One-shot fix so the map isn't blank while the stream warms up.
  /// Non-fatal on failure — the position stream keeps trying.
  Future<void> _resolveInitialPosition() async {
    try {
      currentPosition.value = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      // Ignored — the stream will deliver a fix when one becomes available.
    }
  }

  /// END tracking ping — flips the order out of "En Route", stops the GPS
  /// stream and loads the sample-collection details for the arrived visit.
  Future<void> markArrived() async {
    if (isMarkingArrived.value) return;
    isMarkingArrived.value = true;
    try {
      final pos =
          currentPosition.value ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
      final success = await _locationTrackingService.sendTracking(
        orderAssignDetailId: assignedPatient.orderAssignDetailId ?? 0,
        sampleCollectionOrderId: assignedPatient.sampleCollectionOrderId,
        userId: _userId,
        action: TrackingAction.end,
        latitude: pos.latitude,
        longitude: pos.longitude,
        createdBy: _userId,
      );
      if (success) {
        _positionSub?.cancel();
        showRouteMap.value = false;
        await Future.wait([
          fetchOrderDetails(),
          _fetchSupportingLists(),
          bagController.ensureSessionsLoaded(),
        ]);
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
        'Please check your connection and try again.',
        title: 'Action failed',
      );
    } finally {
      isMarkingArrived.value = false;
    }
  }

  // ---------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------

  Future<void> _loadEmpId() async {
    try {
      final data = await _authManager.getUserData();
      if (data != null) {
        final user = data['user'];
        if (user != null && user.containsKey('EmpCode')) {
          empId.value = user['EmpCode'].toString();
          kPrint(empId.value);
        }
      }
    } catch (_) {
      // Non-fatal — submission will still be attempted; backend can reject
      // if UserID is required and missing.
    }
  }

  // ---------------------------------------------------------------------
  // Order confirmation
  // ---------------------------------------------------------------------

  Future<void> fetchOrderDetails() async {
    isLoadingOrder.value = true;
    orderLoadError.value = '';
    try {
      final details = await _service.fetchOrderDetails(
        orderId: orderId,
        userId: empId.value,
      );
      orderDetails.value = details;
      _buildSampleEntries(details.sampleRequirements);
    } on SampleCollectionException catch (e) {
      orderLoadError.value = e.message;
    } catch (e) {
      kPrint(e.toString());
      orderLoadError.value = 'Something went wrong while loading this order.';
    } finally {
      isLoadingOrder.value = false;
    }
  }

  Future<void> _fetchSupportingLists() async {
    final complications = await _service.fetchComplications();
    complicationOptions.assignAll(complications);
    for (final c in complications) {
      complicationSelections[c.complicationId] = null;
    }

    final reasons = await _service.fetchIncompleteReasons();
    incompleteReasonOptions.assignAll(reasons);
  }

  void _buildSampleEntries(List<SampleTypeRequirement> requirements) {
    for (final e in sampleEntries) {
      e.dispose();
    }
    sampleEntries.assignAll(
      requirements
          .map(
            (r) => SampleBarcodeEntry(
              sampleTypeId: r.sampleTypeId,
              sampleType: r.sampleType,
              volumeRequiredMl: r.volumeRequiredMl,
              tests: r.tests,
            ),
          )
          .toList(),
    );
  }

  // ---------------------------------------------------------------------
  // OTP
  // ---------------------------------------------------------------------

  Future<void> confirmAndCollect() async {
    step.value = SampleCollectionStep.otpVerification;
    await sendOtp();
  }

  Future<void> sendOtp() async {
    isSendingOtp.value = true;
    otpError.value = '';
    try {
      final mobileNumber = orderDetails.value?.mobileNumber ?? '';
      await _service.sendCollectionOtp(
        mobileNumber: mobileNumber,
        userId: empId.value,
      );
      _startResendTimer();
    } catch (e) {
      otpError.value = 'Unable to send OTP. Please try again.';
    } finally {
      isSendingOtp.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (resendSecondsLeft.value > 0) return;
    otpInputKey.currentState?.clear();
    await sendOtp();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    resendSecondsLeft.value = 30;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsLeft.value <= 1) {
        timer.cancel();
        resendSecondsLeft.value = 0;
      } else {
        resendSecondsLeft.value--;
      }
    });
  }

  Future<void> verifyOtp() async {
    final otp = otpValue;
    if (otp.length != 4) {
      otpError.value = 'Enter the 4-digit OTP.';
      return;
    }
    isVerifyingOtp.value = true;
    otpError.value = '';
    try {
      final success = await _service.verifyCollectionOtp(
        userId: empId.value,
        otp: otp,
        mobileNumber: orderDetails.value?.mobileNumber ?? '',
      );
      if (success) {
        step.value = SampleCollectionStep.collection;
      } else {
        otpError.value = 'Incorrect OTP. Please try again.';
      }
    } catch (e) {
      otpError.value = 'Unable to verify OTP. Please try again.';
    } finally {
      isVerifyingOtp.value = false;
    }
  }

  // ---------------------------------------------------------------------
  // Barcode entry
  // ---------------------------------------------------------------------

  static final RegExp _allowedChars = RegExp(r'^[A-Za-z0-9-]+$');

  bool _isValidBarcodeFormat(String value) {
    if (value.length < 14 || value.length > 20) return false;
    if (!_allowedChars.hasMatch(value)) return false;
    // Allow at most one hyphen
    if (value.split('-').length > 2) return false;
    return true;
  }

  String getBarcodeLabel(SampleBarcodeEntry entry) {
    final vol = entry.volumeRequiredMl.trim();
    return vol.isEmpty ? entry.sampleType : '${entry.sampleType} ($vol)';
  }

  void onBarcodeChanged(
    SampleBarcodeEntry entry,
    String value, {
    bool immediate = false,
  }) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      entry.barcodeStatus.value = BarcodeCheckStatus.idle;
      entry.barcodeMessage.value = '';
      _recomputeStatus(entry);
      return;
    }

    // 2. Format (length + chars + single '-')
    if (!_isValidBarcodeFormat(trimmed)) {
      entry.barcodeStatus.value = BarcodeCheckStatus.formatError;
      entry.barcodeMessage.value =
          'Must be 14–20 characters: letters, numbers and at most one "-".';
      _recomputeStatus(entry);
      return;
    }

    if (_isDuplicateBarcode(entry, trimmed)) {
      entry.barcodeStatus.value = BarcodeCheckStatus.duplicate;
      entry.barcodeMessage.value = 'Already used for another sample.';
      _recomputeStatus(entry);
      return;
    }

    entry.barcodeStatus.value = BarcodeCheckStatus.checking;
    entry.barcodeMessage.value = '';
    _recomputeStatus(entry);

    Future<void> check() => _checkBarcodeAvailability(entry, trimmed);
    if (immediate) {
      check();
    } else {
      entry.debounceBarcodeCheck(check);
    }
  }

  Future<void> _checkBarcodeAvailability(
    SampleBarcodeEntry entry,
    String value,
  ) async {
    // Bail if the field moved on while we were debouncing/awaiting.
    if (entry.barcodeController.text.trim() != value) return;

    try {
      final available = await _service.checkBarcodeAvailability(value);
      if (entry.barcodeController.text.trim() != value) return; // stale
      entry.barcodeStatus.value = available
          ? BarcodeCheckStatus.available
          : BarcodeCheckStatus.unavailable;
      entry.barcodeMessage.value = available ? '' : 'Barcode already exists.';
    } on SampleCollectionException catch (e) {
      if (entry.barcodeController.text.trim() != value) return;
      entry.barcodeStatus.value = BarcodeCheckStatus.unavailable;
      entry.barcodeMessage.value = e.message;
    } catch (e) {
      if (entry.barcodeController.text.trim() != value) return;
      kPrint(e.toString());
      entry.barcodeStatus.value = BarcodeCheckStatus.error;
      entry.barcodeMessage.value =
          'Could not verify barcode. Check connection.';
    } finally {
      _recomputeStatus(entry);
    }
  }

  void _processScanResult(SampleBarcodeEntry entry, String scannedCode) {
    final value = scannedCode.trim();
    entry.barcodeController.text = value;
    _closeScanner(entry);
    // Scanning is a discrete action — verify immediately, no debounce.
    onBarcodeChanged(entry, value, immediate: true);
  }

  void _recomputeStatus(SampleBarcodeEntry entry) {
    if (entry.isFullyUnusable) {
      entry.status.value = SampleCollectionStatus.incomplete;
    } else if (entry.barcodeController.text.trim().isNotEmpty &&
        entry.barcodeStatus.value == BarcodeCheckStatus.available) {
      entry.status.value = SampleCollectionStatus.collected;
    } else {
      entry.status.value = SampleCollectionStatus.pending;
    }
  }

  bool _isDuplicateBarcode(SampleBarcodeEntry entry, String value) {
    return sampleEntries.any(
      (other) =>
          other.sampleTypeId != entry.sampleTypeId &&
          other.barcodeController.text.trim().isNotEmpty &&
          other.barcodeController.text.trim() == value,
    );
  }

  MobileScannerController _ensureScannerController() {
    _scannerController ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    return _scannerController!;
  }

  void openBarcodeScanner(SampleBarcodeEntry entry) {
    entry.isScanning.value = true;
    isScannerOpen.value = true;
    final scannerController = _ensureScannerController();

    Get.bottomSheet(
      BarcodeScannerSheet(
        sampleType: entry.sampleType,
        scannerController: scannerController,
        onCodeDetected: (code) => _processScanResult(entry, code),
        onClose: () => _closeScanner(entry),
      ),
      isDismissible: false,
    );
  }

  void _closeScanner(SampleBarcodeEntry entry) {
    entry.isScanning.value = false;
    isScannerOpen.value = false;
    _scannerController?.stop();
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
  }

  // ---------------------------------------------------------------------
  // Partial / incomplete collection
  // ---------------------------------------------------------------------

  void openIncompleteTestsSheet(SampleBarcodeEntry entry) {
    Get.bottomSheet(
      IncompleteTestsBottomSheet(
        entry: entry,
        reasonOptions: incompleteReasonOptions,
        onConfirm: (testInfos) => _applyIncompleteSelection(entry, testInfos),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _applyIncompleteSelection(
    SampleBarcodeEntry entry,
    Map<int, TestIncompleteInfo> testInfos,
  ) {
    entry.testIncompleteMap
      ..clear()
      ..addAll(testInfos);
    entry.testIncompleteMap.refresh();
    _recomputeStatus(entry);
  }

  void undoAllIncomplete(SampleBarcodeEntry entry) {
    entry.testIncompleteMap.clear();
    _recomputeStatus(entry);
  }

  // ---------------------------------------------------------------------
  // Complications
  // ---------------------------------------------------------------------

  void setComplication(int complicationId, bool value) {
    complicationSelections[complicationId] = value;
  }

  // ---------------------------------------------------------------------
  // Validation + submission
  // ---------------------------------------------------------------------

  String? validate() {
    if (!hasOpenBag) {
      return 'Please open a bag before submitting the collection.';
    }
    if (sampleEntries.isEmpty) {
      return 'No sample types found for this order.';
    }
    for (final entry in sampleEntries) {
      if (!entry.isResolved) {
        return 'Please collect all samples before submitting.';
      }
    }
    final seen = <String>{};
    for (final entry in sampleEntries) {
      final value = entry.barcodeController.text.trim();
      if (value.isEmpty) continue;
      if (!seen.add(value)) {
        return 'Duplicate barcode detected for ${entry.sampleType}.';
      }
    }
    return null;
  }

  SampleCollectionPayload _buildPayload() {
    final collected = sampleEntries.where(
      (e) => e.barcodeController.text.trim().isNotEmpty,
    );

    final incompleteTests = <IncompleteTestEntry>[];
    for (final entry in sampleEntries) {
      entry.testIncompleteMap.forEach((testId, info) {
        incompleteTests.add(
          IncompleteTestEntry(
            sampleTypeId: entry.sampleTypeId,
            testId: testId,
            incompleteReasonId: info.reason.reasonId,
            incompleteReason: info.remarks.isNotEmpty
                ? info.remarks
                : info.reason.reason,
          ),
        );
      });
    }

    return SampleCollectionPayload(
      orderId: orderId,
      userId: _userId,
      orderStatusCode: incompleteTests.isEmpty
          ? 'COLLECTED'
          : 'PARTIALLY_COLLECTED',
      // The open bag's real identifiers. Every sample is attributed to this
      // bag/session so movement can be traced end-to-end. (Previously these
      // were hardcoded placeholder values.)
      bagId: activeBagId,
      sessionId: activeSessionId,
      tubeCount: collected.length,
      notes: notesController.text.trim(),
      collectedAt: DateTime.now(),
      sampleCollectionDetails: collected
          .map(
            (e) => SampleCollectionDetailEntry(
              sampleTypeId: e.sampleTypeId,
              barcodeNo: e.barcodeController.text.trim(),
            ),
          )
          .toList(),
      sampleCollectionComplications: complicationSelections.entries
          .where((e) => e.value != null)
          .map(
            (e) => SampleCollectionComplicationEntry(
              complicationId: e.key,
              status: e.value!,
            ),
          )
          .toList(),
      incompleteTests: incompleteTests,
    );
  }

  /// Submits the collection. Returns the outcome instead of a bare bool
  /// so the caller can distinguish a full success from "saved, but LIS
  /// sync failed" — both of which are still routed to the success screen.
  /// Returns null on a hard failure (nothing was saved).
  Future<SampleSubmissionResult?> submitCollection() async {
    final error = validate();
    if (error != null) {
      LiquidSnack.warning(error, title: 'Incomplete');
      return null;
    }

    isSubmitting.value = true;
    try {
      final payload = _buildPayload();
      kPrint('Collection Body');
      kPrint(payload.toJson().toString());

      await _service.submitSampleCollection(payload);
      // Refresh the shared bag state silently so capacity reflects this
      // submission and the next collection flow sees current counts.
      unawaited(bagController.checkBagSession(showFeedback: false));
      final result = SampleSubmissionResult(
        outcome: SampleSubmissionOutcome.success,
        orderId: orderId,
      );
      submissionResult.value = result;
      return result;
    } on SampleCollectionException catch (e) {
      if (e.isLisSyncFailure) {
        final result = SampleSubmissionResult(
          outcome: SampleSubmissionOutcome.partialLisFailure,
          orderId: orderId,
          message: e.message,
        );
        submissionResult.value = result;
        return result;
      }
      LiquidSnack.error(title: 'Submission failed', e.message);
      return null;
    } catch (e) {
      kPrint(e.toString());
      LiquidSnack.error(
        'Something went wrong. Please try again.',
        title: 'Submission failed',
      );
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Call this from the submit button instead of the old
  /// `submitCollection()` + `Get.back(result: true)` pattern. Routes to
  /// the success screen on either a full success or a partial-LIS-failure
  /// "soft" success; does nothing on a hard failure (the snackbar above
  /// already told the user what went wrong, so they stay on the form).
  Future<void> submitAndShowResult() async {
    final result = await submitCollection();
    if (result != null) {
      Get.off(
        () => SampleCollectionSuccessPage(controller: this, result: result),
      );
    }
  }

  /// Retries the push to Disha from the success screen. Also doubles as
  /// a manual "check status" action, since the endpoint's response tells
  /// you the current sync state either way.
  Future<void> retryDishaSubmission() async {
    if (isRetryingDisha.value) return;
    isRetryingDisha.value = true;
    dishaRetryMessage.value = '';
    try {
      await _service.resubmitToDisha(orderId: orderId, userId: empId.value);
      dishaSyncResolved.value = true;
      dishaRetryMessage.value = 'Synced to Disha successfully.';
    } on SampleCollectionException catch (e) {
      dishaRetryMessage.value = e.message;
    } catch (e) {
      kPrint(e.toString());
      dishaRetryMessage.value =
          'Still unable to sync. Please try again shortly.';
    } finally {
      isRetryingDisha.value = false;
    }
  }

  /// Runs a reschedule-style action with a shared loading flag + snackbar
  /// handling, so success/failure feedback is consistent across the flow.
  Future<bool> _runAction(
    Future<bool> Function() action, {
    required String successMessage,
  }) async {
    isRescheduling.value = true;
    try {
      final success = await action();
      if (success) {
        LiquidSnack.success(successMessage, title: 'Success');
        RouteManager.redirectToHomeDashboard();
        RouteManager.navigateToPatientQueue();
      }
      return success;
    } on SampleCollectionException catch (e) {
      LiquidSnack.error(e.message, title: 'Action failed');
      return false;
    } catch (e) {
      kPrint(e.toString());
      LiquidSnack.error(
        'Something went wrong. Please try again.',
        title: 'Action failed',
      );
      return false;
    } finally {
      isRescheduling.value = false;
    }
  }

  /// Reschedules a visit using the [AvailableSlot] the backend returned for
  /// the picked date — persisted via the dedicated appointment-reschedule
  /// endpoint. The mandatory [rescheduleReasonId] picked in the sheet is sent
  /// as `RescheduleReasoneID`. Returns whether the backend accepted the
  /// reschedule so the sheet can stay open on failure.
  Future<bool> reschedule(
    AssignedPatient patient, {
    required DateTime newDate,
    required AvailableSlot slot,
    required int rescheduleReasonId,
  }) {
    return _runAction(
      () => _service.reschedule(
        orderId: patient.orderId,
        userId: int.tryParse(empId.value) ?? 0,
        createdBy: int.tryParse(empId.value) ?? 0,
        appointmentDate: newDate,
        slotId: slot.slotId,
        rescheduleReasonId: rescheduleReasonId,
      ),
      successMessage: 'Visit rescheduled',
    );
  }

  Future<List<RescheduleReason>> fetchRescheduleReasons() {
    return _patientQueueService.fetchRescheduleReasons();
  }

  Future<List<AvailableSlot>> fetchAvailableSlots(DateTime date) {
    return _patientQueueService.fetchAvailableSlots(
      userId: empId.value,
      appointmentDate: date,
    );
  }
}
