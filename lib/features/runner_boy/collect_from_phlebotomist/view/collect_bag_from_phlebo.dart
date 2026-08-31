// views/collect_bag_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/componenents/info_row_widget.dart';
import 'package:lifenity_connect/constants/app_assets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../../../phlebotomist/accept_bag/view/widget/scanner_bottomsheet.dart';
import '../controller/collect_bag_from_phlebo_controller.dart';
import '../model/qr_bag_detail.dart';

class CollectBagFromPhlebotomistView extends StatelessWidget {
  CollectBagFromPhlebotomistView({super.key});

  final CollectBagFromPhlebotomistController controller =
  Get.put(CollectBagFromPhlebotomistController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Collect Bag From Phlebotomist',
        actions: [
          Obx(() => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: Icon(
                controller.flashEnabled.value ? Icons.flash_on : Icons.flash_off,
                color: controller.flashEnabled.value ? Colors.yellow : Colors.grey,
              ),
              onPressed: controller.toggleFlash,
            ),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.collectBagState.value == CollectBagState.processing) {
          return _buildProcessingView('Collecting Bag...', Icons.shopping_bag_outlined);
        }
        if (controller.collectBagState.value == CollectBagState.success) {
          return _buildCollectSuccessView();
        }
        if (controller.transferStep.value == TransferStep.transferring) {
          return _buildProcessingView('Transferring...', Icons.swap_horiz);
        }
        if (controller.transferStep.value == TransferStep.success) {
          return _buildTransferSuccessView();
        }

        return Column(
          children: [
            _buildTabSelector(),
            Expanded(
              child: PageView(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => controller.selectedTabIndex.value = index,
                children: [
                  _buildCollectBagFlow(context),
                  _buildTransferBagFlow(context),
                ],
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Tab Selector ──────────────────────────────────────────────────────────

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(() => Row(
        children: [
          _buildTabItem(
            title: 'Collect Bag',
            icon: Icons.shopping_bag_outlined,
            isSelected: controller.selectedTabIndex.value == 0,
            onTap: () => controller.switchTab(0),
          ),
          _buildTabItem(
            title: 'Transfer',
            icon: Icons.swap_horiz,
            isSelected: controller.selectedTabIndex.value == 1,
            onTap: () => controller.switchTab(1),
          ),
        ],
      )),
    );
  }

  Widget _buildTabItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18,
                  color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Collect Bag Flow ──────────────────────────────────────────────────────

  Widget _buildCollectBagFlow(BuildContext context) {
    return Obx(() {
      final hasBag = controller.scannedBagDetail.value != null;
      final isManualInput = controller.isManualInputActive.value;

      return Column(
        children: [
          // Collapsible Scanner
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: (hasBag || isManualInput)
                ? 100
                : MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular((hasBag || isManualInput) ? 20 : 0),
                  ),
                  child: MobileScanner(
                    controller: controller.scannerController,
                    onDetect: isManualInput
                        ? null
                        : (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode?.rawValue != null) {
                        controller.handleBarcodeScan(barcode!.rawValue!);
                      }
                    },
                  ),
                ),

                // Scanner overlay when expanded
                if (!hasBag && !isManualInput)
                  CustomPaint(
                    painter: ScannerOverlayPainter(),
                    child: const Center(
                        child: AnimatedScanLine(height: 250, width: 250)),
                  ),

                // Collapsed header when bag scanned or manual input active
                if (hasBag || isManualInput)
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
                          isManualInput ? Icons.keyboard : Icons.inventory_2,
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
                                isManualInput
                                    ? 'Manual Entry Mode'
                                    : 'Scanned: ${controller.scannedBagDetail.value!.bagcode}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                isManualInput
                                    ? 'Type barcode and press send'
                                    : 'Bag validated successfully',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: controller.resetCollect,
                        ),
                      ],
                    ),
                  ),

                // Loading overlay
                if (controller.isLoading.value)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),

                // Scan hint
                if (!hasBag && !isManualInput)
                  Positioned(
                    bottom: 0,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Align barcode within frame',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details section
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Manual input field — shown when no bag scanned yet
                    if (!hasBag)
                      TextField(
                        focusNode: controller.manualInputFocusNode,
                        controller: controller.collectBagcodeController, // ✅
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'Enter barcode manually',
                          prefixIcon: const Icon(Icons.qr_code_2),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: controller.onManualCollectSubmit, // ✅
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                        ),
                        onSubmitted: (_) => controller.onManualCollectSubmit(), // ✅
                      ),

