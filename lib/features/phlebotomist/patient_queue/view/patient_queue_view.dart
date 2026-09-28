import 'package:flutter/material.dart';
import 'package:get/get.dart' hide SnackPosition;
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/patient_card.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_empty_state.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_error_state.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_loading_skeleton.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/rejected_assignment_sheet.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/rescheduled_slot.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/status_filter_bar.dart';
import 'package:lifenity_connect/routes/route_manager.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../theme/app_colors.dart';
import '../controller/patient_queue_controller.dart';
import '../controller/patient_queue_scroll_controller.dart';
import '../model/patient_queue_model.dart';
import 'widgets/date_filter_tile.dart';
import 'widgets/queue_collapsing_header.dart';
import 'widgets/visit_type_tabs.dart';

class PatientQueueView extends GetView<PatientQueueController> {
  const PatientQueueView({super.key});

  PatientQueueScrollController get _scroll =>
      Get.find<PatientQueueScrollController>();

  @override
  Widget build(BuildContext context) {
    // No Scaffold.appBar / SafeArea: the app bar lives inside the body so it
    // can scroll away. The header handles the status-bar inset itself.
    return Scaffold(backgroundColor: AppColors.bgPage, body: _buildBody(context));
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  CustomAppBar _buildAppBar() {
    return CustomAppBar(
      title: 'Patient Queue',
      enableSearch: true,
      searchHint: 'Search by name, address, test',
      onSearchChanged: controller.updateSearch,
      onSearchClosed: controller.clearSearch,
      onSearchCleared: controller.clearSearch,
      actions: [
        Obx(
              () => IconButton(
            onPressed: controller.isRefreshing.value
                ? null
                : controller.refreshPatients,
            icon: controller.isRefreshing.value
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// Non-scrolling app bar for loading / error states.
  Widget _withStaticAppBar(BuildContext context, Widget child) {
    final appBar = _buildAppBar();
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.paddingOf(context).top + appBar.preferredSize.height,
          child: appBar,
        ),
        Expanded(child: child),
      ],
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      switch (controller.loadState.value) {
        case QueueLoadState.initial:
        case QueueLoadState.loading:
          return _withStaticAppBar(
            context,
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: QueueLoadingSkeleton(),
            ),
          );

        case QueueLoadState.error:
          return _withStaticAppBar(
            context,
            QueueErrorState(
              message: controller.errorMessage.value,
              onRetry: controller.retry,
            ),
          );

        case QueueLoadState.empty:
        case QueueLoadState.loaded:
          return _buildLoadedContent(context);
      }
    });
  }

  Widget _buildLoadedContent(BuildContext context) {
    final scroll = _scroll;
    final topInset = MediaQuery.paddingOf(context).top;
    final appBar = _buildAppBar();

    return Stack(
      children: [
        // 1) The list — padded so its first item starts below the header.
        Positioned.fill(
          child: Obx(() {
            // Wait one frame until the header has been measured.
            if (!scroll.isReady) return const SizedBox.shrink();
            final headerHeight =
                topInset +
                    scroll.collapsibleHeight.value +
                    scroll.pinnedHeight.value;
            return _buildList(context, headerHeight);
          }),
        ),

        // 2) The header — app bar + visit row slide away, chips stay pinned.
        QueueCollapsingHeader(
          scroll: scroll,
          topInset: topInset,
          backgroundColor: AppColors.bgPage,
          collapsible: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Full app bar incl. status-bar area, so its gradient runs
              // behind the status bar exactly as before.
              SizedBox(
                height: topInset + appBar.preferredSize.height,
                child: appBar,
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Obx(
                      () => Row(
                    children: [
                      Expanded(
                        child: VisitTypeTabs(
                          active: controller.activeVisitType.value,
                          clinicCount: controller.clinicVisitCount,
                          homeCount: controller.homeVisitCount,
                          onChanged: controller.setVisitType,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: DateFilterTile(
                          active: controller.activeDateFilter.value,
                          customRange: controller.customRange.value,
                          onChanged: controller.setDateFilter,
                          onCustomRangeSelected: controller.setCustomRange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pinned: Obx(
                () => StatusFilterBar(
              filters: controller.statusFilters,
              activeStatus: controller.activeStatusFilter.value,
              onFilterSelected: controller.setStatusFilter,
              isEmergencyActive: controller.isEmergencyOnly.value,
              emergencyCount: controller.emergencyCount,
              onEmergencyToggle: controller.toggleEmergencyFilter,
              clinics: controller.clinicFilters,
              activeClinic: controller.activeClinicFilter.value,
              onClinicSelected: controller.setClinicFilter,
              activeVisitType: controller.activeVisitType.value,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, double headerHeight) {
    final scroll = _scroll;

    return RefreshIndicator(
      color: AppColors.primary700,
      // Spinner appears just below the pinned chips instead of under them.
      edgeOffset: headerHeight,
      onRefresh: controller.refreshPatients,
      child: NotificationListener<ScrollNotification>(
        onNotification: scroll.handleScroll,
        child: Obx(() {
          final patients = controller.filteredPatients;

          if (patients.isEmpty) {
            final isFiltered = controller.hasActiveFilters;
            // Collection mode (bag registration entry point) narrows the
            // queue to Arrived orders — explain that when it's empty.
            final collectionEmpty = controller.isCollectionMode && !isFiltered;
            return ListView(
              // Scrollable so pull-to-refresh still works when empty.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: headerHeight),
              children: [
                QueueEmptyState(
                  isFiltered: isFiltered,
                  title: collectionEmpty ? 'No arrived patients' : null,
                  subtitle: collectionEmpty
                      ? "Only orders with status 'Arrived' can be "
                      'collected into this bag. They will appear here '
                      'once the patient is marked as arrived.'
                      : null,
                  onClearFilter: isFiltered ? controller.clearAllFilters : null,
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(8, headerHeight, 8, 100),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return _AnimatedListEntry(
                key: ValueKey(patient.id),
                index: index,
                child: Obx(
                      () => PatientCard(
                    key: ValueKey('card_${patient.id}'),
                    patient: patient,
                    isProcessing: controller.processingIds.contains(patient.id),
                    onTapDetails: () => _openPatientDetails(patient),
                    onReject: () => _confirmReject(context, patient),
                    onReschedule: () => RescheduleSheet.show(
                      context,
                      patient: patient,
                      onFetchSlots: (date) => controller.fetchAvailableSlots(date),
                      onFetchReasons: () => controller.fetchRescheduleReasons(),
                      onConfirm: (date, slot, reasonId, otherRemark) =>
                          controller.rescheduleAssignment(
                            patient,
                            newDate: date,
                            slot: slot,
                            rescheduleReasonId: reasonId,
                            otherRemark: otherRemark,
                          ),
                      onSendOtp: (mobileNo, orderId) =>
                          controller.sendRescheduleOtp(
                            mobileNo: mobileNo,
                            sampleCollectionOrderId: orderId,
                          ),
                      onVerifyOtp: (mobileNo, otp, orderId) =>
                          controller.verifyRescheduleOtp(
                            mobileNo: mobileNo,
                            otp: otp,
                            sampleCollectionOrderId: orderId,
                          ),
                    ),
                    onPrimaryAction: () => _handlePrimaryAction(patient),
                    onStartRoute: () => controller.startRoute(patient),
                    onSyncToLis: () => controller.syncToLis(patient),
                    onMarkArrived: () => controller.markArrived(patient),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  void _handlePrimaryAction(AssignedPatient patient) {
    // "Start Route" has its own button on the card now — the primary
    // action only needs to accept the assignment.
    controller.acceptAndStart(patient);
  }

  void _openPatientDetails(AssignedPatient patient) {
    // "Collect" orders are sample-done / LIS-sync-pending reminders — the
    // collection flow doesn't apply, so there's nothing to open.
    if (patient.status == PatientStatus.collect) return;
    RouteManager.navigateToSampleCollection(patient);
  }

  void _confirmReject(BuildContext context, AssignedPatient patient) {
    RejectAssignmentSheet.show(
      context,
      patient: patient,
      controller: controller,
      service: controller.sampleCollectionService,
    );
  }
}

class _AnimatedListEntry extends StatefulWidget {
  final int index;
  final Widget child;
  @override
  final Key? key;

  const _AnimatedListEntry({
    required this.index,
    required this.child,
    this.key,
  });

  @override
  State<_AnimatedListEntry> createState() => _AnimatedListEntryState();
}

class _AnimatedListEntryState extends State<_AnimatedListEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fade);

    final delay = Duration(milliseconds: 40 * widget.index.clamp(0, 8));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      key: widget.key,
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}