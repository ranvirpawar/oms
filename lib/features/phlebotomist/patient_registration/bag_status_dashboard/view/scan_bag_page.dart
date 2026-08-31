// views/scan_bag_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/routes/route_manager.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../runner_boy/collect_empty_bag/view/widget/animated_scan_line.dart';
import '../../../../runner_boy/collect_empty_bag/view/widget/scanner_overlay_painter.dart';
import '../controller/registrarion_bag_controller.dart';



class ScanBagPage extends StatefulWidget {
  const ScanBagPage({super.key});

  @override
  State<ScanBagPage> createState() => _ScanBagPageState();
}

class _ScanBagPageState extends State<ScanBagPage> {
  final MobileScannerController cameraController = MobileScannerController(
    torchEnabled: false,
    facing: CameraFacing.back,
  );

  // Reactive variables (replaces setState)
  final isProcessing = false.obs;
  final processingMessage = 'Scanning...'.obs;

  @override
  void initState() {
    super.initState();
    // Ensure camera starts
    cameraController.start();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BagRegistrationController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        title: 'Scan Bag QR Code',
        actions: [
          Obx(() => IconButton(
            icon: Icon(
              controller.isTorchOn.value ? Icons.flash_on : Icons.flash_off,
              color: controller.isTorchOn.value ? Colors.yellow : Colors.white,
            ),
            onPressed: () async {
              await cameraController.toggleTorch();
              controller.isTorchOn.value = cameraController.torchEnabled;
            },
          )),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) async {
              if (isProcessing.value) return;

              final barcode = capture.barcodes.firstOrNull;
              if (barcode == null || barcode.rawValue == null) return;

              isProcessing.value = true;
              processingMessage.value = 'Verifying QR Code...';

              await _processBarcode(barcode.rawValue!, controller);
            },
          ),

          // Scanner Frame Overlay (only when not processing)
          Obx(() => !isProcessing.value
              ? CustomPaint(
            painter: ScannerOverlayPainter(),
            child: const Center(
              child: AnimatedScanLine(height: 250, width: 250),
            ),
          )
              : const SizedBox()),

