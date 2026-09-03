// sample_item_card.dart
//
// One card per required sample type on the Sample Collection screen.
// Reuses the existing CFormTextField pattern for barcode entry, with a
// scan-icon suffix that opens the shared MobileScanner bottom sheet from
// SampleCollectionController.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../componenents/c_textformfeild.dart';
import '../../../../../constants/app_assets.dart';
import '../../../../../theme/app_colors.dart';

import '../../controller/sample_collection_controller.dart';
import '../../model/sample_collection_models.dart';

class SampleItemCard extends StatelessWidget {
  final SampleBarcodeEntry entry;
  final SampleCollectionController controller;

  const SampleItemCard({
    super.key,
    required this.entry,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = entry.status.value;
      final borderColor = switch (status) {
        SampleCollectionStatus.collected => AppColors.greenBorder,
        SampleCollectionStatus.incomplete => AppColors.redText,
        SampleCollectionStatus.pending => AppColors.border,
      };

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: status == SampleCollectionStatus.pending ? 1 : 1.4),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.getBarcodeLabel(entry),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 10),
            if (status == SampleCollectionStatus.incomplete)
              _buildIncompleteBanner(context)
            else
              _buildBarcodeInput(context),
          ],
        ),
      );
    });
  }

  Widget _buildBarcodeInput(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CFormTextField(
            controller: entry.barcodeController,
            label: 'Barcode',
            iconPath: AppAssets.barcodeIcon,
            isRequired: true,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
            maxLength: 30,
            suffix: IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded,
                  color: AppColors.blue),
              onPressed: () => controller.openBarcodeScanner(entry),
            ),
            onChanged: (value) => controller.onBarcodeChanged(entry, value),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 26),
          child: TextButton(
            onPressed: () => controller.markAsNotCollected(entry),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.redText,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text(
              'Not\nCollected',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncompleteBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.redLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.redText),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sample not collected. Reason required below.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => controller.undoNotCollected(entry),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Undo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SampleCollectionStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, border, fg, icon) = switch (status) {
      SampleCollectionStatus.collected => (
          'Collected',
          AppColors.greenLight,
          AppColors.greenBorder,
          AppColors.greenText,
          Icons.check_circle_rounded,
        ),
      SampleCollectionStatus.incomplete => (
          'Not Collected',
          AppColors.redLight,
          AppColors.redText,
          AppColors.redText,
          Icons.cancel_rounded,
        ),
      SampleCollectionStatus.pending => (
          'Pending',
          AppColors.grayLight,
          AppColors.border,
          AppColors.textMuted,
          Icons.radio_button_unchecked_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}
