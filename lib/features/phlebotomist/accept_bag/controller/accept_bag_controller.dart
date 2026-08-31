// accept_bag_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../services/user_service.dart';
import '../../../auth/model/login_response_model.dart';
import '../model/accept_bag_model.dart';
import '../service/accept_bag_service.dart';

// accept_bag_controller.dart


import '../view/widget/scanner_bottomsheet.dart';
import 'package:permission_handler/permission_handler.dart';



class AcceptBagController extends GetxController {
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final Rx<String> userId = ''.obs;
  final UserService userService = Get.put(UserService());
  final AcceptBagService acceptBagService = AcceptBagService();

  // Scanner
  final Rx<MobileScannerController?> scannerController = Rx<MobileScannerController?>(null);


  // State
  final Rx<AcceptBagState> acceptBagState = AcceptBagState.idle.obs;
  final RxBool isLoading = false.obs;
  final RxBool isScanning = false.obs;
  final RxString errorMessage = ''.obs;

  // Data
  final RxList<AssignedBag> assignedBagsList = <AssignedBag>[].obs;
  final Rx<AssignedBag?> selectedBag = Rx<AssignedBag?>(null);
  final Rx<BagQRTransaction?> scannedTransaction = Rx<BagQRTransaction?>(null);
  final RxString scannedBarcode = ''.obs;
  final RxBool isTorchOn = false.obs;

  @override
  void onInit() {
    loadUser();
    super.onInit();
  }

  @override
  void onClose() {
    debugPrint('Cleaning up AcceptBagController');
    _disposeScannerSafely();
    super.onClose();
  }

  void _disposeScannerSafely() {
    try {
      scannerController.value?.dispose();
      scannerController.value = null;
      debugPrint('Scanner disposed');
    } catch (e) {
      debugPrint('Error disposing scanner: $e');
    }
  }

  void loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = user.value?.empCode.toString() ?? '';
        debugPrint('User loaded: ${user.value?.name}');
        fetchAssignedBags();
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  Future<void> fetchAssignedBags() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (userId.value.isEmpty) throw Exception('User ID not found');

      final response = await acceptBagService.getAssignedBagsList(
        phleboUserId: int.parse(userId.value),
        processId: 0,
      );

