// lib/views/handover_bag_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/constants/app_assets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../../../phlebotomist/accept_bag/view/widget/scanner_bottomsheet.dart';
import '../controller/handover_bag_controller.dart';
class HandoverBagView extends StatelessWidget {
  const HandoverBagView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HandoverBagController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Handover to Inventory',
        actions: [
          Obx(() => Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: Icon(
                controller.flashlightEnabled.value ? Icons.flash_on : Icons.flash_off,
                color: controller.flashlightEnabled.value ? Colors.yellow : AppColors.surfaceContainer,
              ),
              onPressed: controller.toggleFlashlight,
            ),
          )),
        ],
      ),
      body: Column(
        children: [
          // Collapsible Scanner Section
          Obx(() {
            final hasBag = controller.bagDetails.value != null;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: hasBag ? 100 : MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(hasBag ? 20 : 0)),
                    child: MobileScanner(
                      controller: controller.scannerController,
                      onDetect: controller.onBarcodeDetected,
                    ),
                  ),

                  if (!hasBag)
                    CustomPaint(
                      painter: ScannerOverlayPainter(),
                      child: const Center(child: AnimatedScanLine(height: 250, width: 250)),
                    ),

                  // Collapsed Header when bag is scanned
                  if (hasBag)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black87, Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: GestureDetector(
                        onTap: controller.resetScanner,
                        child: Row(
                          children: [
                           Image.asset(AppAssets.bagInventory, height: 24,),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Scanned: ${controller.bagDetails.value!.bagcode}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text('Tap to scan another', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),

                               const Icon(Icons.camera_alt, color: Colors.white),


                          ],
                        ),
                      ),
                    ),

                  // Loading Overlay
                  if (controller.isLoading.value)
                    Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),

                  // Hint Text
                  if (!hasBag)
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          controller.scannerActive.value ? 'Align barcode within frame' : 'Processing...',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),

          // Details + Manual Input Section
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Obx(() {
                final bag = controller.bagDetails.value;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Image.asset(AppAssets.bagInventory, height: 24,),
                          const SizedBox(width: 12),
                          Text('Handover to Inventory',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Manual Input (only when no bag)
                      if (bag == null) ...[
                        TextField(
                          controller: controller.manualBarcodeController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Enter barcode manually',
                            prefixIcon: const Icon(Icons.qr_code_2),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              onPressed: () {
                                final value = controller.manualBarcodeController.text.trim();
                                if (value.isNotEmpty) controller.onManualBarcodeSubmit(value);
                              },
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                          ),
                          onSubmitted: (value) => controller.onManualBarcodeSubmit(value),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Placeholder
                      if (bag == null && !controller.isLoading.value)
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.qr_code_scanner, size: 90, color: theme.disabledColor.withOpacity(0.6)),
                              const SizedBox(height: 20),
                              Text('Scan or enter a bag code to handover',
                                  style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                            ],
                          ),
                        ),

                      // Bag Details
                      if (bag != null) ...[
                        _buildCompactRow('Bag Code', bag.bagcode, Icons.tag),
                        const SizedBox(height: 12),
                        _buildCompactRow('Category', bag.category, Icons.category),
                     
                        const SizedBox(height: 32),

                        // Handover Button
                        Obx(() => SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: controller.isSubmitting.value ? null : controller.handoverBag,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 6,
                            ),
                            child: controller.isSubmitting.value
                                ? const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                                : const Text('Handover Bag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        )),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: controller.resetScanner,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.primary, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text('Scan Another Bag',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
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

  // Reusable compact row (same as AcceptBag screen)
  Widget _buildCompactRow(String label, String value, IconData icon, {Color? color}) {
    final theme = Get.theme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (theme.brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100])!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color ?? theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


