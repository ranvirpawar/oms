// lib/controllers/handover_connector_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide SnackPosition;
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:geolocator/geolocator.dart';

import '../../../../services/user_service.dart';
import '../../../../utils/ui_designs/liquid_snackbar.dart';
import '../../../auth/model/login_response_model.dart';
import '../../handover_to_phlebo/model/bag_transaction_model.dart';
import '../model/connector_model.dart';
import '../service/connector_service.dart';

enum HandoverState { idle, scanning, processing, success, error }

class HandoverConnectorController extends GetxController {

  final bool isHandOverToRunnerBoy;

  HandoverConnectorController({required this.isHandOverToRunnerBoy}) {
    // Force Empty bag when handing over to Runner Boy
    if (isHandOverToRunnerBoy) {
      selectedBagType.value = 'Empty';
    }
  }
  // -----------------------------------------------------------------
  // Core services & user
  // -----------------------------------------------------------------
  final UserService userService = Get.find<UserService>();
  final ConnectorService connectorService = ConnectorService();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxString userId = ''.obs;
  String get _designationId => isHandOverToRunnerBoy ? '7' : '151';
  // -----------------------------------------------------------------
  // UI state
  // -----------------------------------------------------------------
  final Rx<HandoverState> handoverState = HandoverState.idle.obs;
  final RxBool isLoading = false.obs;
  final RxBool isScanning = false.obs;
  final RxString errorMessage = ''.obs;
  final RxDouble handoverProgress = 0.0.obs;

  // -----------------------------------------------------------------
  // Bag type (Sample / Empty)
  // -----------------------------------------------------------------
  final RxString selectedBagType = 'Empty'.obs; // default
  final List<String> bagTypes = ['Sample', 'Empty'];

  // -----------------------------------------------------------------
  // Connector data
  // -----------------------------------------------------------------
  final RxList<Connector> connectorList = <Connector>[].obs;
  final Rx<Connector?> selectedConnector = Rx<Connector?>(null);

  // -----------------------------------------------------------------
  // Scanner & manual entry
  // -----------------------------------------------------------------
  final MobileScannerController scannerController = MobileScannerController();
  final TextEditingController barcodeController = TextEditingController();
  final RxString scannedBarcode = ''.obs;

  // -----------------------------------------------------------------
  // Scanned bags
  // -----------------------------------------------------------------
  final RxList<BagTransaction> scannedBags = <BagTransaction>[].obs;

