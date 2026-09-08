import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide SnackPosition;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../utils/helper_functions/helper_methods.dart';
import '../../../../utils/ui_designs/liquid_snackbar.dart';

import '../service/merge_barcode_service.dart';
import '../model/merge_test_patient_model.dart';

class MergeBarcodeController extends GetxController {
  final MergeBarcodeService _service = MergeBarcodeService();

  final TextEditingController primaryBarcodeController = TextEditingController();
  final TextEditingController glucoseBarcodeController = TextEditingController();

  final Rxn<MergeTestPatientModel> primaryPatient = Rxn<MergeTestPatientModel>();
  final Rxn<MergeTestPatientModel> glucosePatient = Rxn<MergeTestPatientModel>();
  final MobileScannerController scannerController = MobileScannerController();
  final RxBool isScanning = false.obs;
  final RxBool isPrimaryChecking = false.obs;
  final RxBool isGlucoseChecking = false.obs;
  final RxBool isMerging = false.obs;

  final RxString primaryError = ''.obs;
  final RxString glucoseError = ''.obs;

  // Track format validity separately from "patient found" state, same as
  // TestBarcodeController's isMainBarcodeValid / isGlucoseBarcodeValid.
  final RxBool isPrimaryFormatValid = true.obs;
  final RxBool isGlucoseFormatValid = true.obs;

  bool get canMerge =>
      primaryPatient.value != null &&
          glucosePatient.value != null &&
          !isMerging.value;

  @override
  void onInit() {
    super.onInit();
    primaryBarcodeController.addListener(() {
      _handleBarcodeInput(primaryBarcodeController.text, isPrimary: true);
    });
    glucoseBarcodeController.addListener(() {
      _handleBarcodeInput(glucoseBarcodeController.text, isPrimary: false);
    });
  }

  // ── Shared AC-prefixed barcode formatting + validation ─────────────────
  void _handleBarcodeInput(String input, {required bool isPrimary}) {
    final controller = isPrimary ? primaryBarcodeController : glucoseBarcodeController;
    final isCheckingObs = isPrimary ? isPrimaryChecking : isGlucoseChecking;
    final errorObs = isPrimary ? primaryError : glucoseError;
    final validObs = isPrimary ? isPrimaryFormatValid : isGlucoseFormatValid;
    final patientObs = isPrimary ? primaryPatient : glucosePatient;

    // Strip everything except digits
    String digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');

    // Cap at 12 digits
    if (digitsOnly.length > 12) {
      digitsOnly = digitsOnly.substring(0, 12);
    }

    final String finalText = 'AC$digitsOnly';

    // Avoid re-triggering the listener in a loop
    if (controller.text != finalText) {
      controller.value = TextEditingValue(
        text: finalText,
        selection: TextSelection.collapsed(offset: finalText.length),
      );
      return; // setting .value re-fires the listener with the corrected text
    }

    // Clear any previously-fetched patient/error while the user is still typing
    if (patientObs.value != null) patientObs.value = null;
    isCheckingObs.value = false;

    if (finalText == 'AC' || digitsOnly.isEmpty) {
      errorObs.value = '';
      validObs.value = true;
      return;
    }

    if (!_validateBarcodeFormat(finalText, isPrimary: isPrimary)) {
      return;
    }

    // Cross-field duplicate check
    final otherBarcode =
    isPrimary ? glucoseBarcodeController.text : primaryBarcodeController.text;
    if (otherBarcode.isNotEmpty && finalText == otherBarcode) {
      errorObs.value = isPrimary
          ? 'This barcode is already used as the sugar barcode'
          : 'This barcode is already used as the primary barcode';
      validObs.value = false;
      return;
    }

    // Only hit the API once we have a full AC + 12-digit code
    if (finalText.length == 14 && RegExp(r'^AC\d{12}$').hasMatch(finalText)) {
      isCheckingObs.value = true;
      isPrimary ? fetchPrimaryPatient(finalText) : fetchGlucosePatient(finalText);
    }
  }

