import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../theme/app_colors.dart';
import '../../../patient_registration/bag_status_dashboard/view/scan_bag_page.dart';
import '../../controller/sample_collection_controller.dart';
import 'active_bag_card.dart';

class BagContextBanner extends StatelessWidget {
  final SampleCollectionController controller;

  const BagContextBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Obx(() {
          final bag = controller.bagController;
          // Hide while the very first session fetch is still in flight.
          if (bag.isLoading.value && !bag.hasBags) return const SizedBox.shrink();

          if (!controller.hasOpenBag) {
            // Closed assigned bags can be reopened — don't force the phlebo
            // through the new-bag scan flow when their own bag just needs
            // reopening.
            final closedSessions = bag.allSessions.where((s) => !s.isOpen).toList();
            final message = closedSessions.isEmpty
                ? 'No open bag — open one so samples can be tagged to it.'
                : closedSessions.length == 1
                ? 'Bag ${closedSessions.first.bagcode} is closed — reopen it '
                'so samples can be tagged to it.'
                : 'No open bag — reopen one of your closed bags to continue.';

            return Column(
              children: [

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.amberLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.amberBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: AppColors.amberText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (closedSessions.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            if (closedSessions.length == 1) {
                              confirmOpenBag(context, closedSessions.first);
                            } else {
                              showBagPicker(context, controller);
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary800,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text(
                            'Reopen',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () => Get.to(() => const ScanBagPage()),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary800,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                        ),
                        child: Text(
                          closedSessions.isEmpty ? 'Open' : 'New',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          final ratio = controller.bagFillRatio;
          final color = ratio >= 0.9
              ? AppColors.redText
              : (ratio >= 0.6 ? AppColors.amberText : AppColors.greenText);
          final pct = (ratio * 100).round().clamp(0, 100).toInt();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.emerald200),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collecting into ${controller.activeBagcode.isEmpty ? 'Bag #${controller.activeBagId}' : controller.activeBagcode}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        controller.bagCapacity > 0
                            ? '${controller.bagUsed} of ${controller.bagCapacity} slots used'
                            : 'Open session',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.bagCapacity > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}