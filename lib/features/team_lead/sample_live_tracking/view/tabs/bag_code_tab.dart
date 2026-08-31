import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';
import '../../controller/live_tracking_controller.dart';
import '../widgets/bag_card.dart';

class BagsTab extends GetView<LiveTrackingController> {
  const BagsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: TextField(
              onChanged: controller.setBagSearch,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Search bag code or contact name…',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // ── Filter chips — built entirely from live bag statuses ────────────
        SizedBox(
          height: 44,
          child: Obx(() {
            final filters = controller.bagStatusFilters;

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {


                return Obx(() {
                  final f = filters[i];
                  final count = controller.bagChipCount(f);
                  final isActive = controller.activeBagFilter.value == f;
                  final isAttention = f == 'Attention';
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        controller.setBagFilter(f);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isAttention ? AppColors.redText : AppColors.primary)
                              : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? (isAttention ? AppColors.redText : AppColors.primary)
                                : (isAttention ? AppColors.redBorder : AppColors.border),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isAttention) ...[
                              Icon(Icons.warning_amber_rounded, size: 12, color: isActive ? Colors.white : AppColors.redText),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              f,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isActive ? Colors.white : (isAttention ? AppColors.redText : AppColors.textSecondary),
                              ),
                            ),
                            if (count > 0 && f != 'All') ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.white.withOpacity(0.25) : AppColors.bgCardAlt,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isActive ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                );
              },
            );
          }),
        ),

        // ── Bag list (attention-needed sorted first) ─────────────────────────
        Expanded(
          child: Obx(() {
            final list = controller.filteredBags;

            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: 8),
                    Text('No bags found', style: AppTextStyles.bodySecondary),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: controller.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                itemCount: list.length,
                itemBuilder: (_, i) => BagCard(bag: list[i], controller: controller),
              ),
            );
          }),
        ),
      ],
    );
  }
}