import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/patient_card.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_empty_state.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_error_state.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_loading_skeleton.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_search_bar.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/queue_summary_bar.dart';

import '../../../../theme/app_colors.dart';

import '../controller/patient_queue_controller.dart';

import '../model/patient_queue_model.dart';


/// Entry point of the phlebotomist's operational workflow.
///
/// Assigned Patients → Patient Details → Visit/Arrival → Sample
/// Collection → Verification → Submission → Completed.
///
/// This screen's only job is to make it effortless to identify the right
/// patient and move them into that workflow — so it stays a thin
/// presentation layer over [PatientQueueController]; there is no business
/// logic here.
class PatientQueueView extends GetView<PatientQueueController> {
  const PatientQueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // App bar
  // -----------------------------------------------------------------
  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Patient Queue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Body — switches on load state
  // -----------------------------------------------------------------
  Widget _buildBody(BuildContext context) {
    return Obx(() {
      switch (controller.loadState.value) {
        case QueueLoadState.initial:
        case QueueLoadState.loading:
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: const QueueLoadingSkeleton(),
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
          Obx(
            () => QueueSearchBar(
              controller: controller.searchController,
              showClear: controller.isSearching,
              onClear: controller.clearSearch,
            ),
          ),
          Expanded(
            child: Obx(() {
              final patients = controller.filteredPatients;

              if (patients.isEmpty) {
                final isFiltered = controller.isSearching ||
                    controller.activeFilter.value != QueueFilter.all;
                return ListView(
                  // Wrapped in a scrollable so pull-to-refresh still works
                  // even when the filtered result is empty.
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    QueueEmptyState(
                      isFiltered: isFiltered,
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
                    
                    index: index,
                    child: Obx(
                      () => PatientCard(
                        patient: patient,
                        isProcessing:
                            controller.processingIds.contains(patient.id),
                        onTapDetails: () => _openPatientDetails(patient),
                        onReject: () => _confirmReject(context, patient),
                        onReschedule: () =>
                            controller.reschedule(patient.id),
                        onPrimaryAction: () => _handlePrimaryAction(patient),
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
    if (patient.status == PatientStatus.accepted) {
      controller.startRoute(patient.id);
    } else {
      controller.acceptAndStart(patient.id);
    }
  }

  void _openPatientDetails(AssignedPatient patient) {
    // Placeholder navigation hook — wire up to the real Patient Details
    // route once it exists, e.g. `Get.toNamed(Routes.PATIENT_DETAILS,
    // arguments: patient.id)`.
    Get.snackbar(
      patient.name,
      'Open patient details for ${patient.orderId}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _confirmReject(BuildContext context, AssignedPatient patient) {
    // A destructive action gets a confirmation step so it can't be
    // triggered by an accidental tap while walking/traveling.
    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject this assignment?'),
        content: Text(
          'You are about to reject the assignment for ${patient.name} (${patient.orderId}). This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.reject(patient.id);
            },
            style:
                TextButton.styleFrom(foregroundColor: AppColors.redText),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

/// Lightweight staggered fade + slide-in for list entrance — subtle,
/// fast, and only plays once per card build rather than on every rebuild
/// triggered by Obx (each card's own AnimatedBuilder-free wrapper keys off
/// the list index so it only fires when the item first appears in the tree).
class _AnimatedListEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedListEntry({required this.index, required this.child});

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
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
