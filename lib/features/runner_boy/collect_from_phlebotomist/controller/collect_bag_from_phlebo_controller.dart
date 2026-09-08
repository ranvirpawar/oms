// controllers/collect_bag_controller.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../services/user_service.dart';
import '../../../../utils/ui_designs/liquid_snackbar.dart';
import '../../../auth/model/login_response_model.dart';
import '../model/qr_bag_detail.dart';
import '../service/collect_bag_service.dart';
enum CollectBagState { idle, scanning, validating, validated, processing, success, error }

enum TransferStep {
  idle,
  scanningSource,
  sourceScanned,
  scanningDestination,
  destinationScanned,
  transferring,
  success
}

class CollectBagFromPhlebotomistController extends GetxController {
  final CollectBagService _service = CollectBagService();
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final userId = 0.obs;
  final UserService userService = Get.put(UserService());

  // PageView controller
  final pageController = PageController();
  final selectedTabIndex = 0.obs;

  // ── Collect Bag ───────────────────────────────────────────────────────────
  final collectBagState = CollectBagState.idle.obs;
  final scannedBagDetail = Rxn<QRBagCountDetail>();
  final collectBagcodeController = TextEditingController();
  final isManualInputActive = false.obs;
  final manualInputFocusNode = FocusNode();

  // ── Transfer Bag ──────────────────────────────────────────────────────────
  final transferStep = TransferStep.idle.obs;
  final sourceBag = Rxn<QRBagCountDetail>();
  final destinationBag = Rxn<QRBagCountDetail>();
  final sourceBagcodeController = TextEditingController();
  final destinationBagcodeController = TextEditingController();
  final isTransferring = false.obs;

  // ── Common ────────────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final flashEnabled = false.obs;
  final errorMessage = ''.obs;
  late MobileScannerController scannerController;

  @override
  void onInit() {
    super.onInit();
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    manualInputFocusNode.addListener(() {
      isManualInputActive.value = manualInputFocusNode.hasFocus;
    });
    _loadUser();
  }

  @override
  void onClose() {
    pageController.dispose();
    collectBagcodeController.dispose();
    sourceBagcodeController.dispose();
    destinationBagcodeController.dispose();
    scannerController.dispose();
    manualInputFocusNode.dispose();
    super.onClose();
  }

  Future<void> _loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = user.value?.empCode ?? 0;
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  // ── Tab Switching ─────────────────────────────────────────────────────────

  void switchTab(int index) {
    HapticFeedback.lightImpact();
    selectedTabIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    reset();
  }

  void toggleFlash() {
    scannerController.toggleTorch();
    flashEnabled.value = !flashEnabled.value;
  }

  // ── Barcode Scan Handler ──────────────────────────────────────────────────

  void handleBarcodeScan(String barcode) {
    if (selectedTabIndex.value == 0) {
      // Collect flow — type 1
      collectBagcodeController.text = barcode;
      _validateAndScanBag(barcode, isCollect: true);
    } else {
      // Transfer flow
      if (transferStep.value == TransferStep.scanningSource) {
        sourceBagcodeController.text = barcode;
        _validateAndScanBag(barcode, isSource: true);
      } else if (transferStep.value == TransferStep.scanningDestination) {
        destinationBagcodeController.text = barcode;
        _validateAndScanBag(barcode, isSource: false);
      }
    }
  }

  // ── Core: GETQRBagCount ───────────────────────────────────────────────────
  // type 1 = source / collect bag
  // type 2 = destination bag

