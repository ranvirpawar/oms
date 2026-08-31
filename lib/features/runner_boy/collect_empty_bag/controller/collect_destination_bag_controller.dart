import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/constants/bag_process_ids.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../componenents/success_checked_animation_dialouge.dart';
import '../../../../routes/route_manager.dart';
import '../../../../services/snackbar_service.dart';
import '../../../../services/user_service.dart';
import '../../../auth/model/login_response_model.dart';
import '../service/bag_service.dart';







class CollectDestinationBagController extends GetxController {
  final UserService userService = Get.find();
  final BagService bagService = BagService();

  // ── Scanner ───────────────────────────────────────────────────────────────
  late MobileScannerController scannerController;
  final TextEditingController manualBarcodeController = TextEditingController();
  final FocusNode manualInputFocusNode = FocusNode();

  // ── Observables ───────────────────────────────────────────────────────────
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxString userId = ''.obs;

  final RxBool isSubmitting = false.obs;
  final RxBool scannerActive = true.obs;
  final RxBool flashlightEnabled = false.obs;
  final RxBool isManualInputActive = false.obs;

  // The only state needed — barcode string detected by scanner or typed manually
  final RxString scannedBarcode = ''.obs;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
      facing: CameraFacing.back,
    );
    loadUser();
    manualInputFocusNode.addListener(() {
      isManualInputActive.value = manualInputFocusNode.hasFocus;
    });
  }

  @override
  void onClose() {
    scannerController.dispose();
    manualBarcodeController.dispose();
    manualInputFocusNode.dispose();
    super.onClose();
  }

  // ── User ──────────────────────────────────────────────────────────────────
  Future<void> loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = userData.empCode.toString();
      }
    } catch (e) {
      debugPrint('User load error: $e');
    }
  }

  // ── Flashlight ────────────────────────────────────────────────────────────
  void toggleFlashlight() {
    flashlightEnabled.value = !flashlightEnabled.value;
    scannerController.toggleTorch();
  }

  // ── Barcode detected → just store it, show Collect button ─────────────────
  void onBarcodeDetected(BarcodeCapture capture) {
    if (!scannerActive.value) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    scannerActive.value = false;
    scannedBarcode.value = barcode;
    manualBarcodeController.text = barcode;
  }

  // ── Manual entry → store barcode, show Collect button ────────────────────
  void onManualSubmit() {
    final barcode = manualBarcodeController.text.trim();
    if (barcode.isEmpty) {
      SnackBarService.to.showMessage(message: 'Enter a valid barcode');
      return;
    }
    manualInputFocusNode.unfocus();
    scannerActive.value = false;
    scannedBarcode.value = barcode;
  }

  // ── Collect button pressed → call InsertStartQRCodeBagEvent ───────────────
  Future<void> collectDestinationBag() async {
    if (scannedBarcode.value.isEmpty) {
      SnackBarService.to.showMessage(message: 'Please scan a destination bag first');
      return;
    }

    final uid = int.tryParse(userId.value);
    if (uid == null) {
      SnackBarService.to.showMessage(message: 'User session invalid, please re-login');
      return;
    }

    isSubmitting.value = true;

    try {
      final response = await bagService.insertStartQRCodeBagEvent(
        bagCode: scannedBarcode.value,
        processId: BagProcessId.emptyBagCollected.processId,
        facilityCode: '0',
        userId: uid,
      );

      // Response: { "status": "Success", "Sessionid": 8, "S_bagid": 10, "message": "..." }
      final status = response['status']?.toString() ?? '';
      final message = response['message']?.toString() ?? '';

      if (status.toLowerCase() != 'success') {
        throw Exception(message.isNotEmpty ? message : 'Failed to collect destination bag');
      }

      debugPrint('✅ Collected | Sessionid: ${response['Sessionid']} | S_bagid: ${response['S_bagid']}');

      Get.dialog(
        ModernSuccessDialog(
          message: 'Destination Bag Collected Successfully',
          buttonText: 'OK',
          onPressed: () {
            Get.back();
            RouteManager.redirectToHomeDashboard();
          },
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      SnackBarService.to.showMessage(
        message: msg.isEmpty ? 'Collection failed' : msg,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  void resetScanner() {
    scannedBarcode.value = '';
    manualBarcodeController.clear();
    isManualInputActive.value = false;
    scannerActive.value = true;
  }
}