import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../theme/app_colors.dart';
import '../../controller/invoice_tracking_controller.dart';

class StageSelectionBottomSheet extends StatelessWidget {
  final InvoiceTrackingController controller;

  const StageSelectionBottomSheet({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Next Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      /*SizedBox(height: 2),
                      Text(
                        'Choose the next status to update',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),*/
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey[200]),

          // Current Status Banner
          Obx(() {
            final currentStatus =
                controller.selectedInvoice.value?.processDescription;
            if (currentStatus == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Status',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentStatus,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Stage List
          Flexible(
            child: Obx(() {
              final stages = controller.stages;
              final nextStageId = controller.nextStage.value?.processId;

              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: stages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final stage = stages[index];
                  final sortedStages = controller.stages.toList()
                    ..sort((a, b) => a.processId.compareTo(b.processId));
                  final nextPendingId = sortedStages.first.processId;

                  final bool isTeamLead = controller.isTeamLeadLogin.value;
                  final bool isNextStage = stage.processId == nextPendingId;
                  final bool isStage3 = stage.processId == 3;

                  // Decide if this stage is selectable
                  final bool isSelectable = isTeamLead
                      ? isNextStage // Team Lead: only next in line
                      : (isStage3 &&
                          isNextStage); // Others: only stage 3 AND it's next

                  final bool isLocked = !isSelectable;

                  return GestureDetector(
                    onTap: isLocked
                        ? null
                        : () => controller.selectStageFromBottomSheet(stage),
                    child: Opacity(
                      opacity: isLocked ? 0.8 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isNextStage
                              ? AppColors.primary.withOpacity(0.08)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isNextStage
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: isNextStage ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Circle badge
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isNextStage
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isNextStage
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stage.processDescription,
                                    style: TextStyle(
                                      fontWeight: isNextStage
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (isNextStage && isTeamLead)
                                        _badge('Update', Colors.green),
                                      /*if (isNextStage &&
                                          !isTeamLead &&
                                          isStage3)
                                        _badge("Your Task", Colors.blue),*/
                                      if (!isSelectable &&
                                          !isTeamLead &&
                                          !isStage3)
                                        _badge('Locked', Colors.red),
                                      if (stage.processId == 24)
                                        _badge('Team Lead Only', Colors.orange),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isSelectable)
                              const Icon(Icons.chevron_right,
                                  color: AppColors.primary)
                            else
                              Icon(Icons.lock_outline,
                                  color: Colors.grey.shade500, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          // color: color.shade700,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Subtle pulse animation for the active stage
class _PulseAnimation extends StatefulWidget {
  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 0.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(_animation.value),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}