  bool _validateBarcodeFormat(String barcode, {required bool isPrimary}) {
    final label = isPrimary ? 'Barcode' : 'Glucose Barcode';
    final errorObs = isPrimary ? primaryError : glucoseError;
    final validObs = isPrimary ? isPrimaryFormatValid : isGlucoseFormatValid;

    if (barcode.length > 14) {
      errorObs.value = '$label cannot exceed 14 characters (AC + 12 digits)';
      validObs.value = false;
      return false;
    }

    if (barcode.length < 14) {
      errorObs.value = '$label needs ${14 - barcode.length} more digits';
      validObs.value = false;
      return false;
    }

    errorObs.value = '';
    validObs.value = true;
    return true;
  }

  // ── Primary barcode fetch ───────────────────────────────────────────────
  Future<void> fetchPrimaryPatient(String orderId) async {
    if (orderId.isEmpty) return;

    isPrimaryChecking.value = true;
    primaryError.value = '';
    try {
      final patient = await _service.fetchPatientDetails(orderId: orderId);
      isPrimaryChecking.value = false;
      if (patient == null) {
        primaryError.value = 'No record found for this barcode';
      } else {
        primaryPatient.value = patient;
      }
    } catch (e) {
      isPrimaryChecking.value = false;
      primaryError.value = 'Failed to fetch details. Please try again.';
      kPrint('[MergeBarcodeController] fetchPrimaryPatient error: $e');
    }
  }

  // ── Sugar / glucose barcode fetch ──────────────────────────────────────
  Future<void> fetchGlucosePatient(String orderId) async {
    if (orderId.isEmpty) return;

    isGlucoseChecking.value = true;
    glucoseError.value = '';
    try {
      final patient = await _service.fetchPatientDetails(orderId: orderId);
      isGlucoseChecking.value = false;
      if (patient == null) {
        glucoseError.value = 'No record found for this barcode';
      } else {
        glucosePatient.value = patient;
      }
    } catch (e) {
      isGlucoseChecking.value = false;
      glucoseError.value = 'Failed to fetch details. Please try again.';
      kPrint('[MergeBarcodeController] fetchGlucosePatient error: $e');
    }
  }

  // ── Merge action ───────────────────────────────────────────────────────
  Future<void> mergeBarcodes() async {
    if (!canMerge) return;

    isMerging.value = true;
    try {
      final message = await _service.mergeBarcodes(
        primaryVisitCode: primaryPatient.value!.visitCode,
        primaryOrderId: primaryPatient.value!.orderId,
        sugarVisitCode: glucosePatient.value!.visitCode,
        glucoseOrderId: glucosePatient.value!.orderId,
      );

      LiquidSnack.success(message, title: 'Merged');
      _resetAll();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      LiquidSnack.error(msg, title: 'Merge failed');
      kPrint('[MergeBarcodeController] mergeBarcodes error: $e');
    } finally {
      isMerging.value = false;
    }
  }
  // ── NEW: scanner bottom sheet, mirrors TestBarcodeController ───────────
  void openBarcodeScanner({required bool isPrimary}) {
    isScanning.value = true;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan Barcode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      isScanning.value = false;
                      Get.back();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MobileScanner(
                controller: scannerController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _processScanResult(barcode.rawValue!, isPrimary: isPrimary);
                      break;
                    }
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Position the barcode within the frame to scan',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      isDismissible: false,
    );
  }

  void _processScanResult(String scannedCode, {required bool isPrimary}) {
    isScanning.value = false;
    Get.back(); // close scanner sheet

    String digitsOnly = scannedCode.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 12) {
      digitsOnly = digitsOnly.substring(0, 12);
    }
    final String formattedCode = 'AC$digitsOnly';

    // Setting .text triggers the existing listener, which will validate
    // and kick off the patient lookup exactly like manual typing does.
    if (isPrimary) {
      primaryBarcodeController.text = formattedCode;
    } else {
      glucoseBarcodeController.text = formattedCode;
    }
  }
  void _resetAll() {
    primaryBarcodeController.clear();
    glucoseBarcodeController.clear();
    primaryPatient.value = null;
    glucosePatient.value = null;
    primaryError.value = '';
    glucoseError.value = '';
  }

  @override
  void onClose() {
    primaryBarcodeController.dispose();
    glucoseBarcodeController.dispose();
    scannerController.dispose(); // NEW
    super.onClose();
  }
}
