import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/constants/app_assets.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';
import '../../controller/live_tracking_controller.dart';

import '../widgets/alert_tile_widget.dart';
import '../widgets/donut_chart_widget.dart';
import '../widgets/flow_step_widget.dart';
import '../widgets/status_summary_card.dart';
import '../../model/facility_model.dart';
import '../widgets/tracking_bag_details.dart';

class DashboardTab extends GetView<LiveTrackingController> {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.summary.value;

      if (summary == null) {
        return const SizedBox.shrink();
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Attention banner ───────────────────────────────────────
              if (controller.attentionCount > 0) ...[
                const _AttentionBanner(),
                const SizedBox(height: 14),
              ],

              // ── Sample Bags Overview ────────────────────────────────────
              _SectionCard(
                title: 'Sample Bags Overview',
                subtitle: "Today's status mix, live from the field",
                trailing: _ViewAllButton(onTap: () => controller.setTab(1)),
                child: DonutChartWidget(distribution: controller.statusDistribution),
              ),

              const SizedBox(height: 14),

              // ── Sample Collection Flow ──────────────────────────────────
              _SectionCard(
                title: 'Sample Collection Flow',
                subtitle: 'Bags moving through each stage today',
                child: FlowSnakeGrid(

                  steps: [
                    FlowStepData(
                      iconAsset: AppAssets.bagOpenedIcon,
                      label: 'Bag Opened',
                      count: summary.openBag,
                      state: summary.openBag > 0 ? FlowStepState.done : FlowStepState.idle,
                    ),
                    FlowStepData(
                      iconAsset: AppAssets.bagClosedIcon,
                      label: 'Closed',
                      count: summary.closeBag,
                      state: summary.closeBag > 0 ? FlowStepState.done : FlowStepState.idle,
                    ),
                    FlowStepData(
                      iconAsset: AppAssets.bagCollectedIcon,
                      label: 'Collected',
                      count: summary.sampleBagCollected,
                      state: summary.sampleBagCollected > 0 ? FlowStepState.done : FlowStepState.idle,
                    ),
                    FlowStepData(
                      iconAsset: AppAssets.bagTransferIcon,
                      label: 'Transfer',
                      count: summary.sampleTransfer,
                      state: summary.sampleTransfer > 0 ? FlowStepState.done : FlowStepState.idle,
                    ),
                    FlowStepData(
                      iconAsset: AppAssets.bagHandoverIcon,
                      label: 'Handover',
                      count: summary.sampleBagHandover,
                      state: summary.sampleBagHandover > 0 ? FlowStepState.active : FlowStepState.idle,
                    ),
                    FlowStepData(
                      iconAsset: AppAssets.bagSubmittedIcon,
                      label: 'Submitted',
                      count: summary.bagSubmitted,
                      state: summary.bagSubmitted > 0 ? FlowStepState.done : FlowStepState.idle,
                    ),
                    FlowStepData(
                      iconAsset: AppAssets.bagAcceptedIcon,
                      label: 'Accepted',
                      count: summary.bagAccepted,
                      state: summary.bagAccepted > 0 ? FlowStepState.done : FlowStepState.idle,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Status Summary — computed live from the facility list ─────
              _SectionCard(
                title: 'Status Summary',
                trailing: _ViewAllButton(onTap: () => controller.setTab(1)),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.85,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatusSummaryCard(
                      bgAsset: AppAssets.attentionNeeded,
                      count: controller.attentionCount,
                      label: 'Attention\nNeeded',
                      borderColor: AppColors.redBorder,
                      onTap: controller.attentionCount > 0
                          ? () => controller.drillDown('Attention')
                          : null,
                    ),
                    StatusSummaryCard(
                      bgAsset: AppAssets.inTransit,
                      count: controller.inTransitCount,
                      borderColor: AppColors.tealTextOG,
                      label: 'In\nTransit',
                      onTap: controller.inTransitCount > 0
                          ? () => controller.drillDown('In Transit')
                          : null,
                    ),
                    StatusSummaryCard(
                      bgAsset: AppAssets.pickupAwaiting,
                      count: controller.awaitingPickupCount,
                      borderColor: AppColors.blueText,
                      label: 'Awaiting\nPickup',
                      onTap: controller.awaitingPickupCount > 0
                          ? () => controller.drillDown('Pending')
                          : null,
                    ),
                    StatusSummaryCard(
                      bgAsset: AppAssets.completedToday,
                      count: controller.completedTodayCount,
                      borderColor: AppColors.greenText,
                      label: 'Completed\n Today',
                      onTap: controller.completedTodayCount > 0
                          ? () => controller.drillDown('Bag Accepted')
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Recent Alerts — real facilities, worst first ────────────────
              _SectionCard(
                title: 'Recent Alerts',
                trailing: _ViewAllButton(onTap: () => controller.setTab(1)),
                child: const _AlertsList(),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
  }
}

// ── Attention banner ────────────────────────────────────────────────────────

class _AttentionBanner extends GetView<LiveTrackingController> {
  const _AttentionBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.drillDown('Attention'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.redLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.redBorder, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.redText, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${controller.attentionCount} facility(ies) have breached TAT — needs immediate follow-up.',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.redText),
              ),
            ),
            GestureDetector(
              onTap: () => controller.drillDown('Attention'),
              child: const Icon(Icons.chevron_right_rounded, color: AppColors.redText),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alerts, built from real facility data (not hardcoded copy) ─────────────

class _AlertsList extends GetView<LiveTrackingController> {
  const _AlertsList();

  @override
  Widget build(BuildContext context) {
    final feed = controller.attentionFeed.take(4).toList();

    if (feed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.greenText, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('All facilities are within TAT. No action needed.', style: AppTextStyles.bodySecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < feed.length; i++) ...[
          _FacilityAlertTile(facility: feed[i]),
          if (i != feed.length - 1) Divider(height: 1, color: AppColors.border, thickness: 0.5),
        ],
      ],
    );
  }
}

class _FacilityAlertTile extends StatelessWidget {
  final FacilityModel facility;

  const _FacilityAlertTile({required this.facility});

  @override
  Widget build(BuildContext context) {
    final urgency = facility.urgency;
    final elapsed = facility.tatTimeInHrs ?? facility.liveElapsedHours;
    final isBreach = urgency == FacilityUrgency.breached;

    final message = isBreach
        ? '${facility.facilityName} has breached its TAT'
        : '${facility.facilityName} is approaching its TAT';

    final sub = elapsed != null
        ? 'Elapsed ${elapsed.toStringAsFixed(1)} hrs of ${facility.stdTatTime.toStringAsFixed(1)} hrs standard'
        : facility.displayStatus;

    return AlertTileWidget(
      icon: isBreach ? Icons.error_outline_rounded : Icons.hourglass_bottom_rounded,
      iconBg: urgency.bgColor,
      iconColor: urgency.color,
      message: message,
      subMessage: sub,
      timeAgo: facility.timeElapsed,
      onTap: () {
        final ctrl = Get.find<LiveTrackingController>();
        ctrl.openFacilityDetail(facility);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BagDrilldownSheet(controller: ctrl),
        );
      },
    );
  }
}

// ── Local section helpers ───────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.sectionTitle),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTextStyles.caption),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: const [
          Text(
            'View All',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary),
          ),
          SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.primary),
        ],
      ),
    );
  }
}
