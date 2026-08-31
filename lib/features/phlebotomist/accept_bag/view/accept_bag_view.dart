// accept_bag_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_assets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/animations/success_check_animation.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../controller/accept_bag_controller.dart';
import '../model/accept_bag_model.dart';

import 'package:flutter_svg/flutter_svg.dart';
class AcceptBagView extends StatelessWidget {
  AcceptBagView({super.key});

  final AcceptBagController controller = Get.put(AcceptBagController());

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Cleanup controller when user pops the screen
        debugPrint('🔙 Popping AcceptBagView, cleaning up controller');
        Get.delete<AcceptBagController>();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: const CustomAppBar(
          title: 'Accept Assigned Bags',

        ),
        body: RefreshIndicator(
          onRefresh: controller.fetchAssignedBags,

          child: Obx(() {
            if (controller.acceptBagState.value == AcceptBagState.processing) {
              return _buildProcessingView();
            } else if (controller.acceptBagState.value == AcceptBagState.success) {
              return _buildSuccessView();
            }
            return _buildMainView(context);
          }),
        ),
      ),
    );
  }

  Widget _buildMainView(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.fetchAssignedBags,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildAssignedBagsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedBagsList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.assignedBagsList.isEmpty) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(40),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No Assigned Bags',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Assigned bags will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: controller.fetchAssignedBags,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.asset(
                      AppAssets.medicalUnitIcon,
                      colorFilter: const ColorFilter.mode(
                          AppColors.primary, BlendMode.srcIn),
                      height: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Assigned Bags (${controller.assignedBagsList.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: controller.assignedBagsList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bag = controller.assignedBagsList[index];
                return _buildBagCard(bag, index);
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBagCard(AssignedBag bag, int index) {
    return GestureDetector(
      onTap: () => controller.selectBagAndScan(bag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E6ED)),
        ),
        child: Row(
          children: [
            // Serial number circle on left
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Bag info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bag.bagcode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppAssets.calendarClockIcon,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                            AppColors.primary, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        bag.formattedDateTime,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scanner icon on right
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    backgroundColor: Color(0xFFE0E6ED),
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 50,
                        color: const Color(0xFF4F46E5).withOpacity(0.8),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Accepting Bag...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Text(
              'Processing ${controller.selectedBag.value?.bagcode ?? ""}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SuccessCheckAnimation(),
            const SizedBox(height: 32),
            const Text(
              'Bag Accepted Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1F36),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Obx(
                  () => Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E6ED)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bag Code',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          controller.scannedBarcode.value,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF1A1F36),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction ID',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${controller.scannedTransaction.value?.transactionId ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Auto-dismiss message
            Text(
              'Returning to list in a moment...',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*class AcceptBagView extends StatelessWidget {
  AcceptBagView({super.key});

  final AcceptBagController controller = Get.put(AcceptBagController());

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Cleanup controller when user pops the screen
        debugPrint('🔙 Popping AcceptBagView, cleaning up controller');

        Get.delete<AcceptBagController>();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: CustomAppBar(
          title: 'Accept Assigned Bags',
          // Optional: Add manual cleanup on back button
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              Get.delete<AcceptBagController>();
              Get.back();
            },
          ),
        ),
        body: Obx(() {
          if (controller.acceptBagState.value == AcceptBagState.processing) {
            return _buildProcessingView();
          } else if (controller.acceptBagState.value ==
              AcceptBagState.success) {
            return _buildSuccessView();
          }

          return _buildMainView(context);
        }),
        bottomNavigationBar: Obx(() {
          if (controller.acceptBagState.value == AcceptBagState.processing) {
            return const SizedBox();
          } else if (controller.acceptBagState.value ==
              AcceptBagState.success) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.reset();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add),
                      const SizedBox(width: 8),
                      const Text(
                        'Accept Another Bag',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const SizedBox();
        }),
      ),
    );
  }

  Widget _buildMainView(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.fetchAssignedBags,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Assigned Bags List
            _buildAssignedBagsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedBagsList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.assignedBagsList.isEmpty) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No Assigned Bags',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Assigned bags will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: controller.fetchAssignedBags,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.asset(
                      AppAssets.medicalUnitIcon,
                      colorFilter: const ColorFilter.mode(
                          AppColors.primary, BlendMode.srcIn),
                      height: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Assigned Bags (${controller.assignedBagsList.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: controller.assignedBagsList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bag = controller.assignedBagsList[index];
                return _buildBagCard(bag, index);
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBagCard(AssignedBag bag, int index) {
    return GestureDetector(
      onTap: () => controller.selectBagAndScan(bag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E6ED)),
        ),
        child: Row(
          children: [
            // Serial number circle on left
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Bag info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bag.bagcode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppAssets.calendarClockIcon,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                            AppColors.primary, BlendMode.srcIn),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        bag.formattedDateTime,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scanner icon on right
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.qr_code_scanner,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildProcessingView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    backgroundColor: const Color(0xFFE0E6ED),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 50,
                        color: const Color(0xFF4F46E5).withOpacity(0.8),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Accepting Bag...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Text(
                  'Processing ${controller.selectedBag.value?.bagcode ?? ""}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SuccessCheckAnimation(),
            const SizedBox(height: 32),
            const Text(
              'Bag Accepted Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1F36),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Obx(
              () => Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E6ED)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bag Code',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          controller.selectedBag.value?.bagcode ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF1A1F36),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction ID',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${controller.selectedBag.value?.transactionId ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class ScannerOverlay extends StatelessWidget {
  final AcceptBagController controller;

  const ScannerOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Check if scanner controller is available
    if (controller.scannerController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: controller.scannerController!,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  controller.handleBarcodeScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Scanner overlay
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Center(
              child: AnimatedScanLine(
                height: 200,
                width: 200,
              ),
            ),
          ),

          // Controls
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                children: [
                  _buildIconButton(
                    Icons.flash_on,
                    controller.toggleFlash,
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    Icons.close,
                    controller.stopScanning,
                  ),
                ],
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Scan bag QR code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                      'Scanning: ${controller.selectedBag.value?.bagcode ?? ""}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}*/


