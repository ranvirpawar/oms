import 'package:flutter/material.dart';
import 'package:lifenity_connect/features/runner_boy/collect_empty_bag/view/widget/animated_scan_line.dart';
import 'package:lifenity_connect/features/runner_boy/collect_empty_bag/view/widget/scanner_overlay_painter.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../controller/collect_destination_bag_controller.dart';

class CollectDestinationBagView extends StatelessWidget {
  const CollectDestinationBagView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CollectDestinationBagController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Collect Destination Bag',
        actions: [
          Obx(() => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: Icon(
                controller.flashlightEnabled.value
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: controller.flashlightEnabled.value
                    ? Colors.yellow
                    : AppColors.surfaceContainer,
              ),
              onPressed: controller.toggleFlashlight,
            ),
          )),
        ],
      ),
      body: Column(
        children: [
          // ── Collapsible Scanner ───────────────────────────────────────────
          Obx(() {
            final hasBarcode = controller.scannedBarcode.value.isNotEmpty;
            final isTyping = controller.isManualInputActive.value;
            final isCollapsed = hasBarcode || isTyping;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: isCollapsed
                  ? 100
                  : MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              child: Stack(
                children: [
                  // Camera feed
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(isCollapsed ? 20 : 0),
                    ),
                    child: MobileScanner(
                      controller: controller.scannerController,
                      onDetect: isTyping ? null : controller.onBarcodeDetected,
                    ),
                  ),

                  // Scan overlay (expanded only)
                  if (!isCollapsed)
                    CustomPaint(
                      painter: ScannerOverlayPainter(),
                      child: const Center(
                        child: AnimatedScanLine(height: 250, width: 250),
                      ),
                    ),

                  // Collapsed header bar
                  if (isCollapsed)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black87, Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            isTyping ? Icons.keyboard : Icons.inventory_2,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isTyping
                                      ? 'Manual Entry Mode'
                                      : 'Scanned: ${controller.scannedBarcode.value}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  isTyping
                                      ? 'Type barcode and press send'
                                      : 'Ready to collect',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (isTyping)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white),
                              onPressed: () {
                                controller.manualBarcodeController.clear();
                                controller.manualInputFocusNode.unfocus();
                                controller.isManualInputActive.value = false;
                                controller.resetScanner();
                              },
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white),
                              onPressed: controller.resetScanner,
                            ),
                        ],
                      ),
                    ),

                  // Hint text (expanded only)
                  if (!isCollapsed)
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Align destination bag barcode within frame',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),

          // ── Bottom Panel ──────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Obx(() {
                final barcode = controller.scannedBarcode.value;
                final hasBarcode = barcode.isNotEmpty;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Manual input (no barcode yet) ──────────────────
                      if (!hasBarcode) ...[
                        TextField(
                          focusNode: controller.manualInputFocusNode,
                          controller: controller.manualBarcodeController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Enter destination bag barcode manually',
                            prefixIcon: const Icon(Icons.qr_code_2),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: controller.onManualSubmit,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor:
                            isDark ? Colors.grey[800] : Colors.grey[100],
                          ),
                          onSubmitted: (_) => controller.onManualSubmit(),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.qr_code_scanner,
                                    size: 90, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Scan or enter destination bag\nbarcode to continue',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // ── Barcode detected — show barcode card + Collect ──
                      if (hasBarcode) ...[
                        _buildRow('Bag Barcode', barcode, Icons.tag),
                        const SizedBox(height: 32),

                        // Collect button
                        Obx(() => SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: controller.isSubmitting.value
                                ? null
                                : controller.collectDestinationBag,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                            ),
                            child: controller.isSubmitting.value
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : const Text(
                              'Collect Destination Bag',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.surfaceContainer,
                              ),
                            ),
                          ),
                        )),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: controller.resetScanner,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: theme.colorScheme.primary, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Scan Another Bag',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, IconData icon) {
    final theme = Get.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (theme.brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[100])!
            .withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}