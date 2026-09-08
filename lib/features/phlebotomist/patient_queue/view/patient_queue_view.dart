import 'package:flutter/material.dart';
import 'package:get/get.dart' hide SnackPosition;
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/patient_card.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_empty_state.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_error_state.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_loading_skeleton.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_search_bar.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_summary_bar.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/rejected_assignment_sheet.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/rescheduled_slot.dart';
import 'package:lifenity_connect/routes/route_manager.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../theme/app_colors.dart';

import '../../../../utils/ui_designs/liquid_snackbar.dart';
import '../controller/patient_queue_controller.dart';

import '../model/patient_queue_model.dart';

class PatientQueueView extends GetView<PatientQueueController> {
  const PatientQueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: CustomAppBar(
        title: 'Patient Queue',
        enableSearch: true,
        searchHint: 'Search by name, ID, or test',
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
      ),
      body: SafeArea(
        bottom: false,
        child: Column(children: [Expanded(child: _buildBody(context))]),
      ),
    );
  }

  // -----------------------------------------------------------------
  // App bar
  // -----------------------------------------------------------------

  // -----------------------------------------------------------------
  // Body — switches on load state
  // -----------------------------------------------------------------
  Widget _buildBody(BuildContext context) {
    return Obx(() {
      switch (controller.loadState.value) {
        case QueueLoadState.initial:
        case QueueLoadState.loading:
          return const Padding(
            padding: EdgeInsets.only(top: 16),
            child: QueueLoadingSkeleton(),
          );

        case QueueLoadState.error:
          return QueueErrorState(
            message: controller.errorMessage.value,
            onRetry: controller.retry,
          );

        case QueueLoadState.empty:
        case QueueLoadState.loaded:
          return _buildLoadedContent(context);
      }
    });
  }

  Widget _buildLoadedContent(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary700,
      onRefresh: controller.refreshPatients,
      child: Column(
        children: [
          const SizedBox(height: 14),
          Obx(
                () => QueueSummaryBar(
              activeFilter: controller.activeFilter.value,
              allCount: controller.totalCount,
              rescheduledCount: controller.rescheduledCount,
              homeCount: controller.homeVisitCount,
              clinicCount: controller.clinicVisitCount,
              onFilterSelected: controller.setFilter,
            ),
          ),

          Expanded(
            child: Obx(() {
              final patients = controller.filteredPatients;

              if (patients.isEmpty) {
                final isFiltered =
                    controller.isSearching ||
                        controller.activeFilter.value != QueueFilter.all;
                // Collection mode (bag registration entry point) narrows the
                // queue to Arrived orders — explain that when it's empty.
                final collectionEmpty =
                    controller.isCollectionMode && !isFiltered;
                return ListView(
                  // Wrapped in a scrollable so pull-to-refresh still works
                  // even when the filtered result is empty.
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    QueueEmptyState(
                      isFiltered: isFiltered,
                      title: collectionEmpty ? 'No arrived patients' : null,
                      subtitle: collectionEmpty
                          ? "Only orders with status 'Arrived' can be "
                              'collected into this bag. They will appear here '
                              'once the patient is marked as arrived.'
                          : null,
                      onClearFilter: isFiltered
                          ? () {
                        controller.setFilter(QueueFilter.all);
                        controller.clearSearch();
                      }
                          : null,
                    ),
                  ],
                );
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                        isProcessing: controller.processingIds.contains(
                          patient.id,
                        ),
                        onTapDetails: () => _openPatientDetails(patient),
                        onReject: () => _confirmReject(context, patient),
                            onReschedule: () => RescheduleSheet.show(
                              context,
                              patient: patient,
                              onConfirm: (date, start, end) => controller.reschedule(
                                patient,
                                newDate: date,
                                startTime: start,
                                endTime: end,
                              ),
                            ),
                        onPrimaryAction: () => _handlePrimaryAction(patient),
                        onStartRoute: () => controller.startRoute(patient),
                        onSyncToLis: () => controller.syncToLis(patient),
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

  void _confirmReject(
      BuildContext context,
      AssignedPatient patient,
      ) {
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
