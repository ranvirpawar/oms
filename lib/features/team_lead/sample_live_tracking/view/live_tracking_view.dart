import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/team_lead/sample_live_tracking/view/tabs/bag_code_tab.dart';
import 'package:lifenity_connect/features/team_lead/sample_live_tracking/view/widgets/date_picker_widget.dart';
import 'package:lifenity_connect/features/team_lead/sample_live_tracking/view/widgets/error_screen.dart';
import 'package:lifenity_connect/features/team_lead/sample_live_tracking/view/widgets/tracking_dashboard_loading_widget.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import '../../../../theme/app_colors.dart';
import '../controller/live_tracking_controller.dart';

import 'tabs/dashboard_tab.dart';
import 'tabs/facility_list_tab.dart';

class LiveTrackingView extends StatelessWidget {
  const LiveTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    // Register controller if not already registered
    final controller = Get.put(LiveTrackingController());
    final today = DateFormat('MMM d, yyyy').format(DateTime.now());
    return Obx(() {
      return PopScope(
        canPop: controller.selectedTabIndex.value == 0,

        onPopInvoked: (didPop) {
          if (didPop) return;

          if (controller.selectedTabIndex.value != 0) {
            controller.setTab(0);
          }
        },

        child: Scaffold(
          backgroundColor: AppColors.bgPage,
          appBar: CustomAppBar(
            title: 'Bag Live Tracking',
            actions: [
              GestureDetector(
                onTap: () => _showDatePicker(context, controller),
                child: const _DatePill(),
              ),
            ],
          ),
          body: SafeArea(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const LiveTrackingSkeleton();
              }
              if (controller.error.value != null) {
                return ErrorScreen(
                  message: controller.error.value!,
                  onRetry: controller.loadAll,
                );
              }
              return const _MainContent();
            }),
          ),
        ),
      );
    });
  }

  void _showDatePicker(
      BuildContext context,
      LiveTrackingController controller,
      ) {
    final fmt = DateFormat('yyyy-MM-dd');

    DateRangePickerSheet.show(
      context,
      from: fmt.parse(controller.fromDate.value),
      to: fmt.parse(controller.toDate.value),
      onApply: (range) {
        controller.updateDateRange(
          from: fmt.format(range.start),
          to: fmt.format(range.end),
        );
      },
    );
  }
}

// ── Main content (header + tabs) ───────────────────────────────────────────────

class _MainContent extends GetView<LiveTrackingController> {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // _Header(),
        const _TabBar(),
        Expanded(
          child: Obx(
                () => IndexedStack(
              index: controller.selectedTabIndex.value,
              children: const [DashboardTab(), FacilityListTab(), BagsTab()],
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = Get.find<LiveTrackingController>();

      final fmt = DateFormat('yyyy-MM-dd');

      final from = fmt.parse(ctrl.fromDate.value);
      final to = fmt.parse(ctrl.toDate.value);

      final label = from == to
          ? DateFormat('MMM d, yyyy').format(to)
          : '${DateFormat('MMM d').format(from)} – ${DateFormat('MMM d').format(to)}';

      return Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: AppColors.surface,
            ),

            const SizedBox(width: 5),

            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.surface,
              ),
            ),

            const SizedBox(width: 3),

            const Icon(
              Icons.expand_more_rounded,
              size: 13,
              color: AppColors.surface,
            ),
          ],
        ),
      );
    });
  }
}

// ── Tab bar ────────────────────────────────────────────────────────────────────

class _TabBar extends GetView<LiveTrackingController> {
  const _TabBar();

  static const _tabs = ['Dashboard', 'Facilities', 'Bags'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      child: Column(
        children: [
          Obx(
                () => Row(
              children: List.generate(_tabs.length, (i) {
                final isActive = controller.selectedTabIndex.value == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setTab(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isActive
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        _tabs[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5, color: AppColors.border),
        ],
      ),
    );
  }
}





