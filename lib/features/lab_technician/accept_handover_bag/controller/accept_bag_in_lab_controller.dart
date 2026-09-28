// lib/features/lab_technician/accept_bag_in_lab/controller/accept_bag_in_lab_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide SnackPosition;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../services/user_service.dart';
import '../../../../utils/ui_designs/liquid_snackbar.dart';
import '../../../auth/model/login_response_model.dart';
import '../model/bag_details_extended_model.dart';
import '../model/bag_model_new.dart';
import '../service/lab_accession_api_service.dart';





class AcceptBagInLabController extends GetxController {
  final LabAccessionService _apiService = LabAccessionService();

  // ─── Scanner ───────────────────────────────────────────────────────────────
  late MobileScannerController scannerController;
  final TextEditingController manualBarcodeController = TextEditingController();

  // ─── Observables ──────────────────────────────────────────────────────────
  final scannedBarcode = Rx<String?>(null);

  /// Step 1 result — contains SessionID + basic bag info
  final scanResult = Rx<ScanQRBagOutput?>(null);

  /// Step 2 (type=1) — detailed bag info for display
  final bagDetails = Rx<BagDetailsForLabOutput?>(null);

  /// Step 2b (type=2) — facility summary list
  final facilityList = Rx<List<BagFacilityItem>?>(null);

  /// Step 2c (type=4) — patient registration list
  final patientList = Rx<List<BagPatientItem>?>(null);

  /// Currently selected facility filter (null = "All")
  final selectedFacility = Rx<String?>(null);

  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final scannerActive = true.obs;
  final flashlightEnabled = false.obs;
  final bagDetailsLoading = false.obs;


  // ─── User ─────────────────────────────────────────────────────────────────
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final Rx<String> userId = ''.obs;
  final Rx<String> facilityCode = ''.obs;
  final UserService userService = Get.put(UserService());

  // ─── Derived: patients filtered by selected facility ──────────────────────
  List<BagPatientItem> get filteredPatients {
    final patients = patientList.value ?? [];
    final filter = selectedFacility.value;
    if (filter == null) return patients;
    return patients.where((p) => p.facilityName == filter).toList();
  }

  @override
  void onInit() {
    super.onInit();
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    loadUser();
    debugPrint('✨ [Controller] AcceptBagInLabController initialized.');
  }

  @override
  void onClose() {
    scannerController.dispose();
    manualBarcodeController.dispose();
    debugPrint('🗑️ [Controller] AcceptBagInLabController disposed.');
    super.onClose();
  }