  Future<QRBagCountDetail?> _scanAndValidateBag(String bagcode, {required int type}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _service.getQRBagCount(bagcode: bagcode, type: type);
      final output = response['output'];

      if (response['status'] == 'Success' &&
          output != null &&
          (output as List).isNotEmpty) {
        return QRBagCountDetail.fromJson(output.first);
      }

      throw Exception(response['message'] ?? 'Bag not found');
    } catch (e) {
      errorMessage.value = e.toString();
      _showErrorSnackbar(e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Collect Flow ──────────────────────────────────────────────────────────

  void onManualCollectSubmit() {
    final code = collectBagcodeController.text.trim();
    if (code.isEmpty) {
      _showErrorSnackbar('Please enter a bag code');
      return;
    }
    manualInputFocusNode.unfocus();
    isManualInputActive.value = false;
    _validateAndScanBag(code, isCollect: true);
  }

  Future<void> _validateAndScanBag(
      String barcode, {
        bool isCollect = false,
        bool isSource = false,
      }) async {
    // type 1 → collect or source bag
    // type 2 → destination bag
    final int type = (!isCollect && !isSource) ? 2 : 1;

    final detail = await _scanAndValidateBag(barcode, type: type);
    if (detail == null) {
      if (isCollect) collectBagState.value = CollectBagState.error;
      if (!isSource) transferStep.value = TransferStep.sourceScanned;
      return;
    }

    if (isCollect) {
      // Collect validation: bag must be closed
      if (!detail.isBagClosed) {
        _showErrorSnackbar('Bag is still open. Only closed bags can be collected.');
        collectBagState.value = CollectBagState.error;
        Future.delayed(const Duration(seconds: 2), () => resetCollect());
        return;
      }
      scannedBagDetail.value = detail;
      collectBagState.value = CollectBagState.validated;
      _showSuccessSnackbar('Bag validated — ready to collect');
    } else if (isSource) {
      // Source bag: must have tubes
      if ((detail.tubecount ?? 0) <= 0) {
        _showErrorSnackbar('Source bag has no tubes to transfer.');
        transferStep.value = TransferStep.idle;
        sourceBagcodeController.clear();
        return;
      }
      sourceBag.value = detail;
      transferStep.value = TransferStep.sourceScanned;
      _showSuccessSnackbar('Source bag validated');
    } else {
      // Destination bag: must not be closed & must differ from source
      if (sourceBag.value != null && detail.bagId == sourceBag.value!.bagId) {
        _showErrorSnackbar('Source and destination bags cannot be the same.');
        transferStep.value = TransferStep.sourceScanned;
        destinationBagcodeController.clear();
        return;
      }
      if (detail.isBagClosed) {
        _showErrorSnackbar('Destination bag is closed. Please select an open bag.');
        transferStep.value = TransferStep.sourceScanned;
        destinationBagcodeController.clear();
        return;
      }
      destinationBag.value = detail;
      transferStep.value = TransferStep.destinationScanned;
      _showSuccessSnackbar('Destination bag validated');
    }
  }

  Future<void> collectBag() async {
    if (scannedBagDetail.value == null) return;
    collectBagState.value = CollectBagState.processing;

    try {
      final response = await _service.collectBag(
        sessionId: scannedBagDetail.value!.sessionID,
        userId: userId.value,
      );

      if (response['status'] == 'Success') {
        collectBagState.value = CollectBagState.success;
        _showSuccessSnackbar('Bag collected successfully!');
      } else {
        throw Exception(response['message'] ?? 'Failed to collect bag');
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
      collectBagState.value = CollectBagState.validated;
    }
  }

  void resetCollect() {
    collectBagcodeController.clear();
    scannedBagDetail.value = null;
    collectBagState.value = CollectBagState.idle;
    errorMessage.value = '';
    isLoading.value = false;
    isManualInputActive.value = false;
    manualInputFocusNode.unfocus();
  }

  // ── Transfer Flow ─────────────────────────────────────────────────────────

  void startSourceScan() => transferStep.value = TransferStep.scanningSource;

  void startDestinationScan() => transferStep.value = TransferStep.scanningDestination;

  void stopScanning() {
    if (transferStep.value == TransferStep.scanningSource) {
      transferStep.value = TransferStep.idle;
    } else if (transferStep.value == TransferStep.scanningDestination) {
      transferStep.value = TransferStep.sourceScanned;
    }
  }

  Future<void> validateSourceManual() async {
    final code = sourceBagcodeController.text.trim();
    if (code.isEmpty) {
      _showErrorSnackbar('Please scan or enter source bag code');
      return;
    }
    await _validateAndScanBag(code, isSource: true);
  }

  Future<void> validateDestinationManual() async {
    final code = destinationBagcodeController.text.trim();
    if (code.isEmpty) {
      _showErrorSnackbar('Please scan or enter destination bag code');
      return;
    }
    await _validateAndScanBag(code, isSource: false);
  }

  Future<void> executeTransfer() async {
    if (sourceBag.value == null || destinationBag.value == null) return;

    transferStep.value = TransferStep.transferring;
    isTransferring.value = true;

    try {
      final response = await _service.transferSampleToQRBag(
        fromSession: sourceBag.value!.sessionID,
        toSession: destinationBag.value!.sessionID,
        fromBagId: sourceBag.value!.bagId,
        toBagId: destinationBag.value!.bagId,
        userId: userId.value,
        tubecount: sourceBag.value!.tubecount ?? 0,
      );

      if (response['status'] == 'Success') {
        transferStep.value = TransferStep.success;
        _showSuccessSnackbar('Transfer completed successfully!');
      } else {
        throw Exception(response['message'] ?? 'Transfer failed');
      }
    } catch (e) {
      _showErrorSnackbar('Transfer failed: ${e.toString()}');
      transferStep.value = TransferStep.destinationScanned;
    } finally {
      isTransferring.value = false;
    }
  }

  void clearSourceBag() {
    sourceBag.value = null;
    sourceBagcodeController.clear();
    transferStep.value = TransferStep.idle;
    destinationBag.value = null;
    destinationBagcodeController.clear();
  }

  void clearDestinationBag() {
    destinationBag.value = null;
    destinationBagcodeController.clear();
    transferStep.value = TransferStep.sourceScanned;
  }

  // ── Reset All ─────────────────────────────────────────────────────────────

  void reset() {
    resetCollect();
    sourceBag.value = null;
    destinationBag.value = null;
    sourceBagcodeController.clear();
    destinationBagcodeController.clear();
    transferStep.value = TransferStep.idle;
    isTransferring.value = false;
    flashEnabled.value = false;
    errorMessage.value = '';
  }

  // ── Snackbars ─────────────────────────────────────────────────────────────

  void _showSuccessSnackbar(String message) {
    LiquidSnack.success(message, title: 'Success');
  }

  void _showErrorSnackbar(String message) {
    LiquidSnack.error(message, title: 'Error');
  }
}