// lib/controllers/handover_bag_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide SnackPosition;
import 'package:lifenity_connect/features/lab_technician/accept_handover_bag/service/lab_accession_api_service_old.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lifenity_connect/features/lab_technician/accept_handover_bag/model/bag_model.dart';

import '../../../../services/location_service.dart';
import '../../../../services/user_service.dart';
import '../../../../utils/ui_designs/liquid_snackbar.dart';
import '../../../auth/model/login_response_model.dart';
class HandoverBagController extends GetxController {
  final LabAccessionService _apiService = LabAccessionService();
  final LocationService _locationService = LocationService();

  // Scanner Controller
  late MobileScannerController scannerController;
  final TextEditingController manualBarcodeController = TextEditingController();

  // Observable variables
  final scannedBarcode = Rx<String?>(null);
  final bagDetails = Rx<BagDetail?>(null);
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final scannerActive = true.obs;
  final flashlightEnabled = false.obs;

  // User ID (replace with auth later)
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final Rx<String> userId = ''.obs;
  final UserService userService = Get.put(UserService());

  @override
  void onInit() {
    super.onInit();
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    debugPrint('HandoverBagController Initialized.');
    super.onInit();
  }

  @override
  void onClose() {
    scannerController.dispose();
    manualBarcodeController.dispose();
    debugPrint('HandoverBagController Disposed.');
    super.onClose();
  }

  void loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = user.value?.empCode.toString() ?? '';
        debugPrint('✅ [Controller] User data loaded: ${user.value?.name}');
      } else {
        debugPrint('❌ [Controller] Failed to load user data');
      }
    } catch (e) {
      debugPrint('❌ [Controller] Error loading user: $e');
    }
  }

  void toggleFlashlight() {
    flashlightEnabled.value = !flashlightEnabled.value;
    scannerController.toggleTorch();
    debugPrint('[Scanner] Flashlight: ${flashlightEnabled.value}');
  }

  void onBarcodeDetected(BarcodeCapture capture) async {
    if (!scannerActive.value || isLoading.value) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    scannerActive.value = false;
    scannedBarcode.value = barcode;
    debugPrint('[Scanner] Detected: $barcode');

    await fetchBagDetails(barcode);
  }

  void onManualBarcodeSubmit(String barcode) {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;
    debugPrint('Manual barcode: $trimmed');
    fetchBagDetails(trimmed);
  }

  Future<void> fetchBagDetails(String bagcode) async {
    isLoading.value = true;
    bagDetails.value = null;

    try {
      final response = await _apiService.getScanQRForAndTransactionID(
        bagcode: bagcode,
        processid: '14', // Bag must be accepted first
        userid: userId.value,
      );

      if (response.status == 'Success' && response.output?.isNotEmpty == true) {
        bagDetails.value = response.output!.first;

        LiquidSnack.success('Bag scanned successfully');
      } else {
        final msg = response.message.isNotEmpty ? response.message : 'Invalid or already handed over bag';
        LiquidSnack.warning(msg);
        Future.delayed(const Duration(seconds: 4), resetScanner);
      }
    } catch (e) {
      debugPrint('Error fetching bag: $e');
      LiquidSnack.error('Failed to load bag details');
      resetScanner();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handoverBag() async {
    if (bagDetails.value == null) {
      LiquidSnack.warning('Please scan a valid bag first');
      return;
    }

    isSubmitting.value = true;

    try {
      final location = await _locationService.getLocationStrings();

      final response = await _apiService.insertBagTransactionStatus(
        transactionID: bagDetails.value!.transactionID.toString(),
        processid: '15', // Handover to Inventory
        userid: userId.value,
        lats: location['latitude']!,
        longs: location['longitude']!,
        handOverUserid: userId.value,
      );

      if (response.status == 'Success') {
        LiquidSnack.success('Bag handed over to inventory!');

        await Future.delayed(const Duration(seconds: 1));
        resetScanner();
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      LiquidSnack.error('Handover failed: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  void resetScanner() {
    scannedBarcode.value = null;
    bagDetails.value = null;
    manualBarcodeController.clear();
    scannerActive.value = true;
    debugPrint('[State] Scanner reset');
  }
}