  // ─── Load User ─────────────────────────────────────────────────────────────
  void loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = user.value?.empCode.toString() ?? '';
        debugPrint('✅ [Controller] User loaded: ${user.value?.name}');
      } else {
        debugPrint('❌ [Controller] No user data found');
      }
    } catch (e) {
      debugPrint('❌ [Controller] Error loading user: $e');
    }
  }

  // ─── Flashlight ────────────────────────────────────────────────────────────
  void toggleFlashlight() {
    flashlightEnabled.value = !flashlightEnabled.value;
    scannerController.toggleTorch();
    debugPrint('🔦 [Scanner] Flashlight: ${flashlightEnabled.value}');
  }

  // ─── Scanner Detection ─────────────────────────────────────────────────────
  void onBarcodeDetected(BarcodeCapture capture) async {
    if (!scannerActive.value || isLoading.value) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    scannerActive.value = false;
    scannedBarcode.value = barcode;
    debugPrint('🔍 [Scanner] Barcode detected: $barcode');

    await _runFullScanFlow(barcode);
  }

  void onManualBarcodeSubmit(String barcode) {
    if (barcode.trim().isEmpty) return;
    debugPrint('⌨️ [Scanner] Manual barcode: $barcode');
    _runFullScanFlow(barcode.trim());
  }


  // ─── Full Scan Flow (Step 1 → Step 2a → Step 2b → Step 2c) ───────────────
  Future<void> _runFullScanFlow(String bagcode) async {
    if (isLoading.value) return;

    isLoading.value = true;
    scannerActive.value = false;

    scanResult.value = null;
    bagDetails.value = null;
    facilityList.value = null;
    patientList.value = null;
    selectedFacility.value = null;

    try {
      // ─────────────────────────────────────────────────────────────
      // STEP 1
      // ─────────────────────────────────────────────────────────────
      debugPrint('⚙️ [Flow] Step 1 — scanQRBag($bagcode)');

      final step1 = await _apiService.scanQRBag(
        bagcode: bagcode,
      );

      // Don't depend on status/statusCode.
      // Required output itself is the validation.
      if (step1.output == null || step1.output!.isEmpty) {
        final message = step1.message.isNotEmpty
            ? step1.message
            : 'Bag not found';

        debugPrint('⚠️ [Flow] Step 1 invalid: $message');

        LiquidSnack.warning(message);

        await _resetScannerAfterFailure();
        return;
      }

      final firstResult = step1.output!.first;

      scanResult.value = firstResult;

      final sessionId = firstResult.sessionID.toString();

      debugPrint(
        '✅ [Flow] Step 1 complete. SessionID: $sessionId',
      );

      // ─────────────────────────────────────────────────────────────
      // STEP 2A
      //
      // MAIN VALIDATION CALL.
      // DO NOT start type 2 / type 4 before this succeeds.
      // ─────────────────────────────────────────────────────────────
      debugPrint(
        '⚙️ [Flow] Step 2a — validating bag before further calls',
      );

      bagDetailsLoading.value = true;

      BagDetailsForLabResponse step2a;

      try {
        step2a = await _apiService.getBagDetailsForLabTeam(
          sessionId: sessionId,
          facilityCode: facilityCode.value,
        );
      } catch (e) {
        // Backend rejected the bag.
        // Show message ONCE and STOP here.
        final message = _extractErrorMessage(e);

        debugPrint(
          '❌ [Flow] Bag validation failed: $message',
        );

        LiquidSnack.warning(message);

        await _resetScannerAfterFailure();

        return;
      }

      // Even if the request doesn't throw,
      // no output means we cannot continue.
      if (step2a.output == null) {
        final message = step2a.message.isNotEmpty
            ? step2a.message
            : 'Bag details not available';

        debugPrint(
          '⚠️ [Flow] Bag details empty: $message',
        );

        LiquidSnack.warning(message);

        await _resetScannerAfterFailure();

        return;
      }

      // ─────────────────────────────────────────────────────────────
      // Type 1 valid → bag can continue
      // ─────────────────────────────────────────────────────────────
      bagDetails.value = step2a.output;

      debugPrint(
        '✅ [Flow] Bag validated successfully: '
            '${bagDetails.value?.bagQRCode}',
      );

      // ─────────────────────────────────────────────────────────────
      // STEP 2B + 2C
      //
      // These calls happen ONLY after type 1 passes.
      // ─────────────────────────────────────────────────────────────
      debugPrint(
        '⚙️ [Flow] Fetching facility + patient details...',
      );

      final results = await Future.wait([
        _apiService.getBagFacilityList(
          sessionId: sessionId,
        ),
        _apiService.getBagPatientList(
          sessionId: sessionId,
        ),
      ]);

      final facilityResponse =
      results[0] as BagFacilityListResponse;

      final patientResponse =
      results[1] as BagPatientListResponse;

      // Again: no status/statusCode checks.
      if (facilityResponse.output != null) {
        facilityList.value = facilityResponse.output;
      }

      if (patientResponse.output != null) {
        patientList.value = patientResponse.output;
      }

      debugPrint(
        '✅ [Flow] Full bag scan completed.',
      );

      /*LiquidSnack.success(
        'Session #${firstResult.sessionID} — '
            '${firstResult.tubecount} tubes',
        title: 'Bag Scanned',
      );*/
    } catch (e, stackTrace) {
      final message = _extractErrorMessage(e);

      debugPrint('❌ [Flow] Unexpected error: $e');
      debugPrint('$stackTrace');

      LiquidSnack.error(message);

      await _resetScannerAfterFailure();
    } finally {
      bagDetailsLoading.value = false;
      isLoading.value = false;
    }
  }

  String _extractErrorMessage(Object error) {
    final errorText = error.toString();

    // Your current exception looks like:
    //
    // Exception: Network error:
    // UnknownError(
    //   status: 400,
    //   message: This bag has not yet been submitted to the laboratory.
    // )

    final match = RegExp(
      r'message:\s*(.*?)(?:\)|$)',
    ).firstMatch(errorText);

    if (match != null) {
      final message = match.group(1)?.trim();

      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    return errorText
        .replaceFirst('Exception: ', '')
        .replaceFirst('Network error: ', '')
        .trim();
  }
  // ─── Step 3: Accept Bag ────────────────────────────────────────────────────
  Future<void> acceptBag() async {
    if (scanResult.value == null) {
      LiquidSnack.warning('Please scan a bag first');
      return;
    }

    isSubmitting.value = true;
    final sessionId = scanResult.value!.sessionID.toString();

    debugPrint('⚙️ [Flow] Step 3 — insertQRBagSessionEvent(session=$sessionId)');

    try {
      final response = await _apiService.insertQRBagSessionEvent(
        sessionId: sessionId,
        userId: userId.value,
        processId: '8',
      );

      if (response.status == 'Success') {
        debugPrint('🎉 [Flow] Step 3 success. Bag accepted!');
        LiquidSnack.success(
          response.message.isNotEmpty
              ? response.message
              : 'Bag accepted successfully',
          title: 'Accepted',
        );
        await Future.delayed(const Duration(seconds: 1));
        resetScanner();
      } else {
        debugPrint('⚠️ [Flow] Step 3 failed: ${response.message}');
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to accept bag');
      }
    } catch (e) {
      debugPrint('❌ [Flow] Accept error: $e');
      LiquidSnack.error('Failed to accept bag: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Reset ─────────────────────────────────────────────────────────────────
  void resetScanner() {
    scannedBarcode.value = null;
    scanResult.value = null;
    bagDetails.value = null;
    facilityList.value = null;
    patientList.value = null;
    selectedFacility.value = null;
    scannerActive.value = true;
    manualBarcodeController.clear();
    debugPrint('🔄 [State] Scanner reset.');
  }
  Future<void> _resetScannerAfterFailure() async {
    scannedBarcode.value = null;
    scanResult.value = null;
    bagDetails.value = null;
    facilityList.value = null;
    patientList.value = null;
    selectedFacility.value = null;

    manualBarcodeController.clear();

    // Keep scanner OFF so the same QR does not
    // immediately trigger another API call.
    scannerActive.value = false;

    debugPrint(
      '⏳ [Scanner] Failure handled. Waiting before reactivation...',
    );

    await Future.delayed(
      const Duration(seconds: 2),
    );

    scannerActive.value = true;

    debugPrint(
      '🔄 [Scanner] Ready for next scan.',
    );
  }
}
