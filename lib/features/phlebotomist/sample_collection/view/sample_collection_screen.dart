// sample_collection_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/complication_section.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/sample_item_card.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../theme/app_colors.dart';
import '../controller/sample_collection_controller.dart';
import 'widgets/active_bag_card.dart';

class SampleCollectionScreen extends GetView<SampleCollectionController> {
  const SampleCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: const CustomAppBar(title: 'Sample Collection'),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              // Which bag the phlebotomist is collecting into — shows the
              // open bag's live capacity and lets them switch bags.
              ActiveBagCard(controller: controller),
              const SizedBox(height: 14),
              // No outer Obx needed anymore — _ProgressSummary observes its
              // own reactive counts internally (see fix below).
              _ProgressSummary(controller: controller),
              const SizedBox(height: 14),
              Obx(
                () => Column(
                  children: [
                    for (final entry in controller.sampleEntries)
                      SampleItemCard(entry: entry, controller: controller),
                  ],
                ),
              ),
              // IncompleteCollectionSection(controller: controller),
              ComplicationSection(controller: controller),
              _NotesCard(controller: controller),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SubmitBar(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final SampleCollectionController controller;

  const _ProgressSummary({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowSm,
      ),

      child: Obx(() {
        final total = controller.sampleEntries.length;
        return Row(
          children: [
            _summaryChip(
              'Collected',
              controller.collectedCount,
              AppColors.greenText,
            ),
            _divider(),
            _summaryChip(
              'Not Collected',
              controller.incompleteCount,
              AppColors.redText,
            ),
            _divider(),
            _summaryChip(
              'Pending',
              controller.pendingCount,
              AppColors.textMuted,
            ),
            _divider(),
            _summaryChip('Total', total, AppColors.textPrimary),
          ],
        );
      }),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: AppColors.border);

  Widget _summaryChip(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final SampleCollectionController controller;

  const _NotesCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Remarks',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.notesController,
            maxLines: 3,
            style: const TextStyle(fontSize: 12.5),
            decoration: InputDecoration(
              hintText: 'Add any notes about this collection (optional)',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.grayLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final SampleCollectionController controller;

  const _SubmitBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              elevation: 0,
            ),
            onPressed: controller.isSubmitting.value
                ? null
                : () async {
                    await controller.submitAndShowResult();
                  },
            child: controller.isSubmitting.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
