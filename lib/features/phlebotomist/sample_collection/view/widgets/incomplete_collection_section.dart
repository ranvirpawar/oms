// incomplete_collection_section.dart
//
// Renders one block per sample marked "Not Collected": a reason table
// (single-select, Yes/No styled per the reference screenshot) and a
// remarks field. Only shown when at least one sample is incomplete.

import 'package:flutter/material.dart';
import 'package:get/get.dart';


import '../../../../../theme/app_colors.dart';
import '../../controller/sample_collection_controller.dart';
import '../../model/sample_collection_models.dart';

class IncompleteCollectionSection extends StatelessWidget {
  final SampleCollectionController controller;

  const IncompleteCollectionSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final incomplete = controller.incompleteEntries;
      if (incomplete.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(top: 4, bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.redText.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppColors.redText),
                  SizedBox(width: 8),
                  Text(
                    'Samples not collected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            for (final entry in incomplete)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: _IncompleteEntryBlock(
                  entry: entry,
                  controller: controller,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _IncompleteEntryBlock extends StatelessWidget {
  final SampleBarcodeEntry entry;
  final SampleCollectionController controller;

  const _IncompleteEntryBlock({required this.entry, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.sampleType,
            style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const Text(
            'Sample is not collected, please select the reason.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 10),
          _buildReasonTable(),
          const SizedBox(height: 10),
          _buildRemarksField(),
        ],
      ),
    );
  }

  Widget _buildReasonTable() {
    return Obx(() {
      final selected = entry.selectedReason.value;
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            Container(
              color: AppColors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text('Reason',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Select',
                        textAlign: TextAlign.end,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
            ),
            for (final reason in controller.incompleteReasonOptions)
              Container(
                color: AppColors.bgCard,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        reason.reason,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _YesNoPill(
                            label: 'Yes',
                            isActive: selected?.reasonId == reason.reasonId,
                            activeColor: AppColors.greenText,
                            onTap: () =>
                                controller.selectIncompleteReason(entry, reason),
                          ),
                          const SizedBox(width: 6),
                          _YesNoPill(
                            label: 'No',
                            isActive: selected?.reasonId != reason.reasonId,
                            activeColor: AppColors.redText,
                            onTap: () {
                              if (selected?.reasonId == reason.reasonId) {
                                entry.selectedReason.value = null;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildRemarksField() {
    return TextField(
      controller: entry.remarksController,
      maxLines: 2,
      style: const TextStyle(fontSize: 12.5),
      decoration: InputDecoration(
        hintText: 'Remarks (optional)',
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

class _YesNoPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _YesNoPill({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : AppColors.grayLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? activeColor : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive
                  ? (label == 'Yes' ? Icons.check_rounded : Icons.close_rounded)
                  : (label == 'Yes' ? Icons.check_rounded : Icons.close_rounded),
              size: 12,
              color: isActive ? activeColor : AppColors.textMuted,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? activeColor : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