                    if (!hasBag)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.qr_code_scanner,
                                  size: 90, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Scan or enter bag code to continue',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (hasBag)
                      _buildBagDetailsCard(controller.scannedBagDetail.value!), // ✅ QRBagCountDetail
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // ── Transfer Bag Flow ─────────────────────────────────────────────────────

  Widget _buildTransferBagFlow(BuildContext context) {
    return Obx(() {
      final step = controller.transferStep.value;
      final isScanning = step == TransferStep.scanningSource ||
          step == TransferStep.scanningDestination;

      return Column(
        children: [
          // Scanner — visible only when scanning
          if (isScanning)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: MediaQuery.of(context).size.height * 0.35,
              width: double.infinity,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: controller.scannerController,
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode?.rawValue != null) {
                        controller.handleBarcodeScan(barcode!.rawValue!);
                      }
                    },
                  ),
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.primary, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildIconButton(
                        Icons.close, controller.stopScanning),
                  ),
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
                      child: Text(
                        step == TransferStep.scanningSource
                            ? 'Scan Source Bag'
                            : 'Scan Destination Bag',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Transfer sections
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isScanning ? 0 : 30),
                  topRight: Radius.circular(isScanning ? 0 : 30),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTransferSection(
                      title: 'Phlebotomist Bag (From)',
                      icon: Icons.upload,
                      color: AppColors.primary,
                      bagDetail: controller.sourceBag.value,
                      textController: controller.sourceBagcodeController, // ✅
                      onScan: controller.startSourceScan,
                      onValidate: controller.validateSourceManual, // ✅
                      onClear: controller.clearSourceBag,
                      isValidated: controller.sourceBag.value != null,
                      isEnabled: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTransferArrow(),
                    const SizedBox(height: 16),
                    _buildTransferSection(
                      title: 'RB/Connector Bag (To)',
                      icon: Icons.download,
                      color: const Color(0xFF48BB78),
                      bagDetail: controller.destinationBag.value,
                      textController: controller.destinationBagcodeController, // ✅
                      onScan: controller.startDestinationScan,
                      onValidate: controller.validateDestinationManual, // ✅
                      onClear: controller.clearDestinationBag,
                      isValidated: controller.destinationBag.value != null,
                      isEnabled: controller.sourceBag.value != null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // ── Transfer Section ──────────────────────────────────────────────────────

  Widget _buildTransferSection({
    required String title,
    required IconData icon,
    required Color color,
    required QRBagCountDetail? bagDetail, // ✅ correct type
    required TextEditingController textController,
    required VoidCallback onScan,
    required VoidCallback onValidate,
    required VoidCallback onClear,
    required bool isValidated,
    bool isEnabled = true,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isValidated ? color : Colors.grey.shade200,
            width: isValidated ? 2 : 1,
          ),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (!isValidated) ...[
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                enabled: isEnabled,
                decoration: InputDecoration(
                  hintText: 'Enter or scan bag code',
                  prefixIcon:
                  const Icon(Icons.qr_code_rounded, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: isEnabled ? onValidate : null,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                ),
                onSubmitted: (_) => isEnabled ? onValidate() : null,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isEnabled ? onScan : null,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Bag'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: color, width: 2),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              _buildBagInfo(bagDetail!), // ✅ QRBagCountDetail
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Change Bag'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransferArrow() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_downward, color: AppColors.primary, size: 24),
      ),
    );
  }

  // ── Bag Detail Cards ──────────────────────────────────────────────────────

  Widget _buildBagDetailsCard(QRBagCountDetail bag) { // ✅
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Text('Bag Details',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildBagInfo(bag),
          ),
        ],
      ),
    );
  }

