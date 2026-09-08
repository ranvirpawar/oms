// complication_section.dart
//
// Yes/No complication list. Options + IDs come from
// SampleCollectionController.complicationOptions (API-sourced); selections
// are stored per ComplicationID in complicationSelections.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../theme/app_colors.dart';
import '../../controller/sample_collection_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../theme/app_colors.dart';
import '../../controller/sample_collection_controller.dart';

class ComplicationSection extends StatelessWidget {
  final SampleCollectionController controller;

  const ComplicationSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.complicationOptions.isEmpty) {
        return const SizedBox.shrink();
      }

      final expanded = controller.complicationsExpanded.value;
      final selectedCount = controller.selectedComplicationsCount;

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
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                HapticFeedback.lightImpact();
                controller.toggleComplicationsExpanded();
              },
              child: Row(
                children: [
                  _ExpandIndicator(expanded: expanded, hasSelections: selectedCount > 0),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Any complications during collection?',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedCount == 0
                              ? 'Optional — tap to add if any occurred'
                              : '$selectedCount recorded',
                          style: TextStyle(
                            fontSize: 11,
                            color: selectedCount == 0 ? AppColors.textMuted : AppColors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
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
              )
                  : const SizedBox.shrink(),
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
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
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

/// Modern checkbox-style expand/collapse indicator, replacing the static
/// medical icon. Fills in when at least one complication has been recorded.
class _ExpandIndicator extends StatelessWidget {
  final bool expanded;
  final bool hasSelections;
  const _ExpandIndicator({required this.expanded, required this.hasSelections});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: hasSelections ? AppColors.blue.withOpacity(0.12) : AppColors.grayLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasSelections ? AppColors.blue : AppColors.border,
          width: 1.4,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedRotation(
        turns: expanded ? 0.5 : 0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Icon(
          hasSelections ? Icons.check_rounded : Icons.expand_more_rounded,
          size: 16,
          color: hasSelections ? AppColors.blue : AppColors.textMuted,
        ),
      ),
    );
  }
}

/*class ComplicationSection extends StatelessWidget {
  final SampleCollectionController controller;

  const ComplicationSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.complicationOptions.isEmpty) {
        return const SizedBox.shrink();
      }

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
                    style: TextStyle(
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
}*/
