import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/constants/app_assets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../controller/collected_bags_controller.dart';
import '../model/collected_bag_model.dart';
import 'handover_bag_view.dart';

class CollectedBagsView extends StatelessWidget {
  CollectedBagsView({super.key});

  final CollectedBagsController controller = Get.put(CollectedBagsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: CustomAppBar(
        title: 'Collected Bags',
        actions: [
          Obx(() => controller.hasSelection
              ? IconButton(
                  icon: const Icon(Icons.deselect, color: AppColors.surfaceContainer),
                  tooltip: 'Clear selection',
                  onPressed: controller.clearSelection,
                )
              : const SizedBox()),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.surfaceContainer),
            onPressed: controller.fetchBags,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.submissionState.value == SubmissionState.processing) {
          return _buildProcessingView();
        }
        return _buildMainView(context);
      }),
      bottomNavigationBar: Obx(() {
        if (controller.submissionState.value == SubmissionState.processing) {
          return const SizedBox.shrink();
        }
        return _buildBottomBar(context);
      }),
    );
  }

  // ─────────────────────────────────────────
  // MAIN BODY
  // ─────────────────────────────────────────

  Widget _buildMainView(BuildContext context) {
    return Column(
      children: [
        _buildSelectionHeader(),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.filteredBagsList.isEmpty) {
              return _buildEmptyState();
            }
            return _buildBagsList();
          }),
        ),
      ],
    );
  }

  Widget _buildSelectionHeader() {
    return Obx(() {
      final count = controller.selectionCount;
      final total = controller.filteredBagsList.length;
      final allSelected = count == total && total > 0;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: count > 0
            ? AppColors.primary.withOpacity(0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            if (count > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                count == 0
                    ? 'Tap cards to select bags'
                    : 'Tap again to deselect',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            GestureDetector(
              onTap: allSelected
                  ? controller.clearSelection
                  : controller.selectAll,
              child: Text(
                allSelected ? 'Deselect All' : 'Select All',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ─────────────────────────────────────────
  // BAGS LIST
  // ─────────────────────────────────────────

  Widget _buildBagsList() {
    return Obx(() {
      final selectedIds = controller.selectedSessionIds.toSet();

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: controller.filteredBagsList.length,
        itemBuilder: (context, index) {
          final bag = controller.filteredBagsList[index];
          final isSelected = selectedIds.contains(bag.sessionId);

          return _BagCard(
            bag: bag,
            isSelected: isSelected,
            onTap: () => controller.toggleBagSelection(bag),
          );
        },
      );
    });
  }

  // ─────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Collected Bags',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bags collected via QR scan will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: controller.fetchBags,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // PROCESSING VIEW
  // ─────────────────────────────────────────

  Widget _buildProcessingView() {
    return Center(
      child: Obx(() {
        final progress = controller.submissionProgress.value;
        final total = controller.submissionTotal.value;
        final percent = total > 0 ? progress / total : 0.0;

        return Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.science_outlined,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                total > 1
                    ? 'Submitting $progress of $total bags...'
                    : 'Submitting bag...',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please do not close the app',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────
  // BOTTOM ACTION BAR
  // ─────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Obx(() {
      final hasSelection = controller.hasSelection;
      final count = controller.selectionCount;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.fromLTRB(20, hasSelection ? 16 : 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              if (!hasSelection)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Select bags above to take action',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),

              if (hasSelection) ...[
                // Selected info pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$count bag${count > 1 ? 's' : ''} selected',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.clearSelection,
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.black45),
                      )
                    ],
                  ),
                ),

                // Action Buttons Row
                Row(
                  children: [
                    // Handover to Connector
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Get.to(() => const HandoverView());
                          // Runs when user pops back from HandoverView
                          controller.fetchBags();
                        },
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Handover'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Submit to Lab
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.submitToLab,
                        icon: const Icon(Icons.science_outlined, size: 18),
                        label: const Text('Submit to Lab'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BAG CARD WIDGET
// ────────────────────────────────────────────────────────────────────────────

class _BagCard extends StatelessWidget {
  final QRBag bag;
  final bool isSelected;
  final VoidCallback onTap;

  const _BagCard({
    required this.bag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 14),
        transform: isSelected
            ? Matrix4.translationValues(
                -2, -2, 0) // Moves the card slightly up-left when selected
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.18)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 22 : 12,
              offset: const Offset(0, 4),
              spreadRadius: isSelected ? 1 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Selection side accent bar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                left: 0,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: isSelected ? 3 : 0,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(0),
                      bottomLeft: Radius.circular(0),
                    ),
                  ),
                ),
              ),

              // Card Content
              Padding(
                padding: EdgeInsets.fromLTRB(isSelected ? 20 : 16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        // Bag icon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.qr_code_scanner,
                            size: 20,
                            color:
                                isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Bag code & date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bag.bagcode,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    AppAssets.calendarIcon,
                                    height: 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    bag.collectedDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Selection indicator OR status
                        _SelectionBadge(isSelected: isSelected),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Divider(height: 1, color: Colors.grey.shade100),
                    const SizedBox(height: 14),

                    // Tube count row (big callout)
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.biotech_outlined,
                          label: 'Tubes',
                          value: bag.tubeCount.toString(),
                          color: Colors.teal,
                        ),
                        if (bag.status.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          _InfoChip(
                            icon: Icons.info_outline,
                            label: 'Status',
                            value: bag.status,
                            color: Colors.blueGrey,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  final bool isSelected;

  const _SelectionBadge({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
