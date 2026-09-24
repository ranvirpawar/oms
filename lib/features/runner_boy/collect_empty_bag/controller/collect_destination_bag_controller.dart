import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/constants/bag_process_ids.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../componenents/success_checked_animation_dialouge.dart';
import '../../../../routes/route_manager.dart';
import '../../../../services/user_service.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../../../../utils/ui_designs/liquid_snackbar.dart';
import '../../../auth/model/login_response_model.dart';
import '../../../phlebotomist/bag_status_dashboard/service/bag_registration_service.dart';
import '../service/bag_service.dart';







class CollectDestinationBagController extends GetxController {
  final UserService userService = Get.find();
  final BagService bagService = BagService();
  final BagRegistrationService bagRegistrationService = BagRegistrationService();
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
      LiquidSnack.warning('Enter a valid barcode');
      return;
    }
    manualInputFocusNode.unfocus();
    scannerActive.value = false;
    scannedBarcode.value = barcode;
  }

  // ── Collect button pressed → call InsertStartQRCodeBagEvent ───────────────
  Future<void> collectDestinationBag() async {
    if (scannedBarcode.value.isEmpty) {
      LiquidSnack.warning('Please scan a destination bag first');
      return;
    }

    final uid = int.tryParse(userId.value);

    if (uid == null) {
      LiquidSnack.error('User session invalid, please re-login');
      return;
    }

    if (isSubmitting.value) return;

    try {
      isSubmitting.value = true;

      // ─────────────────────────────────────────────────────────────
      // 1. Check whether this bag is already assigned
      // ─────────────────────────────────────────────────────────────
      final alreadyAssigned = await _isBagAlreadyAssigned(
        scannedBarcode.value,
      );

      if (alreadyAssigned) {
        // Do NOT continue to InsertStartQRCodeBagEvent.
        // Error snackbar is already shown inside _isBagAlreadyAssigned().
        return;
      }

      // ─────────────────────────────────────────────────────────────
      // 2. Bag is available → allow collection
      // ─────────────────────────────────────────────────────────────
      final response = await bagService.insertStartQRCodeBagEvent(
        bagCode: scannedBarcode.value,
        processId: BagProcessId.emptyBagCollected.processId,
        facilityCode: '0',
        userId: uid,
      );

      final status = response['status']?.toString().trim().toLowerCase() ?? '';
      final message = response['message']?.toString() ?? '';

      if (status != 'success') {
        throw Exception(
          message.isNotEmpty
              ? message
              : 'Failed to collect destination bag',
        );
      }

      debugPrint(
        '✅ Collected | '
            'Sessionid: ${response['Sessionid']} | '
            'S_bagid: ${response['S_bagid']}',
      );

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

      LiquidSnack.error(
        msg.isEmpty ? 'Collection failed' : msg,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> _isBagAlreadyAssigned(String bagCode) async {
    final response = await bagRegistrationService.checkBagAlreadyAssigned(
      bagCode: bagCode,
    );

    final output = response['output'];

    if (output is List && output.isNotEmpty) {
      final data = output.first;

      if (data is Map) {
        final status = data['Status']?.toString().trim().toLowerCase();
        final message =
            data['Message']?.toString() ?? 'Unable to use this bag.';

        final retVal = int.tryParse(
          data['RetVal']?.toString() ?? '',
        );

        kPrint(
          '🎒 Bag assignment check | '
              'Bag: $bagCode | '
              'Status: $status | '
              'RetVal: $retVal | '
              'Message: $message',
        );

        if (status == 'failed') {
          LiquidSnack.error(message);
          return true;
        }

        return false;
      }
    }

    throw Exception('Invalid response from bag assignment check.');
  }
  // ── Reset ─────────────────────────────────────────────────────────────────
  void resetScanner() {
    scannedBarcode.value = '';
    manualBarcodeController.clear();
    isManualInputActive.value = false;
    scannerActive.value = true;
  }
}