          // Loading / Success Overlay
          Obx(() => isProcessing.value
              ? Container(
            color: Colors.black.withOpacity(0.85),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Spinner
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Dynamic Message
                  Text(
                    processingMessage.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please wait...',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),

                  const SizedBox(height: 48),

                  // Progress Steps - All turn green on success
                  _buildProgressSteps(),
                ],
              ),
            ),
          )
              : const SizedBox()),

          // Bottom Instructions
          Obx(() => !isProcessing.value
              ? Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 56),
                  SizedBox(height: 16),
                  Text(
                    'Position the QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The bag will open automatically after scanning',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
              : const SizedBox()),
        ],
      ),
    );
  }

  // Reactive Progress Steps
  Widget _buildProgressSteps() {
    final msg = processingMessage.value.toLowerCase();

    final bool scanComplete = true;
    final bool verifyComplete = msg.contains('verifying') || msg.contains('success');
    final bool openComplete = msg.contains('success');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStep('Scan', scanComplete),
          _buildLine(scanComplete && verifyComplete),
          _buildStep('Verify', verifyComplete),
          _buildLine(verifyComplete && openComplete),
          _buildStep('Open', openComplete),
        ],
      ),
    );
  }

  Widget _buildStep(String label, bool active) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? AppColors.primary : Colors.white38,
              width: 2.5,
            ),
          ),
          child: Center(
            child: active
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white38,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool active) {
    return Container(
      width: 50,
      height: 3,
      margin: const EdgeInsets.only(bottom: 20),
      color: active ? AppColors.primary : Colors.white24,
    );
  }

  // Main processing logic
  Future<void> _processBarcode(String scannedCode, BagRegistrationController controller) async {
    try {
      processingMessage.value = 'Verifying Bag...';

      // Uses new openBag() which calls InsertStartQRCodeBegEvent (processid=2)
      final success = await controller.openBag(scannedCode);

      if (!success) {
        processingMessage.value = 'Failed to open bag';
        await Future.delayed(const Duration(seconds: 2));
        _resetScanner();
        return;
      }

      processingMessage.value = 'Bag Opened Successfully! ✓';
      RouteManager.navigateToBagStatusDashboard();
    } catch (e) {
      processingMessage.value = 'Error occurred';
      await Future.delayed(const Duration(seconds: 2));
      _resetScanner();
    }
  }
  void _resetScanner() {
    if (mounted) {
      isProcessing.value = false;
      processingMessage.value = 'Scanning...';
    }
  }
}
/*class ScanBagPage extends StatefulWidget {
  const ScanBagPage({Key? key}) : super(key: key);

  @override
  State<ScanBagPage> createState() => _ScanBagPageState();
}

class _ScanBagPageState extends State<ScanBagPage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;
  String processingMessage = 'Scanning...';

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BagRegistrationController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        title: "Scan Bag Qr Code",
        actions: [
          Obx(() {
            return IconButton(
              icon: Icon(
                controller.isTorchOn.value ? Icons.flash_on : Icons.flash_off,
                color: controller.isTorchOn.value ? Colors.yellow : Colors.white,
              ),
              onPressed: () async {
                await cameraController.toggleTorch();
                controller.isTorchOn.value = cameraController.torchEnabled;
              },
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          // Scanner View
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) async {
              if (isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() {
                    isProcessing = true;
                    processingMessage = 'Verifying QR Code...';
                  });

                  // Process the scanned code with progress updates
                  await _processBarcode(barcode.rawValue!, controller);
                  break;
                }
              }
            },
          ),

          // Scanning overlay (only show when not processing)
          if (!isProcessing)
            CustomPaint(
              painter: ScannerOverlayPainter(),
              child: const Center(
                child: AnimatedScanLine(height: 250, width: 250),
              ),
            ),

          // Loading Overlay (show when processing)
          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Loading Circle
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4299E1),
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Processing Message
                    Text(
                      processingMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Please wait...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),

                    // Progress Steps (Optional - shows current step)
                    const SizedBox(height: 32),
                    _buildProgressSteps(),
                  ],
                ),
              ),
            ),

          // Instructions at bottom (only show when not processing)
          if (!isProcessing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Position the QR code within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The bag will open automatically after scanning',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Process barcode with progress updates
  Future<void> _processBarcode(
      String scannedCode, BagRegistrationController controller) async {
    try {
      // Step 1: Scanning QR
      setState(() => processingMessage = 'Scanning QR Code...');
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Verifying
      setState(() => processingMessage = 'Verifying Bag...');

      // Call the API
      final success = await controller.scanAndOpenBag(scannedCode);

      if (success) {
        // Step 3: Opening bag
        setState(() => processingMessage = 'Bag Opened Successfully! ✓');
        await Future.delayed(const Duration(milliseconds: 800));

        // Navigate back to dashboard
        if (mounted) {
          Get.back();
        }
      } else {
        // Show error and reset
        setState(() {
          processingMessage = 'Failed to open bag';
          isProcessing = false;
        });

        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          setState(() => isProcessing = false);
        }
      }
    } catch (e) {
      // Handle error
      setState(() {
        processingMessage = 'Error: ${e.toString()}';
        isProcessing = false;
      });

      await Future.delayed(const Duration(milliseconds: 2000));

      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  // Build progress steps indicator
  Widget _buildProgressSteps() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepIndicator('Scan', true),
          _buildStepLine(),
          _buildStepIndicator('Verify', processingMessage.contains('Verifying')),
          _buildStepLine(),
          _buildStepIndicator('Open', processingMessage.contains('Success')),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.white.withOpacity(0.2),
    );
  }
}*/



/*class ScanBagPage extends StatefulWidget {
  const ScanBagPage({Key? key}) : super(key: key);

  @override
  State<ScanBagPage> createState() => _ScanBagPageState();
}

class _ScanBagPageState extends State<ScanBagPage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BagRegistrationController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(title: "Scan Bag Qr Code",
        actions: [
          Obx(() {
            return IconButton(
              icon: Icon(
                controller.isTorchOn.value ? Icons.flash_on : Icons.flash_off,
                color: controller.isTorchOn.value ? Colors.yellow : Colors.white,
              ),
              onPressed: () async {
                await cameraController.toggleTorch();
                controller.isTorchOn.value = cameraController.torchEnabled;
              },
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          // Scanner View
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) async {
              if (isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => isProcessing = true);

                  // Show loading
                  Get.dialog(
                    const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Opening bag...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    barrierDismissible: false,
                  );

                  // Process the scanned code
                  final success = await controller.scanAndOpenBag(
                    barcode.rawValue!,
                  );

                  Get.back(); // Close loading dialog

                  if (success) {
                    Get.back(); // Go back to dashboard
                  } else {
                    setState(() => isProcessing = false);
                  }
                  break;
                }
              }
            },
          ),

          // Scanning overlay
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: const Center(
                child: AnimatedScanLine(height: 250, width: 250)),
          ),
          // Instructions at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Position the QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The bag will open automatically after scanning',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/