  Widget _buildBagInfo(QRBagCountDetail bag) { // ✅
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InfoRow(
                icon: AppAssets.fileNoteIcon,
                title: 'Bag Code',
                value: bag.bagcode,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InfoRow(
                icon: AppAssets.fileNoteIcon,
                title: 'Status',
                value: bag.isBagClosed ? 'Closed' : 'Open',
              ),
            ),
          ],
        ),
        const Divider(height: 20),
        Row(
          children: [
            Expanded(
              child: InfoRow(
                icon: AppAssets.fileNoteIcon,
                title: 'Tubes',
                value: bag.tubecount?.toString() ?? '—',
              ),
            ),
            const SizedBox(width: 8),
            if (bag.facilityName != null)
              Expanded(
                child: InfoRow(
                  icon: AppAssets.fileNoteIcon,
                  title: 'Facility',
                  value: bag.facilityName!,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Obx(() {
      final collectState = controller.collectBagState.value;
      final transferStep = controller.transferStep.value;

      if (collectState == CollectBagState.processing ||
          collectState == CollectBagState.success ||
          transferStep == TransferStep.transferring ||
          transferStep == TransferStep.success ||
          transferStep == TransferStep.scanningSource ||
          transferStep == TransferStep.scanningDestination) {
        return const SizedBox();
      }

      if (controller.selectedTabIndex.value == 0 &&
          controller.scannedBagDetail.value != null) {
        return _buildActionBar(
          label: 'Collect Bag',
          icon: Icons.inventory_2_outlined,
          onPressed: controller.collectBag,
        );
      }

      if (controller.selectedTabIndex.value == 1 &&
          controller.sourceBag.value != null &&
          controller.destinationBag.value != null) {
        return _buildActionBar(
          label: 'Execute Transfer',
          icon: Icons.swap_horiz,
          onPressed: controller.isTransferring.value
              ? null
              : controller.executeTransfer,
          isLoading: controller.isTransferring.value,
        );
      }

      return const SizedBox();
    });
  }

  Widget _buildActionBar({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
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
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Icon(icon),
            label: Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
          icon: Icon(icon, color: Colors.white), onPressed: onPressed),
    );
  }

  // ── Success Views ─────────────────────────────────────────────────────────

  Widget _buildCollectSuccessView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSuccessIcon(),
              const SizedBox(height: 32),
              const Text('Bag Collected Successfully!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1F36)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (controller.scannedBagDetail.value != null)
                _buildSuccessSummaryCard(
                  label: 'Collected Bag',
                  bag: controller.scannedBagDetail.value!,
                  color: AppColors.primary,
                  icon: Icons.inventory_2_outlined,
                ),
              const SizedBox(height: 32),
              _buildResetButton(
                  label: 'Collect Another Bag',
                  onPressed: controller.reset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransferSuccessView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSuccessIcon(),
              const SizedBox(height: 32),
              const Text('Transfer Completed!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1F36)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Tubes successfully transferred',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 32),
              if (controller.sourceBag.value != null)
                _buildSuccessSummaryCard(
                  label: 'From',
                  bag: controller.sourceBag.value!,
                  color: AppColors.primary,
                  icon: Icons.upload,
                ),
              const SizedBox(height: 12),
              Icon(Icons.arrow_downward,
                  color: Colors.grey.shade400, size: 28),
              const SizedBox(height: 12),
              if (controller.destinationBag.value != null)
                _buildSuccessSummaryCard(
                  label: 'To',
                  bag: controller.destinationBag.value!,
                  color: const Color(0xFF48BB78),
                  icon: Icons.download,
                ),
              const SizedBox(height: 32),
              _buildResetButton(
                  label: 'New Transfer', onPressed: controller.reset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessSummaryCard({
    required String label,
    required QRBagCountDetail bag, // ✅
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const Divider(height: 20),
          InfoRow(
              icon: AppAssets.fileNoteIcon,
              title: 'Bag Code',
              value: bag.bagcode),
          if (bag.tubecount != null) ...[
            const SizedBox(height: 8),
            InfoRow(
                icon: AppAssets.fileNoteIcon,
                title: 'Tubes',
                value: bag.tubecount.toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle,
                size: 60, color: Colors.green.shade500),
          ),
        );
      },
    );
  }

  Widget _buildResetButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_circle_outline),
        label: Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildProcessingView(String title, IconData icon) {
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Icon(icon,
                          size: 50,
                          color: AppColors.primary.withOpacity(0.8)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1F36))),
            const SizedBox(height: 12),
            Text('Please wait',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

