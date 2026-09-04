import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../services/auth_manager.dart';
import '../../../../utils/helper_functions/helper_methods.dart';


import '../../patient_queue/model/patient_queue_model.dart';
import '../model/sample_collection_models.dart';
import '../service/sample_collection_service.dart';
import '../view/widgets/barcode_scanner_sheet.dart';

/// Per-sample-type UI state: one of these exists for every entry in
/// `orderDetails.sampleRequirements`.
class SampleBarcodeEntry {
  final int sampleTypeId;
  final String sampleType;
  final String volumeRequiredMl;

  final TextEditingController barcodeController = TextEditingController();
  final Rx<SampleCollectionStatus> status =
      SampleCollectionStatus.pending.obs;

  // Incomplete-collection fields (only relevant when status == incomplete).
  final Rxn<IncompleteReasonOption> selectedReason =
      Rxn<IncompleteReasonOption>();
  final TextEditingController remarksController = TextEditingController();

  final RxBool isScanning = false.obs;

  SampleBarcodeEntry({
    required this.sampleTypeId,
    required this.sampleType,
    required this.volumeRequiredMl,
  });

  bool get isCollected => status.value == SampleCollectionStatus.collected;
  bool get isIncomplete => status.value == SampleCollectionStatus.incomplete;
  bool get isPending => status.value == SampleCollectionStatus.pending;

  void dispose() {
    barcodeController.dispose();
    remarksController.dispose();
  }
}

enum SampleCollectionStatus { pending, collected, incomplete }

/// Steps within the module, driven by a single controller so state
/// (order id, user id, empId) survives navigation between the three screens.
enum SampleCollectionStep { orderConfirmation, otpVerification, collection }

class SampleCollectionController extends GetxController {
  SampleCollectionController({required this.assignedPatient})
      : orderId = assignedPatient.orderId.toString();

  final SampleCollectionService _service = SampleCollectionService();
  final AuthManager _authManager = AuthManager();

  final AssignedPatient assignedPatient;
  final String orderId;
  bool get isOrderAccepted => assignedPatient.status == PatientStatus.accepted|| assignedPatient.status == PatientStatus.rescheduled;
  final RxString empId = ''.obs;
  int get _userId => int.tryParse(empId.value) ?? 0;

  final Rx<SampleCollectionStep> step =
      SampleCollectionStep.orderConfirmation.obs;

  // ---- Order confirmation -------------------------------------------------
  final Rxn<OrderConfirmationDetails> orderDetails =
      Rxn<OrderConfirmationDetails>();
  final RxBool isLoadingOrder = false.obs;
  final RxString orderLoadError = ''.obs;

  // ---- OTP -----------------------------------------------------------------
  final List<TextEditingController> otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(4, (_) => FocusNode());
  final RxBool isSendingOtp = false.obs;
  final RxBool isVerifyingOtp = false.obs;
  final RxString otpError = ''.obs;
  final RxInt resendSecondsLeft = 0.obs;
  Timer? _resendTimer;

  // ---- Complications ---------------------------------------------------
  final RxList<ComplicationOption> complicationOptions =
      <ComplicationOption>[].obs;
  // complicationId -> true (yes) / false (no) / null (unanswered)
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