      if (response.isSuccess && response.output != null) {
        assignedBagsList.value = response.output!;
        debugPrint('Loaded ${assignedBagsList.length} bags');
      } else {
        assignedBagsList.value = [];
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      SnackBarService.to.showMessage(
        message: errorMessage.value,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectBagAndScan(AssignedBag bag) {
    // Close any open scanner
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    selectedBag.value = bag;
    debugPrint('Selected: ${bag.bagcode}');

    Future.delayed(const Duration(milliseconds: 300), startScanning);
  }
  Future<void> startScanning() async {
    if (selectedBag.value == null) return;

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      SnackBarService.to.showMessage(
        message: 'Camera permission required',
        backgroundColor: Colors.red.shade100,
      );
      return;
    }

    // 1. Clean previous instance
    _disposeScannerSafely();

    isScanning.value = true;
    acceptBagState.value = AcceptBagState.scanning;

    // 2. Show sheet **once**
    Get.bottomSheet(
      ScannerBottomSheet(controller: this),
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    // 3. Small delay so the sheet is rendered before we init the camera
    await Future.delayed(const Duration(milliseconds: 350));

    try {
      scannerController.value = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: isTorchOn.value,
      );
      debugPrint('Scanner started');
    } catch (e) {
      debugPrint('Camera init failed: $e');
      stopScanning();
      SnackBarService.to.showMessage(
        message: 'Camera not available',
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  /// Close the sheet **and** clean everything.
  void stopScanning({bool keepBag = false}) {
    debugPrint('stopScanning – keepBag: $keepBag');
    isScanning.value = false;
    isTorchOn.value = false;
    acceptBagState.value = AcceptBagState.idle;

    scannerController.value?.stop();

    if (Get.isBottomSheetOpen == true) Get.back();

    Future.delayed(const Duration(milliseconds: 250), () {
      _disposeScannerSafely();
      scannedBarcode.value = '';
      scannedTransaction.value = null;
      if (!keepBag) selectedBag.value = null;
    });
  }

  /// Called from the UI when the user taps **Retry**.
  void retryScanning() {
    scannedBarcode.value = '';
    acceptBagState.value = AcceptBagState.scanning;
    _restartScanner();
  }

  void _restartScanner() {
    try {
      scannerController.value = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: isTorchOn.value,
      );
      debugPrint('Scanner restarted');
    } catch (e) {
      debugPrint('Failed to restart scanner: $e');
      stopScanning();
    }
  }

  // -----------------------------------------------------------------
  //  SCAN HANDLER
  // -----------------------------------------------------------------
  void handleBarcodeScan(String barcode) async {
    if (acceptBagState.value == AcceptBagState.processing ||
        scannedBarcode.value == barcode) {
      return;
    }

    scannedBarcode.value = barcode;
    scannerController.value?.stop();               // prevent double-trigger
    debugPrint('Scanned: $barcode');

    if (barcode != selectedBag.value!.bagcode) {
      _showWrongBagError(barcode);
      return;
    }

    await verifyBagQR(barcode);
  }

  void _showWrongBagError(String scanned) {
    acceptBagState.value = AcceptBagState.error;
    errorMessage.value = 'Wrong bag scanned';

    SnackBarService.to.showMessage(
      message:
      'Wrong bag!\nExpected: ${selectedBag.value!.bagcode}\nScanned: $scanned',
      backgroundColor: Colors.red.shade100,
    );

    // Auto-retry after a short pause – user can also tap the button
    Future.delayed(const Duration(seconds: 2), () {
      if (isScanning.value && Get.isBottomSheetOpen == true) retryScanning();
    });
  }

  // -----------------------------------------------------------------
  //  VERIFY → ACCEPT
  // -----------------------------------------------------------------
  Future<void> verifyBagQR(String barcode) async {
    try {
      acceptBagState.value = AcceptBagState.processing;

      final response = await acceptBagService.scanBagQR(
        bagcode: barcode,
        processId: 4,
        userId: int.parse(userId.value),
      );

      if (!response.isSuccess ||
          response.output == null ||
          response.output!.isEmpty) {
        throw Exception(
            response.message.isNotEmpty ? response.message : 'Invalid QR code');
      }

      final matching = response.output!.firstWhere(
            (t) => t.transactionId == selectedBag.value!.transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );

      scannedTransaction.value = matching;
      await performAcceptBag(matching.transactionId);
    } catch (e) {
      _handleScanError(e);
    }
  }

  Future<void> performAcceptBag(int transactionId) async {
    try {
      final response = await acceptBagService.acceptBag(
        transactionId: transactionId,
        processId: 12,
        userId: int.parse(userId.value),
        handOverUserId: int.parse(userId.value),
      );

      if (!response.isSuccess) {
        throw Exception(
            response.message.isNotEmpty ? response.message : 'Failed to accept');
      }

      // SUCCESS
      acceptBagState.value = AcceptBagState.success;
      SnackBarService.to.showMessage(
        message: 'Bag ${selectedBag.value!.bagcode} accepted!',
        backgroundColor: Colors.green.shade100,
      );

      await fetchAssignedBags();

      // Auto-close after a moment
      Future.delayed(const Duration(seconds: 2), () => stopScanning());
    } catch (e) {
      _handleScanError(e);
    }
  }

  void _handleScanError(dynamic e) {
    acceptBagState.value = AcceptBagState.error;
    errorMessage.value = e.toString().replaceAll('Exception: ', '');

    SnackBarService.to.showMessage(
      message: errorMessage.value,
      backgroundColor: Colors.red.shade100,
    );

    // Auto-retry after 2 s (user can also tap Retry)
    Future.delayed(const Duration(seconds: 2), () {
      if (isScanning.value && Get.isBottomSheetOpen == true) retryScanning();
    });
  }

  // -----------------------------------------------------------------
  //  FLASH
  // -----------------------------------------------------------------
  void toggleFlash() async {
    try {
      await scannerController.value?.toggleTorch();
      isTorchOn.value = !isTorchOn.value;
    } catch (e) {
      debugPrint('Torch error: $e');
    }
  }
  /*Future<void> startScanning() async {
    if (selectedBag.value == null) return;

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      SnackBarService.to.showMessage(
        message: 'Camera permission required',
        backgroundColor: Colors.red,
      );
      return;
    }

    _disposeScannerSafely();

    isScanning.value = true;
    acceptBagState.value = AcceptBagState.scanning;

    Get.bottomSheet(
      ScannerBottomSheet(controller: this),
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      scannerController.value = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      debugPrint('Scanner started');
    } catch (e) {
      debugPrint('Camera init failed: $e');
      stopScanning();
      SnackBarService.to.showMessage(
        message: 'Camera not available',
        backgroundColor: Colors.red,
      );
    }
  }

  void stopScanning({bool allowRestart = false}) {
    debugPrint('Stopping scanner...');
    isScanning.value = false;
    isTorchOn.value = false;
    acceptBagState.value = AcceptBagState.idle;

    scannerController.value?.stop();

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      _disposeScannerSafely();
      scannedBarcode.value = '';
      scannedTransaction.value = null;
      if (!allowRestart) {
        selectedBag.value = null;
      }
    });
  }

  void handleBarcodeScan(String barcode) async {
    // Prevent duplicate processing
    if (acceptBagState.value == AcceptBagState.processing ||
        scannedBarcode.value == barcode) {
      return;
    }

    scannedBarcode.value = barcode;
    debugPrint('Scanned: $barcode');

    // Stop scanner immediately to prevent multiple triggers
    scannerController.value?.stop();

    // Check if scanned bag matches selected
    if (barcode != selectedBag.value!.bagcode) {
      _showWrongBagError(barcode);
      return;
    }

    // Proceed to verify
    await verifyBagQR(barcode);
  }

  void _showWrongBagError(String scannedCode) {
    acceptBagState.value = AcceptBagState.error;
    errorMessage.value = 'Wrong bag scanned';

    SnackBarService.to.showMessage(
      message: 'Wrong bag!\nExpected: ${selectedBag.value!.bagcode}\nScanned: $scannedCode',
      backgroundColor: Colors.red,
    );

    // Allow retry: restart scanner after delay
    Future.delayed(const Duration(seconds: 0), () {
      if (isScanning.value && Get.isBottomSheetOpen == true) {
        _restartScanner();
      }
    });
  }

  Future<void> verifyBagQR(String barcode) async {
    try {
      acceptBagState.value = AcceptBagState.processing;

      final response = await acceptBagService.scanBagQR(
        bagcode: barcode,
        processId: 4,
        userId: int.parse(userId.value),
      );

      if (!response.isSuccess || response.output == null || response.output!.isEmpty) {
        throw Exception(response.message.isNotEmpty ? response.message : 'Invalid QR code');
      }

      final matching = response.output!.firstWhere(
            (t) => t.transactionId == selectedBag.value!.transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );

      scannedTransaction.value = matching;
      await performAcceptBag(matching.transactionId);
    } catch (e) {
      _handleScanError(e);
    }
  }

  void _handleScanError(dynamic e) {
    acceptBagState.value = AcceptBagState.error;
    errorMessage.value = e.toString().replaceAll('Exception: ', '');

    SnackBarService.to.showMessage(
      message: errorMessage.value,
      backgroundColor: Colors.red,
    );

    // Restart scanner after error
    Future.delayed(const Duration(seconds: 2), () {
      if (isScanning.value && Get.isBottomSheetOpen == true) {
        _restartScanner();
      }
    });
  }

  void _restartScanner() {
    scannedBarcode.value = '';
    acceptBagState.value = AcceptBagState.scanning;

    // Re-init scanner
    try {
      scannerController.value = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: isTorchOn.value,
      );
      debugPrint('Scanner restarted');
    } catch (e) {
      debugPrint('Failed to restart scanner: $e');
      stopScanning();
    }
  }



  Future<void> performAcceptBag(int transactionId) async {
    try {
      final response = await acceptBagService.acceptBag(
        transactionId: transactionId,
        processId: 12,
        userId: int.parse(userId.value),
        handOverUserId: int.parse(userId.value),
      );

      if (!response.isSuccess) {
        throw Exception(response.message.isNotEmpty ? response.message : 'Failed to accept');
      }

      // SUCCESS
      acceptBagState.value = AcceptBagState.success;
      SnackBarService.to.showMessage(
        message: 'Bag ${selectedBag.value!.bagcode} accepted!',
        backgroundColor: Colors.green,
      );

      await fetchAssignedBags();

      // Auto-close scanner
      Future.delayed(const Duration(seconds: 1), stopScanning);

      // Reset
      selectedBag.value = null;
      scannedBarcode.value = '';
      scannedTransaction.value = null;

    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(dynamic e) {
    acceptBagState.value = AcceptBagState.error;
    errorMessage.value = e.toString().replaceAll('Exception: ', '');

    SnackBarService.to.showMessage(
      message: errorMessage.value,
      backgroundColor: Colors.red,
    );

    Future.delayed(const Duration(seconds: 2), () {
      stopScanning();
      acceptBagState.value = AcceptBagState.idle;
    });
  }

  void toggleFlash() async {
    try {
      await scannerController?.value!.toggleTorch();
      isTorchOn.value = !isTorchOn.value;
    } catch (e) {
      debugPrint('Torch error: $e');
    }
  }*/

  String getStatusText(int status) {
    return status == 4 ? 'Assigned' : status == 12 ? 'Accepted' : 'Status $status';
  }

  Color getStatusColor(int status) {
    return status == 4 ? Colors.orange : status == 12 ? Colors.green : Colors.grey;
  }
}
/*class AcceptBagController extends GetxController {
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final Rx<String> userId = ''.obs;
  final UserService userService = Get.put(UserService());
  final AcceptBagService acceptBagService = AcceptBagService();

  // Scanner controller - will be recreated for each scan
  MobileScannerController? scannerController;

  // State management
  final Rx<AcceptBagState> acceptBagState = AcceptBagState.idle.obs;
  final RxBool isLoading = false.obs;
  final RxBool isScanning = false.obs;
  final RxBool isScannerReady = false.obs;
  final RxString errorMessage = ''.obs;

  // Bags data
  final RxList<AssignedBag> assignedBagsList = <AssignedBag>[].obs;
  final Rx<AssignedBag?> selectedBag = Rx<AssignedBag?>(null);
  final Rx<BagQRTransaction?> scannedTransaction = Rx<BagQRTransaction?>(null);

  // Filtered list for search
  final RxList<AssignedBag> filteredBagsList = <AssignedBag>[].obs;
  final RxString searchQuery = ''.obs;

  // Scanner state
  final RxString scannedBarcode = ''.obs;
  final RxBool isTorchOn = false.obs;

  @override
  void onInit() {
    loadUser();
    super.onInit();
  }

  @override
  void onClose() {
    debugPrint('🧹 Cleaning up AcceptBagController');
    _disposeScannerSafely();
    super.onClose();
  }

  void _disposeScannerSafely() {
    try {
      scannerController?.dispose();
      scannerController = null;
      debugPrint('✅ Scanner disposed');
    } catch (e) {
      debugPrint('⚠️ Error disposing scanner: $e');
    }
  }

  void loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = user.value?.empCode.toString() ?? '';
        debugPrint('✅ User data loaded: ${user.value?.name}');
        fetchAssignedBags();
      } else {
        debugPrint('❌ Failed to load user data');
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  // Fetch assigned bags list
  Future<void> fetchAssignedBags() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (userId.value.isEmpty) {
        throw Exception('User ID not found');
      }

      final response = await acceptBagService.getAssignedBagsList(
        phleboUserId: int.parse(userId.value),
        processId: 0,
      );

      if (response.isSuccess && response.output != null) {
        assignedBagsList.value = response.output!;
        filteredBagsList.value = response.output!;
        debugPrint('✅ Loaded ${assignedBagsList.length} assigned bags');
      } else {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to load assigned bags');
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      SnackBarService.to.showMessage(
        message: errorMessage.value,
        backgroundColor: Colors.red.shade100,
      );
      debugPrint('❌ Error fetching assigned bags: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Select a bag and open scanner
  void selectBagAndScan(AssignedBag bag) {
    selectedBag.value = bag;
    debugPrint('📦 Selected bag: ${bag.bagcode}');
    startScanning();
  }

  // Start scanning - using bottom sheet
  Future<void> startScanning() async {
    if (selectedBag.value == null) {
      SnackBarService.to.showMessage(message: 'Please select a bag first');
      return;
    }

    // Dispose old scanner if exists
    _disposeScannerSafely();

    isScanning.value = true;
    isTorchOn.value = false;
    acceptBagState.value = AcceptBagState.scanning;

    Get.bottomSheet(
      ScannerBottomSheet(controller: this),
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    // Initialize immediately
    try {
      scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      debugPrint('Scanner ready for multiple scans');
    } catch (e) {
      debugPrint('Error initializing scanner: $e');
      stopScanning();
      SnackBarService.to.showMessage(
        message: 'Camera failed to start',
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  // Stop scanning
  void stopScanning() {
    debugPrint('🛑 Stopping scanner...');
    isScanning.value = false;
    isTorchOn.value = false;
    isScannerReady.value = false;
    try {
      scannerController?.stop();
      debugPrint('✅ Scanner stopped');
    } catch (e) {
      debugPrint('⚠️ Error stopping scanner: $e');
    }

    if (acceptBagState.value == AcceptBagState.scanning) {
      acceptBagState.value = AcceptBagState.idle;
    }

    // Close bottom sheet if open
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }

    // Dispose scanner after stopping
    Future.delayed(const Duration(milliseconds: 300), () {
      _disposeScannerSafely();
    });
  }

  // Handle barcode scan
  void handleBarcodeScan(String barcode) {
    if (acceptBagState.value == AcceptBagState.processing) {
      debugPrint('Already processing, scan ignored');
      return;
    }

    if (selectedBag.value == null) {
      debugPrint('No bag selected');
      return;
    }

    // Prevent duplicate scans
    if (scannedBarcode.value == barcode) {
      debugPrint('Duplicate scan ignored');
      return;
    }

    scannedBarcode.value = barcode;

    debugPrint('Scanned: $barcode');

    // DO NOT call stopScanning() here
    // Just verify and accept

    if (barcode != selectedBag.value!.bagcode) {
      SnackBarService.to.showMessage(
        message:
        'Wrong bag!\nExpected: ${selectedBag.value!.bagcode}\nScanned: $barcode',
        backgroundColor: Colors.red,
      );
      // Reset for next scan
      scannedBarcode.value = '';
      Get.back();
      return;
    }

    // Proceed to verify and accept
    verifyBagQR(barcode);
  }

  // Verify bag QR and get transaction details
  Future<void> verifyBagQR(String barcode) async {
    try {
      acceptBagState.value = AcceptBagState.processing;
      errorMessage.value = '';

      debugPrint('🔍 Verifying QR for bag: $barcode');

      final response = await acceptBagService.scanBagQR(
        bagcode: barcode,
        processId: 4,
        userId: int.parse(userId.value),
      );

      if (!response.isSuccess ||
          response.output == null ||
          response.output!.isEmpty) {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Invalid QR code or bag not found');
      }

      // Find matching transaction from scanned results
      final matchingTransaction = response.output!.firstWhere(
            (transaction) =>
        transaction.transactionId == selectedBag.value!.transactionId,
        orElse: () => response.output!.first,
      );

      scannedTransaction.value = matchingTransaction;

      // Proceed to accept the bag
      await performAcceptBag(matchingTransaction.transactionId);
    } catch (e) {
      acceptBagState.value = AcceptBagState.error;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');

      SnackBarService.to.showMessage(
        message: errorMessage.value,
        backgroundColor: Colors.red.shade100,
      );

      debugPrint('❌ Error verifying bag QR: $e');
      acceptBagState.value = AcceptBagState.idle;
    }
  }

  // Perform accept bag operation
  Future<void> performAcceptBag(int transactionId) async {
    try {
      debugPrint('Accepting bag with transaction ID: $transactionId');

      final response = await acceptBagService.acceptBag(
        transactionId: transactionId,
        processId: 12,
        userId: int.parse(userId.value),
        handOverUserId: int.parse(userId.value),
      );

      if (!response.isSuccess) {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to accept bag');
      }

      // SUCCESS!
      acceptBagState.value = AcceptBagState.success;

      SnackBarService.to.showMessage(
        message: 'Bag ${selectedBag.value!.bagcode} accepted!',
        backgroundColor: Colors.green.shade100,
      );

      // Refresh list
      await fetchAssignedBags();

      // RESET for next scan (but keep scanner open)
      selectedBag.value = null;
      scannedBarcode.value = '';
      scannedTransaction.value = null;

      // Auto-reset success state after 1.5s
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (acceptBagState.value == AcceptBagState.success) {
          acceptBagState.value = AcceptBagState.scanning; // back to scanning
        }
      });

    } catch (e) {
      acceptBagState.value = AcceptBagState.error;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');

      SnackBarService.to.showMessage(
        message: errorMessage.value,
        backgroundColor: Colors.red.shade100,
      );

      debugPrint('Error accepting bag: $e');

      // Allow retry
      scannedBarcode.value = '';
      acceptBagState.value = AcceptBagState.scanning;
    }
  }

  // Search bags
  void searchBags(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredBagsList.value = assignedBagsList;
    } else {
      filteredBagsList.value = assignedBagsList.where((bag) {
        return bag.bagcode.toLowerCase().contains(query.toLowerCase()) ||
            bag.phleboName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  // Clear search
  void clearSearch() {
    searchQuery.value = '';
    filteredBagsList.value = assignedBagsList;
  }

  // Reset controller (for manual reset if needed)
  void reset() {
    selectedBag.value = null;
    scannedTransaction.value = null;
    scannedBarcode.value = '';
    errorMessage.value = '';
    acceptBagState.value = AcceptBagState.idle;
    searchQuery.value = '';
    filteredBagsList.value = assignedBagsList;
  }

  // Toggle flashlight
  void toggleFlash() async {
    try {
      await scannerController?.toggleTorch();
      isTorchOn.value = !isTorchOn.value;
      debugPrint('💡 Torch toggled: ${isTorchOn.value}');
    } catch (e) {
      debugPrint('⚠️ Error toggling torch: $e');
    }
  }

  // Get status text for transition status
  String getStatusText(int status) {
    switch (status) {
      case 4:
        return 'Assigned';
      case 12:
        return 'Accepted';
      default:
        return 'Status $status';
    }
  }

  // Get status color
  Color getStatusColor(int status) {
    switch (status) {
      case 4:
        return Colors.orange;
      case 12:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}*/

/*class AcceptBagController extends GetxController {
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final Rx<String> userId = ''.obs;
  final UserService userService = Get.put(UserService());
  final AcceptBagService acceptBagService = AcceptBagService();

  // Scanner controller - will be recreated for each scan
  MobileScannerController? scannerController;

  // State management
  final Rx<AcceptBagState> acceptBagState = AcceptBagState.idle.obs;
  final RxBool isLoading = false.obs;
  final RxBool isScanning = false.obs;
  final RxString errorMessage = ''.obs;

  // Bags data
  final RxList<AssignedBag> assignedBagsList = <AssignedBag>[].obs;
  final Rx<AssignedBag?> selectedBag = Rx<AssignedBag?>(null);
  final Rx<BagQRTransaction?> scannedTransaction = Rx<BagQRTransaction?>(null);

  // Filtered list for search
  final RxList<AssignedBag> filteredBagsList = <AssignedBag>[].obs;
  final RxString searchQuery = ''.obs;

  // Scanner state
  final RxString scannedBarcode = ''.obs;
  final RxBool showScannerOverlay = false.obs;

  @override
  void onInit() {
    loadUser();
    super.onInit();
  }

  @override
  void onClose() {
    debugPrint('🧹 Cleaning up AcceptBagController');
    _disposeScannerSafely();
    super.onClose();
  }

  void _disposeScannerSafely() {
    try {
      scannerController?.dispose();
      scannerController = null;
      debugPrint('✅ Scanner disposed');
    } catch (e) {
      debugPrint('⚠️ Error disposing scanner: $e');
    }
  }

  void loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = user.value?.empCode.toString() ?? '';
        debugPrint('✅ User data loaded: ${user.value?.name}');
        fetchAssignedBags();
      } else {
        debugPrint('❌ Failed to load user data');
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  // Fetch assigned bags list
  Future<void> fetchAssignedBags() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (userId.value.isEmpty) {
        throw Exception('User ID not found');
      }

      final response = await acceptBagService.getAssignedBagsList(
        phleboUserId: int.parse(userId.value),
        processId: 0,
      );

      if (response.isSuccess && response.output != null) {
        assignedBagsList.value = response.output!;
        filteredBagsList.value = response.output!;
        debugPrint('✅ Loaded ${assignedBagsList.length} assigned bags');
      } else {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to load assigned bags');
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      SnackBarService.to.showMessage(
        message: errorMessage.value,
        backgroundColor: Colors.red.shade100,
      );
      debugPrint('❌ Error fetching assigned bags: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Select a bag and open scanner
  void selectBagAndScan(AssignedBag bag) {
    selectedBag.value = bag;
    debugPrint('📦 Selected bag: ${bag.bagcode}');
    startScanning();
  }

  // Start scanning
  Future<void> startScanning() async {
    if (selectedBag.value == null) {
      SnackBarService.to.showMessage(
        message: 'Please select a bag first',
      );
      return;
    }

    // Dispose previous scanner if exists
    _disposeScannerSafely();

    // Create new scanner controller
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    isScanning.value = true;
    acceptBagState.value = AcceptBagState.scanning;

    debugPrint('📸 Starting scanner...');

    // Small delay to ensure controller is ready
    await Future.delayed(const Duration(milliseconds: 100));

    // Show scanner overlay as a dialog
    Get.dialog(
      WillPopScope(
        onWillPop: () async {
          stopScanning();
          return true;
        },
        child: ScannerOverlay(controller: this),
      ),
      barrierDismissible: false,
    );
  }

  // Stop scanning
  void stopScanning() {
    debugPrint('🛑 Stopping scanner...');
    isScanning.value = false;

    try {
      scannerController?.stop();
      debugPrint('✅ Scanner stopped');
    } catch (e) {
      debugPrint('⚠️ Error stopping scanner: $e');
    }

    if (acceptBagState.value == AcceptBagState.scanning) {
      acceptBagState.value = AcceptBagState.idle;
    }

    // Close scanner dialog if open
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    // Dispose scanner after stopping
    Future.delayed(const Duration(milliseconds: 300), () {
      _disposeScannerSafely();
    });
  }

  // Handle barcode scan
  void handleBarcodeScan(String barcode) {
    if (acceptBagState.value == AcceptBagState.processing) {
      debugPrint('⚠️ Already processing, scan ignored');
      return;
    }

    if (selectedBag.value == null) {
      debugPrint('⚠️ No bag selected');
      return;
    }

    // Prevent multiple scans
    if (scannedBarcode.value == barcode &&
        acceptBagState.value != AcceptBagState.idle) {
      debugPrint('⚠️ Duplicate scan ignored');
      return;
    }

    scannedBarcode.value = barcode;

    debugPrint('📷 Scanned: $barcode');
    stopScanning();

    // Verify if scanned barcode matches selected bag
    if (barcode != selectedBag.value!.bagcode) {
      SnackBarService.to.showMessage(
        message:
        'Scanned barcode does not match selected bag.\nExpected: ${selectedBag.value!.bagcode}\nScanned: $barcode',
      );
      acceptBagState.value = AcceptBagState.idle;
      return;
    }

    // Proceed with QR scan verification
    verifyBagQR(barcode);
  }

  // Verify bag QR and get transaction details
  Future<void> verifyBagQR(String barcode) async {
    try {
      acceptBagState.value = AcceptBagState.processing;
      errorMessage.value = '';

      debugPrint('🔍 Verifying QR for bag: $barcode');

      final response = await acceptBagService.scanBagQR(
        bagcode: barcode,
        processId: 4,
        userId: int.parse(userId.value),
      );

      if (!response.isSuccess ||
          response.output == null ||
          response.output!.isEmpty) {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Invalid QR code or bag not found');
      }

      // Find matching transaction from scanned results
      final matchingTransaction = response.output!.firstWhere(
            (transaction) =>
        transaction.transactionId == selectedBag.value!.transactionId,
        orElse: () => response.output!.first,
      );

      scannedTransaction.value = matchingTransaction;

      // Proceed to accept the bag
      await performAcceptBag(matchingTransaction.transactionId);
    } catch (e) {
      acceptBagState.value = AcceptBagState.error;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');

      SnackBarService.to.showMessage(
        message: errorMessage.value,
      );

      debugPrint('❌ Error verifying bag QR: $e');
      acceptBagState.value = AcceptBagState.idle;
    }
  }

  // Perform accept bag operation
  Future<void> performAcceptBag(int transactionId) async {
    try {
      debugPrint('✅ Accepting bag with transaction ID: $transactionId');

      final response = await acceptBagService.acceptBag(
        transactionId: transactionId,
        processId: 12,
        userId: int.parse(userId.value),
        handOverUserId: int.parse(userId.value),
      );

      if (!response.isSuccess) {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to accept bag');
      }

      // Success!
      acceptBagState.value = AcceptBagState.success;

      SnackBarService.to.showMessage(
        message: 'Bag ${selectedBag.value!.bagcode} accepted successfully',
      );

      // Refresh the list after successful acceptance
      await Future.delayed(const Duration(seconds: 1));
      await fetchAssignedBags();
    } catch (e) {
      acceptBagState.value = AcceptBagState.error;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');

      SnackBarService.to.showMessage(
        message: errorMessage.value,
      );

      debugPrint('❌ Error accepting bag: $e');
      acceptBagState.value = AcceptBagState.idle;
    }
  }

  // Search bags
  void searchBags(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredBagsList.value = assignedBagsList;
    } else {
      filteredBagsList.value = assignedBagsList.where((bag) {
        return bag.bagcode.toLowerCase().contains(query.toLowerCase()) ||
            bag.phleboName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  // Clear search
  void clearSearch() {
    searchQuery.value = '';
    filteredBagsList.value = assignedBagsList;
  }

  // Reset controller
  void reset() {
    selectedBag.value = null;
    scannedTransaction.value = null;
    scannedBarcode.value = '';
    errorMessage.value = '';
    acceptBagState.value = AcceptBagState.idle;
    searchQuery.value = '';
    filteredBagsList.value = assignedBagsList;
  }

  // Toggle flashlight
  void toggleFlash() {
    scannerController?.toggleTorch();
  }

  // Get status text for transition status
  String getStatusText(int status) {
    switch (status) {
      case 4:
        return 'Assigned';
      case 12:
        return 'Accepted';
      default:
        return 'Status $status';
    }
  }

  // Get status color
  Color getStatusColor(int status) {
    switch (status) {
      case 4:
        return Colors.orange;
      case 12:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}*/
