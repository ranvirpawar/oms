// controllers/handover_phlebotomist_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide SnackPosition;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../services/user_service.dart';
import '../../../../utils/ui_designs/liquid_snackbar.dart';
import '../../../auth/model/login_response_model.dart';
import '../model/bag_transaction_model.dart';

import '../model/phlebotomist_model.dart';
import '../service/phlebotomist_service.dart';

enum HandoverState { idle, scanning, processing, success, error }

class HandoverPhlebotomistController extends GetxController {
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final Rx<String> userId = ''.obs;
  final UserService userService = Get.put(UserService());
  final PhlebotomistService phlebotomistService = PhlebotomistService();

  final MobileScannerController scannerController = MobileScannerController();

  // State management
  final Rx<HandoverState> handoverState = HandoverState.idle.obs;
  final RxBool isLoading = false.obs;
  final RxBool isScanning = false.obs;
  final RxString errorMessage = ''.obs;
  final RxDouble handoverProgress = 0.0.obs;

  // Phlebotomist data
  final RxList<Phlebotomist> phlebotomistList = <Phlebotomist>[].obs;
  final Rx<Phlebotomist?> selectedPhlebotomist = Rx<Phlebotomist?>(null);

  // Bag data
  final RxString scannedBarcode = ''.obs;
  final Rx<BagTransaction?> bagTransaction = Rx<BagTransaction?>(null);
  final TextEditingController barcodeController = TextEditingController();

  // Scanned bags list
  final RxList<BagTransaction> scannedBags = <BagTransaction>[].obs;

  @override
  void onInit() {
    loadUser();
    fetchPhlebotomistList();
    super.onInit();
  }

  @override
  void onClose() {
    scannerController.dispose();
    barcodeController.dispose();
    super.onClose();
  }

  void loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = user.value?.empCode.toString() ?? '';
        debugPrint('✅ User data loaded: ${user.value?.name}');
      } else {
        debugPrint('❌ Failed to load user data');
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  // Fetch phlebotomist list
  Future<void> fetchPhlebotomistList() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await phlebotomistService.getPhlebotomistList('4');

      if (response.isSuccess && response.output != null) {
        phlebotomistList.value = response.output!;
        debugPrint('✅ Loaded ${phlebotomistList.length} phlebotomists');
      } else {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to load phlebotomist list');
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      LiquidSnack.error(errorMessage.value);
      debugPrint('❌ Error fetching phlebotomist list: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Select phlebotomist
  void selectPhlebotomist(Phlebotomist? phlebotomist) {
    selectedPhlebotomist.value = phlebotomist;
    debugPrint('👤 Selected phlebotomist: ${phlebotomist?.userName}');
    debugPrint('👤 Selected phlebotomist ID: ${phlebotomist?.userId}');
    //facility code
    debugPrint('👤 Selected phlebotomist facility code: ${phlebotomist?.facilityCode}');

  }

  // Start scanning
  void startScanning() {
    if (selectedPhlebotomist.value == null) {
      LiquidSnack.warning('Please select a phlebotomist first');
      return;
    }

    isScanning.value = true;
    scannerController.start();
  }

  // Stop scanning
  void stopScanning() {
    isScanning.value = false;
    scannerController.stop();
  }

  // Handle barcode scan
  void handleBarcodeScan(String barcode) {
    if (handoverState.value == HandoverState.processing) return;

    scannedBarcode.value = barcode;
    barcodeController.text = barcode;
    stopScanning();

    fetchBagTransaction(barcode);
  }

  // Process manual barcode
  void processManualBarcode() {
    final barcode = barcodeController.text.trim();
    if (barcode.isEmpty) {
      LiquidSnack.warning('Please enter a barcode');
      return;
    }

    if (selectedPhlebotomist.value == null) {
      LiquidSnack.warning('Please select a phlebotomist first');
      return;
    }

    fetchBagTransaction(barcode);
  }

  // Fetch bag transaction details
  Future<void> fetchBagTransaction(String barcode) async {
    try {
      handoverState.value = HandoverState.processing;
      errorMessage.value = '';

      debugPrint('📦 Fetching bag transaction for: $barcode');

      final response = await phlebotomistService.getBagTransaction(
        bagcode: barcode,
        processId: 1,
        userId: int.parse(userId.value),
      );

      if (!response.isSuccess || response.output == null || response.output!.isEmpty) {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Bag not found or invalid barcode');
      }

      final transaction = response.output!.first;

      // Check if bag already scanned
      if (scannedBags.any((bag) => bag.bagcode == transaction.bagcode)) {
        throw Exception('This bag has already been scanned');
      }

      bagTransaction.value = transaction;
      scannedBags.add(transaction);

      handoverState.value = HandoverState.idle;



      // Clear for next scan
      barcodeController.clear();
      scannedBarcode.value = '';

    } catch (e) {
      handoverState.value = HandoverState.error;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');

      LiquidSnack.error(errorMessage.value);

      debugPrint('❌ Error fetching bag transaction: $e');
    }
  }

  // Remove scanned bag
  void removeBag(BagTransaction bag) {
    scannedBags.remove(bag);

  }

  // Validate handover
  bool canHandover() {
    return selectedPhlebotomist.value != null && scannedBags.isNotEmpty;
  }

  // Perform handover
  Future<void> performHandover() async {
    if (!canHandover()) {
      LiquidSnack.warning('Please select phlebotomist and scan at least one bag');
      return;
    }

    try {
      handoverState.value = HandoverState.processing;
      handoverProgress.value = 0.0;
      errorMessage.value = '';

      final totalBags = scannedBags.length;
      int completedBags = 0;

      debugPrint('🚀 Starting handover of $totalBags bags to ${selectedPhlebotomist.value!.userName}');

      // Process each bag
      for (final bag in scannedBags) {
        final assignResponse = await phlebotomistService.updateInitiateBagTransaction(
          processId: 4,
          facilityCode: selectedPhlebotomist.value!.facilityCode ,
          assignToUserId: selectedPhlebotomist.value!.userId,
          userId: int.parse(userId.value),
          transactionId: bag.transactionId,
        );

        if (!assignResponse.isSuccess) {
          throw Exception('Failed to assign bag ${bag.bagcode}: ${assignResponse.message}');
        }


        final response = await phlebotomistService.insertHandoverStatus(
          transactionId: bag.transactionId,
          processId: 4,
          userId: int.parse(userId.value),
          handOverUserId: selectedPhlebotomist.value!.userId,
        );

        if (!response.isSuccess) {
          throw Exception('Failed to handover bag ${bag.bagcode}: ${response.message}');
        }

        completedBags++;
        handoverProgress.value = completedBags / totalBags;

        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Success!
      handoverState.value = HandoverState.success;

      LiquidSnack.success(
        'Successfully handed over $totalBags bag(s) to ${selectedPhlebotomist.value!.userName}',
      );

      // Navigate back after delay
      await Future.delayed(const Duration(seconds: 2));
      Get.back();

    } catch (e) {
      handoverState.value = HandoverState.error;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');

      LiquidSnack.error(errorMessage.value);

      debugPrint('❌ Error performing handover: $e');
    }
  }

  // Reset controller
  void reset() {
    selectedPhlebotomist.value = null;
    scannedBags.clear();
    bagTransaction.value = null;
    scannedBarcode.value = '';
    barcodeController.clear();
    errorMessage.value = '';
    handoverState.value = HandoverState.idle;
    handoverProgress.value = 0.0;
    stopScanning();
  }

  // Toggle flashlight
  void toggleFlash() {
    scannerController.toggleTorch();
  }
  //
}