  int get collectedCount =>
      sampleEntries.where((e) => e.isCollected).length;
  int get incompleteCount =>
      sampleEntries.where((e) => e.isIncomplete).length;
  int get pendingCount => sampleEntries.where((e) => e.isPending).length;
  bool get allSamplesResolved => pendingCount == 0 && sampleEntries.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in otpFocusNodes) {
      f.dispose();
    }
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
      // Not accepted yet: don't call any order-related APIs. The
      // confirmation screen renders straight off `assignedPatient`.
      return;
    }
    await Future.wait([
      fetchOrderDetails(),
      _fetchSupportingLists(),
    ]);
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
    sampleEntries.assignAll(requirements
        .map((r) => SampleBarcodeEntry(
              sampleTypeId: r.sampleTypeId,
              sampleType: r.sampleType,
              volumeRequiredMl: r.volumeRequiredMl,
            ))
        .toList());
  }

  // ---------------------------------------------------------------------
  // OTP — send/verify are PLACEHOLDERS (see SampleCollectionService).
  // ---------------------------------------------------------------------

  Future<void> confirmAndCollect() async {
    step.value = SampleCollectionStep.otpVerification;
    await sendOtp();
  }

  Future<void> sendOtp() async {
    isSendingOtp.value = true;
    otpError.value = '';
    try {
      // passed the mobile number of patient form the order we have
      await _service.sendCollectionOtp(mobileNumber
          : orderId, userId: empId.value);
      _startResendTimer();
    } catch (e) {
      otpError.value = 'Unable to send OTP. Please try again.';
    } finally {
      isSendingOtp.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (resendSecondsLeft.value > 0) return;
    for (final c in otpControllers) {
      c.clear();
    }
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

  String get _otpValue => otpControllers.map((c) => c.text).join();

  Future<void> verifyOtp() async {
    final otp = _otpValue;
    if (otp.length != 4) {
      otpError.value = 'Enter the 4-digit OTP.';
      return;
    }
    isVerifyingOtp.value = true;
    otpError.value = '';
    try {
      /*final success = await _service.verifyCollectionOtp(
        mobileNumber: orderDetails.value!.patient.mobileNumber,
        otp: otp,
        userId: empId.value,
      );*/
      final success =
          await _service.verifyCollectionOtp(orderId: orderId, otp: otp);
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

  void onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < otpFocusNodes.length - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }
    if (_otpValue.length == 4) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  // ---------------------------------------------------------------------
  // Barcode entry — manual input + MobileScanner
  // ---------------------------------------------------------------------

  String getBarcodeLabel(SampleBarcodeEntry entry) {
    final vol = entry.volumeRequiredMl.trim();
    return vol.isEmpty ? entry.sampleType : '${entry.sampleType} ($vol)';
  }

  /// Manual text entry. Value is stored exactly as typed — no prefix added.
  void onBarcodeChanged(SampleBarcodeEntry entry, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      // Only fall back to pending if the row wasn't explicitly marked
      // incomplete; clearing text shouldn't silently undo an
      // incomplete-reason selection.
      if (entry.status.value == SampleCollectionStatus.collected) {
        entry.status.value = SampleCollectionStatus.pending;
      }
      return;
    }
    if (_isDuplicateBarcode(entry, trimmed)) {
      Get.snackbar(
        'Duplicate barcode',
        'This barcode is already used for another sample.',
        snackPosition: SnackPosition.TOP,
      );
    }
    entry.status.value = SampleCollectionStatus.collected;
  }

  bool _isDuplicateBarcode(SampleBarcodeEntry entry, String value) {
    return sampleEntries.any((other) =>
        other.sampleTypeId != entry.sampleTypeId &&
        other.barcodeController.text.trim().isNotEmpty &&
        other.barcodeController.text.trim() == value);
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

  /// Handles a scan result. Per requirement: no "AC" prefix is added — the
  /// raw scanned value is stored as-is (only whitespace is trimmed).
  void _processScanResult(SampleBarcodeEntry entry, String scannedCode) {
    final value = scannedCode.trim();
    entry.barcodeController.text = value;
    _closeScanner(entry);

    if (_isDuplicateBarcode(entry, value)) {
      Get.snackbar(
        'Duplicate barcode',
        'This barcode is already used for another sample.',
        snackPosition: SnackPosition.TOP,
      );
      entry.status.value = SampleCollectionStatus.pending;
      return;
    }
    entry.status.value = SampleCollectionStatus.collected;
  }

  // ---------------------------------------------------------------------
  // Partial / incomplete collection
  // ---------------------------------------------------------------------

  void markAsNotCollected(SampleBarcodeEntry entry) {
    entry.barcodeController.clear();
    entry.status.value = SampleCollectionStatus.incomplete;
  }

  void undoNotCollected(SampleBarcodeEntry entry) {
    entry.status.value = SampleCollectionStatus.pending;
    entry.selectedReason.value = null;
    entry.remarksController.clear();
  }

  void selectIncompleteReason(
    SampleBarcodeEntry entry,
    IncompleteReasonOption reason,
  ) {
    entry.selectedReason.value = reason;
  }

  List<SampleBarcodeEntry> get incompleteEntries =>
      sampleEntries.where((e) => e.isIncomplete).toList();

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
    if (sampleEntries.isEmpty) {
      return 'No sample types found for this order.';
    }
    if (pendingCount > 0) {
      return 'Please collect or mark every sample as not collected.';
    }
    for (final entry in incompleteEntries) {
      if (entry.selectedReason.value == null) {
        return 'Select a reason for ${entry.sampleType}.';
      }
    }
    // Barcode duplicate check across collected entries.
    final seen = <String>{};
    for (final entry in sampleEntries.where((e) => e.isCollected)) {
      final value = entry.barcodeController.text.trim();
      if (!seen.add(value)) {
        return 'Duplicate barcode detected for ${entry.sampleType}.';
      }
    }
    return null;
  }

  SampleCollectionPayload _buildPayload() {
    final collected = sampleEntries.where((e) => e.isCollected);
    final incomplete = sampleEntries.where((e) => e.isIncomplete);

    return SampleCollectionPayload(
      orderId: orderId,
      userId: _userId,
      orderStatusCode: incomplete.isEmpty ? 'COLLECTED' : 'PARTIALLY_COLLECTED',
      bagId: "1004",
      notes: notesController.text.trim(),
      collectedAt: DateTime.now(),
      sampleCollectionDetails: collected
          .map((e) => SampleCollectionDetailEntry(
                sampleTypeId: e.sampleTypeId,
                barcodeNo: e.barcodeController.text.trim(),
              ))
          .toList(),
      sampleCollectionComplications: complicationSelections.entries
          .where((e) => e.value != null)
          .map((e) => SampleCollectionComplicationEntry(
                complicationId: e.key,
                status: e.value!,
              ))
          .toList(),
      incompleteTests: incomplete
          .map((e) => IncompleteTestEntry(
                sampleTypeId: e.sampleTypeId,
                incompleteReasonId: e.selectedReason.value!.reasonId,
                incompleteReason: e.remarksController.text.trim().isNotEmpty
                    ? e.remarksController.text.trim()
                    : e.selectedReason.value!.reason,
              ))
          .toList(),
    );
  }

  Future<bool> submitCollection() async {
    final error = validate();
    if (error != null) {
      Get.snackbar('Incomplete', error, snackPosition: SnackPosition.TOP);
      return false;
    }

    isSubmitting.value = true;
    try {
      final payload = _buildPayload();
      final success = await _service.submitSampleCollection(payload);
      return success;
    } on SampleCollectionException catch (e) {
      Get.snackbar('Submission failed', e.message,
          snackPosition: SnackPosition.TOP);
      return false;
    } catch (e) {
      kPrint(e.toString());
      Get.snackbar(
        'Submission failed',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
