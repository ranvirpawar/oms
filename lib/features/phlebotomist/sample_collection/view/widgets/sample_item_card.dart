// sample_item_card.dart
//
// One card per required sample type on the Sample Collection screen.
// Reuses the existing CFormTextField pattern for barcode entry, with a
// scan-icon suffix that opens the shared MobileScanner bottom sheet from
// SampleCollectionController.

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../../theme/app_colors.dart';

import '../../controller/sample_collection_controller.dart';

import '../../model/sample_stype_style.dart';

import 'barcode_input_field.dart';

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
      final style = SampleTypeStyles.forType(entry.sampleType);
      final borderColor = switch (status) {
        SampleCollectionStatus.collected => AppColors.greenBorder,
        SampleCollectionStatus.incomplete => AppColors.redText,
        SampleCollectionStatus.pending => AppColors.border,
      };

      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: status == SampleCollectionStatus.pending ? 1 : 1.4,
          ),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: style.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: sampleTypeIcon(entry.sampleType, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.sampleType,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (entry.volumeRequiredMl.trim().isNotEmpty)
                        Text(
                          '${entry.volumeRequiredMl.trim()} required',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            if (status == SampleCollectionStatus.incomplete)
              _buildIncompleteBanner(context)
            else
              _buildBarcodeRow(),
          ],
        ),
      );
    });
  }

  Widget _buildBarcodeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BarcodeInputField(
            controller: entry.barcodeController,
            onScanTap: () => controller.openBarcodeScanner(entry),
            onChanged: (value) => controller.onBarcodeChanged(entry, value),
          ),
        ),
        const SizedBox(width: 8),
        _NotCollectedButton(onTap: () => controller.markAsNotCollected(entry)),
      ],
    );
  }

  Widget _buildIncompleteBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.redLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.redText,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Not collected — choose a reason below.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => controller.undoNotCollected(entry),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Undo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact 44x44 icon action — replaces the old two-line "Not\nCollected"
/// text button. Apple-style: soft tinted background, single glyph, tooltip
/// for discoverability instead of a wordy label.
class _NotCollectedButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NotCollectedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Mark as not collected',
      child: Material(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.remove_circle_outline_rounded,
              size: 19,
              color: AppColors.redText,
            ),
          ),
        ),
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
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
