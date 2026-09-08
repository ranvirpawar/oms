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
    isLoading.value = true;
    scanResult.value = null;
    bagDetails.value = null;
    facilityList.value = null;
    patientList.value = null;
    selectedFacility.value = null;

    try {
      // ── Step 1: GET SessionID via /GETScanQRBag ──────────────────────────
      debugPrint('⚙️ [Flow] Step 1 — scanQRBag($bagcode)');
      final step1 = await _apiService.scanQRBag(bagcode: bagcode);

      if (step1.status != 'Success' ||
          step1.output == null ||
          step1.output!.isEmpty) {
        final msg = step1.message.isNotEmpty
            ? step1.message
            : 'Bag not found or cannot be collected';
        debugPrint('⚠️ [Flow] Step 1 failed: $msg');
        LiquidSnack.warning(msg);
        Future.delayed(const Duration(seconds: 3), resetScanner);
        return;
      }

      final firstResult = step1.output!.first;
      scanResult.value = firstResult;
      debugPrint('✅ [Flow] Step 1 success. SessionID: ${firstResult.sessionID}');

      final sessionId = firstResult.sessionID.toString();

      // ── Step 2a + 2b + 2c in parallel ────────────────────────────────────
      debugPrint('⚙️ [Flow] Steps 2a/2b/2c — parallel bag detail fetches');
      bagDetailsLoading.value = true;

      final results = await Future.wait([
        _apiService.getBagDetailsForLabTeam(
          sessionId: sessionId,
          facilityCode: facilityCode.value,
        ),
        _apiService.getBagFacilityList(sessionId: sessionId),
        _apiService.getBagPatientList(sessionId: sessionId),
      ]);

      // 2a: main bag details (type=1)
      final step2a = results[0] as BagDetailsForLabResponse;
      if (step2a.status == 'Success' && step2a.output != null) {
        bagDetails.value = step2a.output;
      }

      // 2b: facility list (type=2)
      final step2b = results[1] as BagFacilityListResponse;
      if (step2b.status == 'Success' && step2b.output != null) {
        facilityList.value = step2b.output;
      }

      // 2c: patient list (type=4)
      final step2c = results[2] as BagPatientListResponse;
      if (step2c.status == 'Success' && step2c.output != null) {
        patientList.value = step2c.output;
      }

      debugPrint('✅ [Flow] All detail steps complete.');

      LiquidSnack.success(
        'Session #${firstResult.sessionID} — ${firstResult.tubecount} tubes',
        title: 'Bag Scanned',
      );
      bagDetailsLoading.value = false;
    } catch (e) {
      debugPrint('❌ [Flow] Error: $e');
      LiquidSnack.error('Failed to process bag: $e');
      bagDetailsLoading.value = false;
      resetScanner();
    } finally {
      bagDetailsLoading.value = false;
      isLoading.value = false;
    }
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
}