  // -----------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();
    _loadUserAndConnectors();
  }

  @override
  void onClose() {
    scannerController.dispose();
    barcodeController.dispose();
    super.onClose();
  }

  Future<void> _loadUserAndConnectors() async {
    try {
      await _loadUser();
      if (user.value != null) {
        await fetchConnectorList();
      }
    } catch (e) {
      debugPrint('Failed to load user or connectors: $e');
    }
  }

  // -----------------------------------------------------------------
  // User
  // -----------------------------------------------------------------
  Future<void> _loadUser() async {
    try {
      final u = await userService.getUser();
      if (u != null) {
        user.value = u;
        userId.value = u.empCode.toString();
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  // -----------------------------------------------------------------
  // 1. Fetch connectors
  // -----------------------------------------------------------------
  Future<void> fetchConnectorList() async {
    if (user.value == null) return;

    try {
      isLoading(true);
      final list = await connectorService.getConnectorList(_designationId); // todo

      connectorList.assignAll(list);
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      LiquidSnack.error(errorMessage.value);
    } finally {
      isLoading(false);
    }
  }

  void selectConnector(Connector? c) => selectedConnector.value = c;

  // -----------------------------------------------------------------
  // Scanner controls
  // -----------------------------------------------------------------
  void startScanning() {
    if (selectedConnector.value == null) {
      LiquidSnack.warning('Select a connector first');
      return;
    }
    isScanning(true);
    scannerController.start();
  }

  void stopScanning() {
    isScanning(false);
    scannerController.stop();
  }

  void toggleFlash() => scannerController.toggleTorch();

  // -----------------------------------------------------------------
  // Barcode handling
  // -----------------------------------------------------------------
  void handleBarcodeScan(String barcode) {
    if (handoverState.value == HandoverState.processing) return;
    scannedBarcode.value = barcode;
    barcodeController.text = barcode;
    stopScanning();
    fetchBagTransaction(barcode);
  }

  void processManualBarcode() {
    final code = barcodeController.text.trim();
    if (code.isEmpty) {
      LiquidSnack.warning('Enter a barcode');
      return;
    }
    if (selectedConnector.value == null) {
      LiquidSnack.warning('Select a connector first');
      return;
    }
    fetchBagTransaction(code);
  }

  int get _scanProcessId {
    return selectedBagType.value == 'Sample' ? 5 : 1;
    // Empty Bag = 1
    // Sample Bag = 5
  }

  // -----------------------------------------------------------------
  // 2. Get bag transaction
  // -----------------------------------------------------------------
  Future<void> fetchBagTransaction(String barcode) async {
    try {
      handoverState(HandoverState.processing);
      final bags = await connectorService.getBagTransaction(
        bagcode: barcode,
        processId: _scanProcessId,
        userId: int.parse(userId.value),
      );

      if (bags.isEmpty) {
        throw Exception('Bag not found');
      }

      final bag = bags.first;

      if (scannedBags.any((b) => b.bagcode == bag.bagcode)) {
        throw Exception('Bag already scanned');
      }

      scannedBags.add(bag);
      handoverState(HandoverState.idle);

      LiquidSnack.success('Bag ${bag.bagcode} added');

      barcodeController.clear();
      scannedBarcode.value = '';
    } catch (e) {
      handoverState(HandoverState.error);
      LiquidSnack.error('Bag is already assigned');
    }
  }

  void removeBag(BagTransaction bag) {
    scannedBags.remove(bag);
    LiquidSnack.info('Bag ${bag.bagcode} removed');
  }

  // -----------------------------------------------------------------
  // Validation
  // -----------------------------------------------------------------
  bool canHandover() =>
      selectedConnector.value != null && scannedBags.isNotEmpty;

  int get handoverProcessId => isHandOverToRunnerBoy ? 7 : 6;
  // -----------------------------------------------------------------
  // 3. Perform handover (initiate → insert)
  // -----------------------------------------------------------------
  Future<void> performHandover() async {
    if (!canHandover()) {
      LiquidSnack.warning('Select connector & scan at least one bag');
      return;
    }

    try {
      isLoading.value = true;
      handoverState(HandoverState.processing);
      handoverProgress(0.0);
      final total = scannedBags.length;
      int done = 0;

      // Location (fallback 0,0)
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low);
      } catch (_) {}
      final lat = position?.latitude ?? 0.0;
      final lng = position?.longitude ?? 0.0;

      for (final bag in scannedBags) {
        // 1. Initiate
        await connectorService.initiateBagTransaction(
          processId: handoverProcessId,
          facilityCode: selectedConnector.value!.facilityCode,
          assignTo: selectedConnector.value!.userId,
          userId: int.parse(userId.value),
          transactionId: bag.transactionId,
        );

        // 2. Final insert
        await connectorService.insertHandoverStatus(
          transactionId: bag.transactionId,
          processId: handoverProcessId,
          userId: int.parse(userId.value),
          handOverUserId: selectedConnector.value!.userId,
          lat: lat,
          lng: lng,
        );

        done++;
        handoverProgress(done / total);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      handoverState(HandoverState.success);
      LiquidSnack.success(
        'Handed over $total bag(s) to ${selectedConnector.value!.userName}',
      );

      await Future.delayed(const Duration(seconds: 2));
      Get.back();
    } catch (e) {
      handoverState(HandoverState.error);
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      LiquidSnack.error(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  // -----------------------------------------------------------------
  // Reset (used by “Hand Over New Bag” button)
  // -----------------------------------------------------------------
  void reset() {
    selectedConnector.value = null;
    selectedBagType.value = 'Sample';
    scannedBags.clear();
    barcodeController.clear();
    scannedBarcode.value = '';
    errorMessage.value = '';
    handoverState(HandoverState.idle);
    handoverProgress(0.0);
    stopScanning();
  }
}
