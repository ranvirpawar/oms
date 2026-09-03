// complication_section.dart
//
// Yes/No complication list. Options + IDs come from
// SampleCollectionController.complicationOptions (API-sourced); selections
// are stored per ComplicationID in complicationSelections.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../theme/app_colors.dart';
import '../../controller/sample_collection_controller.dart';

class ComplicationSection extends StatelessWidget {
  final SampleCollectionController controller;

  const ComplicationSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.complicationOptions.isEmpty)
        return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 18,
                  color: AppColors.blue,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Record any complications during collection?',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final option in controller.complicationOptions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.name,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    _yesNoToggle(option.complicationId),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _yesNoToggle(int complicationId) {
    final selected = controller.complicationSelections[complicationId];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _toggleButton(
          label: 'Yes',
          isActive: selected == true,
          color: AppColors.greenText,
          onTap: () => controller.setComplication(complicationId, true),
        ),
        const SizedBox(width: 6),
        _toggleButton(
          label: 'No',
          isActive: selected == false,
          color: AppColors.redText,
          onTap: () => controller.setComplication(complicationId, false),
        ),
      ],
    );
  }

  Widget _toggleButton({
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : AppColors.grayLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isActive ? color : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
