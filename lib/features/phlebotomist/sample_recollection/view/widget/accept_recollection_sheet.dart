import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../../componenents/c_textformfeild.dart';
import '../../../../../constants/app_assets.dart';
import '../../../../../routes/route_manager.dart';
import '../../../../../theme/app_colors.dart';
import '../../controller/recollection_tests_controller.dart';

import 'package:flutter_svg/flutter_svg.dart';

class AcceptRecollectionBottomSheet extends StatefulWidget {
  final RecollectTestsController controller;

  const AcceptRecollectionBottomSheet({super.key, required this.controller});

  @override
  State<AcceptRecollectionBottomSheet> createState() =>
      _AcceptRecollectionBottomSheetState();
}

class _AcceptRecollectionBottomSheetState
    extends State<AcceptRecollectionBottomSheet> {
  bool isProcessing = false;
  late TextEditingController barcodeController;
  RxBool isBarcodeChecking = false.obs;
  RxString barcodeError = ''.obs;
  RxBool isBarcodeValid = false.obs;
  RxBool barcodeApiValid = false.obs;
  Timer? _debounceTimer;
  bool _showMoreTests = false;

  @override
  void initState() {
    super.initState();
    barcodeController = TextEditingController();
    barcodeController.addListener(_onBarcodeChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    barcodeController.removeListener(_onBarcodeChanged);
    barcodeController.dispose();
    super.dispose();
  }

  void _onBarcodeChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _handleBarcodeInput(barcodeController.text);
      }
    });
  }

  void _handleBarcodeInput(String input) {
    String digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 12) {
      digitsOnly = digitsOnly.substring(0, 12);
    }
    final String finalText = 'AC$digitsOnly';
    if (barcodeController.text != finalText) {
      barcodeController.value = TextEditingValue(
        text: finalText,
        selection: TextSelection.collapsed(offset: finalText.length),
      );
    }
    barcodeApiValid.value = false;
    isBarcodeChecking.value = false;
    barcodeError.value = '';
    if (finalText.isEmpty) {
      isBarcodeValid.value = false;
      return;
    }
    if (!_validateBarcodeFormat(finalText)) {
      return;
    }
    if (finalText.length == 14 &&
        finalText.startsWith('AC') &&
        RegExp(r'^AC\d{12}$').hasMatch(finalText)) {
      isBarcodeChecking.value = true;
      _checkBarcodeAPI(finalText);
    }
  }

  bool _validateBarcodeFormat(String barcode) {
    if (barcode.isEmpty) {
      barcodeError.value = '';
      isBarcodeValid.value = false;
      return false;
    }
    if (!barcode.startsWith('AC')) {
      barcodeError.value = 'Barcode must start with AC';
      isBarcodeValid.value = false;
      return false;
    }
    if (barcode.length < 14) {
      barcodeError.value = 'Barcode must be 14 characters (AC + 12 digits)';
      isBarcodeValid.value = false;
      return false;
    }
    if (!RegExp(r'^AC\d{12}$').hasMatch(barcode)) {
      barcodeError.value =
          'Invalid barcode format. Use AC followed by 12 digits';
      isBarcodeValid.value = false;
      return false;
    }
    barcodeError.value = '';
    isBarcodeValid.value = true;
    return true;
  }

  Future<void> _checkBarcodeAPI(String barcode) async {
    try {
      final isValid = await widget.controller.checkDuplicateBarcode(barcode);
      if (mounted) {
        isBarcodeChecking.value = false;
        if (isValid) {
          barcodeApiValid.value = true;
          barcodeError.value = '';
          isBarcodeValid.value = true;
        } else {
          barcodeApiValid.value = false;
          barcodeError.value = 'Please enter a valid barcode';
          isBarcodeValid.value = false;
        }
      }
    } catch (e) {
      if (mounted) {
        isBarcodeChecking.value = false;
        barcodeError.value = 'Error validating barcode. Please try again.';
        isBarcodeValid.value = false;
        barcodeApiValid.value = false;
      }
    }
  }

  void _processScanResult(String scannedCode, {required bool isMainBarcode}) {
    widget.controller.isScanning.value = false;
    Get.back(); // Close scanner
    String digitsOnly = scannedCode.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 12) {
      digitsOnly = digitsOnly.substring(0, 12);
    }
    final String formattedCode = 'AC$digitsOnly';
    barcodeController.text = formattedCode;
    _handleBarcodeInput(formattedCode);
  }

  void openBarcodeScanner({required bool isMainBarcode}) {
    widget.controller.isScanning.value = true;
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
                  const Text('Scan Barcode',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () {
                      widget.controller.isScanning.value = false;
                      Get.back();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MobileScanner(
                controller: widget.controller.scannerController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _processScanResult(barcode.rawValue!,
                          isMainBarcode: isMainBarcode);
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

  Widget buildSuffixIcon({required bool isMainBarcode}) {
    return GestureDetector(
      onTap: () => openBarcodeScanner(isMainBarcode: isMainBarcode),
      child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 24),
    );
  }

  bool _hasSugarTests() {
    return widget.controller.selectedTests
        .any((test) => [969, 970, 971].contains(test.serviceCode));
  }

  bool _hasNonSugarTests() {
    return widget.controller.selectedTests
        .any((test) => ![969, 970, 971].contains(test.serviceCode));
  }

  Future<void> _processAcceptance() async {
    if (isProcessing || !isBarcodeValid.value || !barcodeApiValid.value) {
      SnackBarService.to.showMessage(
        message: 'Please enter a valid barcode.',
        backgroundColor: Colors.orange,
      );
      return;
    }
    setState(() {
      isProcessing = true;
    });
    try {
      final success =
          await widget.controller.acceptRecollection(barcodeController.text);
      if (success && mounted) {
        Navigator.of(context).pop();
        RouteManager.navigateToSampleRecollection(true);
      }
    } catch (e) {
      debugPrint('Error in _processAcceptance: $e');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void _safeBack() {
    if (isProcessing) return;
    try {
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
      Navigator.of(context).pop();
    } catch (e) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom:  20.0,
          // bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [CupertinoColors.systemBackground, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    AppAssets.testTube,
                    width: 24,
                    height: 24,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Accept Test Recollection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24, color: Colors.grey),
                    onPressed: _safeBack,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Selected Tests

              Obx(() {
                final testNames = widget.controller.selectedTests
                    .map((test) =>
                        test.serviceName ?? 'Test ${test.serviceCode}')
                    .join(', ');
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(AppAssets.fileNoteIcon,
                              width: 16, height: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Selected Tests : ${widget.controller.selectedTests.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final textSpan = TextSpan(
                            text: testNames,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          );
                          final textPainter = TextPainter(
                            text: textSpan,
                            maxLines: 2,
                            textDirection: TextDirection.ltr,
                          )..layout(maxWidth: constraints.maxWidth);
                          final isOverflowing = textPainter.didExceedMaxLines;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                testNames,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                maxLines: _showMoreTests ? null : 2,
                                overflow: _showMoreTests
                                    ? null
                                    : TextOverflow.ellipsis,
                              ),
                              if (isOverflowing)
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _showMoreTests = !_showMoreTests),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      _showMoreTests
                                          ? 'Show Less'
                                          : 'Show More',
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              // Special message for sugar tests
              if (_hasSugarTests() && _hasNonSugarTests()) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_outlined,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sugar tests cannot be collected together with other tests.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_hasSugarTests()) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Glucose test Collection',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Barcode input field
              CFormTextField(
                controller: barcodeController,
                label: 'Sample Barcode',
                iconPath: AppAssets.barcodeIcon,
                isRequired: true,
                keyboardType: TextInputType.number,
                maxLength: 14,
                suffix: buildSuffixIcon(isMainBarcode: true),
                onChanged: (value) {},
              ),
              // Loading indicator
              Obx(() {
                if (isBarcodeChecking.value) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Validating barcode...',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              // Error display
              Obx(() {
                if (barcodeError.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              barcodeError.value,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 20),
              // Action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      (_hasSugarTests() && _hasNonSugarTests()) || isProcessing
                          ? null
                          : _processAcceptance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          (_hasSugarTests() && _hasNonSugarTests())
                              ? 'Cannot Collect Mixed Tests'
                              : 'Accept Selected Tests',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*

class AcceptRecollectionBottomSheet extends StatefulWidget {
  final RecollectTestsController controller;

  const AcceptRecollectionBottomSheet({super.key, required this.controller});

  @override
  State<AcceptRecollectionBottomSheet> createState() => _AcceptRecollectionBottomSheetState();
}

class _AcceptRecollectionBottomSheetState extends State<AcceptRecollectionBottomSheet> {
  // Local state management
  bool showConfirmation = false;
  bool isProcessing = false;

  // Barcode controllers
  late TextEditingController barcodeController;

  // Barcode validation states
  RxBool isBarcodeChecking = false.obs;
  RxString barcodeError = "".obs;
  RxBool isBarcodeValid = false.obs;
  RxBool barcodeApiValid = false.obs;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    barcodeController = TextEditingController();
    barcodeController.addListener(_onBarcodeChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    barcodeController.removeListener(_onBarcodeChanged);
    barcodeController.dispose();
    super.dispose();
  }

  void _onBarcodeChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _handleBarcodeInput(barcodeController.text);
      }
    });
  }

  void _handleBarcodeInput(String input) {
    // Remove all non-digit characters
    String digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 12 digits
    if (digitsOnly.length > 12) {
      digitsOnly = digitsOnly.substring(0, 12);
    }

    // Final value to be stored in controller
    String finalText = 'AC$digitsOnly';

    // Avoid infinite loop by checking if different
    if (barcodeController.text != finalText) {
      barcodeController.value = TextEditingValue(
        text: finalText,
        selection: TextSelection.collapsed(offset: finalText.length),
      );
    }

    // Reset states
    barcodeApiValid.value = false;
    isBarcodeChecking.value = false;
    barcodeError.value = '';

    if (finalText.isEmpty) {
      isBarcodeValid.value = false;
      return;
    }

    if (!_validateBarcodeFormat(finalText)) {
      return;
    }

    if (finalText.length == 14 &&
        finalText.startsWith('AC') &&
        RegExp(r'^AC\d{12}$').hasMatch(finalText)) {
      isBarcodeChecking.value = true;
      _checkBarcodeAPI(finalText);
    }
  }

  bool _validateBarcodeFormat(String barcode) {
    if (barcode.isEmpty) {
      barcodeError.value = '';
      isBarcodeValid.value = false;
      return false;
    }

    if (!barcode.startsWith('AC')) {
      barcodeError.value = 'Barcode must start with AC';
      isBarcodeValid.value = false;
      return false;
    }

    if (barcode.length < 14) {
      barcodeError.value = 'Barcode must be 14 characters (AC + 12 digits)';
      isBarcodeValid.value = false;
      return false;
    }

    if (!RegExp(r'^AC\d{12}$').hasMatch(barcode)) {
      barcodeError.value = 'Invalid barcode format. Use AC followed by 12 digits';
      isBarcodeValid.value = false;
      return false;
    }

    barcodeError.value = '';
    isBarcodeValid.value = true;
    return true;
  }

  Future<void> _checkBarcodeAPI(String barcode) async {
    try {
      // Replace this with your actual API call
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Simulate API response - replace with actual logic
      final isValid = await _validateBarcodeWithAPI(barcode);

      if (mounted) {
        isBarcodeChecking.value = false;
        if (isValid) {
          barcodeApiValid.value = true;
          barcodeError.value = '';
          isBarcodeValid.value = true;
        } else {
          barcodeApiValid.value = false;
          barcodeError.value = 'Barcode not found or already used';
          isBarcodeValid.value = false;
        }
      }
    } catch (e) {
      if (mounted) {
        isBarcodeChecking.value = false;
        barcodeError.value = 'Error validating barcode. Please try again.';
        isBarcodeValid.value = false;
        barcodeApiValid.value = false;
      }
    }
  }

  // Replace this with your actual API validation method
  Future<bool> _validateBarcodeWithAPI(String barcode) async {
    // Implement your actual barcode validation API call here
    // For now, returning true as example
    return true;
  }

  Widget _buildSuffixIcon() {
    return Obx(() {
      if (isBarcodeChecking.value) {
        return Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.all(8),
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      }

      if (barcodeError.value.isNotEmpty) {
        return Container(
          margin: const EdgeInsets.all(8),
          child: const Icon(Icons.error, color: Colors.red, size: 20),
        );
      }

      if (barcodeApiValid.value) {
        return Container(
          margin: const EdgeInsets.all(8),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
        );
      }

      return const SizedBox();
    });
  }

  bool _hasSugarTests() {
    // Check if any selected test has sugar test codes (969, 970, 971)
    return widget.controller.selectedTests.any((test) =>
        [969, 970, 971].contains(test.serviceCode));
  }

  bool _hasNonSugarTests() {
    // Check if any selected test is NOT a sugar test
    return widget.controller.selectedTests.any((test) =>
    ![969, 970, 971].contains(test.serviceCode));
  }

  void _toggleConfirmation() {
    if (!isBarcodeValid.value || !barcodeApiValid.value) {
      SnackBarService.to.showMessage(message:
        'Please enter a valid barcode.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      showConfirmation = !showConfirmation;
    });
  }

  Future<void> _processAcceptance() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final success = await widget.controller.acceptRecollection(barcodeController.text);

      if (success && mounted) {
        // Close the bottom sheet on success
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint("Error in _processAcceptance: $e");
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
          showConfirmation = false;
        });
      }
    }
  }

  void _safeBack() {
    if (isProcessing) return;

    try {
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
      Navigator.of(context).pop();
    } catch (e) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AppAssets.testTube,
                  width: 20,
                  height: 20,
                  color: showConfirmation ? Colors.green : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  showConfirmation ? 'Confirm Acceptance' : 'Accept Test Recollection',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: showConfirmation ? Colors.green : Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                if (!isProcessing)
                  IconButton(
                    icon: Icon(
                      showConfirmation ? Icons.arrow_back : Icons.close,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: showConfirmation ? _toggleConfirmation : _safeBack,
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Content based on state
            if (!showConfirmation) ...[
              // Special message for sugar tests
              if (_hasSugarTests() && _hasNonSugarTests()) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_outlined, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sugar tests cannot be collected together with other tests.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_hasSugarTests()) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sugar test collection - Enter the special barcode.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Barcode input field
              CFormTextField(
                controller: barcodeController,
                label: "Sample Barcode",
                iconPath: AppAssets.barcodeIcon,
                isRequired: true,
                keyboardType: TextInputType.number,
                maxLength: 16,
                suffix: _buildSuffixIcon(),
                onChanged: (value) {
                  // The listener will handle the validation
                },
              ),

              // Loading indicator
              Obx(() {
                if (isBarcodeChecking.value) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                            'Validating barcode...',
                            style: TextStyle(color: Colors.blue, fontSize: 12)
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              }),

              // Error display
              Obx(() {
                if (barcodeError.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              barcodeError.value,
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              const SizedBox(height: 20),

              // Action button - disable if sugar + non-sugar tests
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton(
                  onPressed: (_hasSugarTests() && _hasNonSugarTests()) ? null : _toggleConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    (_hasSugarTests() && _hasNonSugarTests())
                        ? 'Cannot Collect Mixed Tests'
                        : 'Accept Selected Tests',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ] else ...[
              // Confirmation view
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Confirm Acceptance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Are you sure you want to accept recollection of the selected test(s)?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Show entered barcode
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Barcode: ${barcodeController.text}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Show selected tests count
                    Obx(() {
                      final testCount = widget.controller.selectedTests.length;
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.science_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tests to accept: $testCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Confirmation buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isProcessing ? null : _toggleConfirmation,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(double.infinity, 38),
                        foregroundColor: AppColors.secondary,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : _processAcceptance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(double.infinity, 38),
                        elevation: 0,
                      ),
                      child: isProcessing
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Confirm Acceptance',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}*/
