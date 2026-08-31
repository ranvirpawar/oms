// views/handover_phlebotomist_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/view/widgets/custom_dropdown.dart';
import 'package:lifenity_connect/utils/animations/success_check_animation.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../constants/app_assets.dart';
import '../../../../theme/app_colors.dart';
import '../../collect_empty_bag/view/widget/animated_scan_line.dart';
import '../controller/handover_phlebotomist_controller.dart';
import '../model/bag_transaction_model.dart';


class HandoverPhlebotomistView extends StatelessWidget {
  HandoverPhlebotomistView({super.key});

  final HandoverPhlebotomistController controller =
      Get.put(HandoverPhlebotomistController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(title: 'Handover to Phlebotomist'),
      body: Obx(() {
        if (controller.handoverState.value == HandoverState.processing &&
            controller.handoverProgress.value > 0) {
          return _buildProcessingView();
        } else if (controller.handoverState.value == HandoverState.success) {
          return _buildSuccessView();
        }

        return _buildMainView(context);
      }),
      bottomNavigationBar: Obx(() {
        if (controller.handoverState.value == HandoverState.processing) {
          return const SizedBox();
        } else if (controller.handoverState.value == HandoverState.success) {
          // button to add new entry after success
          return    Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:(){
                  // delete controller and get back
                  controller.reset();

                },

                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send),
                    SizedBox(width: 8),
                    Text(
                      'Hand Over New Bag',
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
        return _buildBottomBar();
      }),
    );
  }

  Widget _buildMainView(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Phlebotomist Selection Section
          _buildPhlebotomistSection(),

          const SizedBox(height: 0),

          // Scanner Section
          Obx(() => controller.isScanning.value
              ? _buildScannerSection()
              : _buildManualEntrySection()),

          const SizedBox(height: 16),

          // Scanned Bags List
          _buildScannedBagsList(),

          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildPhlebotomistSection() {
    return Container(
      margin: const EdgeInsets.all(16),
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
                    AppAssets.nurseIcon,
                    colorFilter: const ColorFilter.mode(
                        AppColors.primary, BlendMode.srcIn),
                    height: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Assign to Phlebotomist',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.phlebotomistList.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Icon(Icons.person_off_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No phlebotomists available',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: controller.fetchPhlebotomistList,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  CustomDropdown(
                    label: 'Select Phlebotomist',
                    value:
                        controller.selectedPhlebotomist.value?.userName ?? '',
                    items: controller.phlebotomistList
                        .map((e) => e.userName)
                        .toList(),
                    onChanged: (value) {
                      if (value != null && value.isNotEmpty) {
                        final selectedPhlebotomist =
                            controller.phlebotomistList.firstWhere(
                          (phlebotomist) => phlebotomist.userName == value,
                        );
                        controller.selectPhlebotomist(selectedPhlebotomist);
                        debugPrint(
                          'Selected Phlebotomist: ${selectedPhlebotomist.userName}, ID: ${selectedPhlebotomist.userId}',
                        );
                      }
                    },
                    iconPath: AppAssets.userIcon,
                    // or use your actual icon path
                    isRequired: true,
                  ),

                  // Show selected phlebotomist details
                  Obx(() {
                    final selected = controller.selectedPhlebotomist.value;
                    if (selected == null) return const SizedBox();

                    return Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Icons.location_city_outlined,
                            'Facility',
                            selected.facilityName,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.map_outlined,
                            'Ward',
                            selected.ward,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.business_outlined,
                            'Type',
                            selected.fType,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        SvgPicture.asset(AppAssets.facility,
            height: 16,
            colorFilter: const ColorFilter.mode(
              AppColors.primary,
              BlendMode.srcIn,
            )),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 350,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            MobileScanner(
              controller: controller.scannerController,
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


          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: const Center(
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

            // Instructions
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Scan bag QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildManualEntrySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(
                  AppAssets.barcodeIcon,
                  colorFilter: const ColorFilter.mode(
                      AppColors.primary, BlendMode.srcIn),
                  height: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Scan Bag',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller.barcodeController,
            decoration: const InputDecoration(
              hintText: 'Enter bag barcode',
              prefixIcon: Icon(Icons.qr_code_rounded),
            ),
            onSubmitted: (_) => controller.processManualBarcode(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.startScanning,
                  child: const Text('Scan Qr Code'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.processManualBarcode,
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannedBagsList() {
    return Obx(() {
      if (controller.scannedBags.isEmpty) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No bags scanned yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan a bag to add it ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Scanned Bags (${controller.scannedBags.length})',
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
              itemCount: controller.scannedBags.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bag = controller.scannedBags[index];
                return _buildBagCard(bag);
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBagCard(BagTransaction bag) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E6ED)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(8),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bag.bagcode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${bag.category} • Capacity: ${bag.capacity}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => controller.removeBag(bag),
                  icon: Icon(
                    Icons.close,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.scannedBags.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Bags',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${controller.scannedBags.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.canHandover()
                    ? controller.performHandover
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send),
                    const SizedBox(width: 8),
                    Text(
                      controller.canHandover()
                          ? 'Handover Bags (${controller.scannedBags.length})'
                          : 'Handover Bags',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
                Obx(() => SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: controller.handoverProgress.value,
                        strokeWidth: 6,
                        backgroundColor: const Color(0xFFE0E6ED),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4F46E5)),
                      ),
                    )),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Icon(
                        Icons.local_shipping_outlined,
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
              'Handing Over Bags...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Text(
                  'Processing ${(controller.handoverProgress.value * controller.scannedBags.length).ceil()} of ${controller.scannedBags.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                )),
            const SizedBox(height: 24),
            Obx(() => Text(
                  'To: ${controller.selectedPhlebotomist.value?.userName ?? ""}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600,
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
              'Handover Successful!',
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
                          'Bags Handed Over',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${controller.scannedBags.length}',
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
                          'Handed to',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          controller.selectedPhlebotomist.value?.userName ?? '',
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

// Reuse scanner painters from previous implementation
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanAreaSize = 200.0;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final bracketPaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bracketLength = 30.0;

    canvas.drawLine(
        Offset(left, top + bracketLength), Offset(left, top), bracketPaint);
    canvas.drawLine(
        Offset(left, top), Offset(left + bracketLength, top), bracketPaint);
    canvas.drawLine(Offset(left + scanAreaSize - bracketLength, top),
        Offset(left + scanAreaSize, top), bracketPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top),
        Offset(left + scanAreaSize, top + bracketLength), bracketPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize - bracketLength),
        Offset(left, top + scanAreaSize), bracketPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize),
        Offset(left + bracketLength, top + scanAreaSize), bracketPaint);
    canvas.drawLine(
        Offset(left + scanAreaSize - bracketLength, top + scanAreaSize),
        Offset(left + scanAreaSize, top + scanAreaSize),
        bracketPaint);
    canvas.drawLine(
        Offset(left + scanAreaSize, top + scanAreaSize - bracketLength),
        Offset(left + scanAreaSize, top + scanAreaSize),
        bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


