import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/controller/patient_queue_controller.dart';

import 'package:lifenity_connect/features/phlebotomist/patient_queue/model/patient_queue_model.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_pickup/service/sample_pickup_service.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../utils/ui_designs/liquid_snackbar.dart' hide SnackPosition;

import '../../../sample_collection/service/sample_collection_service.dart';
import '../widgets/visit_type_badge.dart';

class RejectAssignmentSheet extends StatefulWidget {
  final AssignedPatient patient;
  final PatientQueueController controller;
  final SampleCollectionService service;

  const RejectAssignmentSheet({
    super.key,
    required this.patient,
    required this.controller,
    required this.service,
  });

  /// Opens the rejection bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required AssignedPatient patient,
    required PatientQueueController controller,
    required SampleCollectionService service,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) {
        return RejectAssignmentSheet(
          patient: patient,
          controller: controller,
          service: service,
        );
      },
    );
  }

  @override
  State<RejectAssignmentSheet> createState() => _RejectAssignmentSheetState();
}

class _RejectAssignmentSheetState extends State<RejectAssignmentSheet> {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<dynamic> _reasons = [];

  dynamic _selectedReason;

  bool _loadingReasons = true;
  bool _submitting = false;

  bool get _canReject =>
      _selectedReason != null && !_loadingReasons && !_submitting;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  Future<void> _loadReasons() async {
    try {
      final reasons = await widget.service.fetchIncompleteReasons();

      if (!mounted) return;

      setState(() {
        _reasons = reasons;
        _loadingReasons = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingReasons = false;
      });

      LiquidSnack.error(
        'Please try again before rejecting this order.',
        title: 'Unable to load reasons',
      );
    }
  }

  Future<void> _handleReject() async {
    if (!_canReject) return;

    setState(() {
      _submitting = true;
    });

    try {
      /*
       * Keep this call aligned with your existing controller method.
       *
       * If your current method is:
       *
       *   reject(patient)
       *
       * then pass the reasonId to the service inside that method.
       *
       * If your controller already accepts reasonId:
       *
       *   reject(patient, reasonId: ...)
       *
       * use the version below.
       */

      await widget.controller.reject(
        widget.patient,
        reasonId: _selectedReason.reasonId,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
      });

      LiquidSnack.error(
        'Something went wrong. Please try again.',
        title: 'Unable to reject order',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.74,
        minChildSize: 0.50,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _buildHeader(),

                const Divider(height: 1),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    children: [
                      _buildWarningBanner(),

                      const SizedBox(height: 16),

                      _buildPatientSummary(),

                      const SizedBox(height: 24),

                      _buildSectionTitle('Rejection reason', required: true),

                      const SizedBox(height: 6),

                      const Text(
                        'Select why you are unable to accept this order.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _buildReasonSelector(),
                    ],
                  ),
                ),

                _buildBottomAction(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          _buildHeaderIcon(),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reject order',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Review before removing this visit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            splashRadius: 22,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textQuaternary,
            ),
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.assignment_return_outlined,
        size: 21,
        color: AppColors.redText,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Warning
  // ---------------------------------------------------------------------------

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.redLight.withOpacity(0.55),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.redText.withOpacity(0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 19,
              color: AppColors.redText,
            ),
          ),

          const SizedBox(width: 11),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action cannot be undone',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.redText,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'A rejection reason is required for tracking and operational follow-up.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Patient summary
  // ---------------------------------------------------------------------------

  Widget _buildPatientSummary() {
    final p = widget.patient;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Visit type
          Align(
            alignment: Alignment.topLeft,
            child: VisitTypeBadge(visitType: p.visitType),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 1, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPatientAvatar(),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        p.orderId,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),

                      const SizedBox(height: 7),

                      if (p.slotDateTime != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.event_outlined,
                              size: 13,
                              color: AppColors.purple,
                            ),

                            const SizedBox(width: 4),

                            Text(
                              DateFormat(
                                'dd MMM, hh:mm a',
                              ).format(p.slotDateTime!),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'ASSIGNED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blueText,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientAvatar() {
    final p = widget.patient;

    return CircleAvatar(
      radius: 21,
      backgroundColor: AppColors.primary100,
      backgroundImage: p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
      child: p.avatarUrl == null
          ? Text(
              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary800,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Section title
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        if (required) ...[
          const SizedBox(width: 4),

          const Text(
            '*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.redText,
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Reason selector
  // ---------------------------------------------------------------------------

  Widget _buildReasonSelector() {
    if (_loadingReasons) {
      return _buildLoadingReasonList();
    }

    if (_reasons.isEmpty) {
      return _buildEmptyReasonField();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ---------------------------------------------------------------------
          // List header
          // ---------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              border: Border(
                bottom: BorderSide(color: AppColors.border.withOpacity(0.7)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.fact_check_outlined,
                    size: 17,
                    color: AppColors.blue,
                  ),
                ),

                const SizedBox(width: 10),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a reason',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap one option below',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Number of reasons
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${_reasons.length}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------------------
          // Reasons
          // ---------------------------------------------------------------------
          ...List.generate(_reasons.length, (index) {
            final reason = _reasons[index];

            final isSelected = _selectedReason?.reasonId == reason.reasonId;

            return _buildReasonItem(
              reason,
              isSelected,
              isLast: index == _reasons.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingReasonList() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.grayLight,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loading rejection reasons...',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Please wait',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyReasonField() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.textTertiary,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'No rejection reasons are available.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildPickerHeader(BuildContext pickerContext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  size: 19,
                  color: AppColors.redText,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rejection reason',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Choose the reason that best describes the situation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                splashRadius: 20,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textQuaternary,
                ),
                onPressed: () {
                  Navigator.of(pickerContext).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonItem(
    dynamic reason,
    bool isSelected, {
    required bool isLast,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _submitting
            ? null
            : () {
                setState(() {
                  _selectedReason = reason;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.blue.withOpacity(0.055)
                : Colors.transparent,
            border: Border(
              bottom: isLast
                  ? BorderSide.none
                  : BorderSide(color: AppColors.border.withOpacity(0.7)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // -----------------------------------------------------------------
              // Radio / selection indicator
              // -----------------------------------------------------------------
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.blue : Colors.white,
                  border: Border.all(
                    width: isSelected ? 2 : 1.5,
                    color: isSelected ? AppColors.blue : AppColors.border,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('selected'),
                          size: 14,
                          color: Colors.white,
                        )
                      : const SizedBox(key: ValueKey('unselected')),
                ),
              ),

              const SizedBox(width: 12),

              // -----------------------------------------------------------------
              // Reason text
              // -----------------------------------------------------------------
              Expanded(
                child: Text(
                  reason.reason,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),

              // -----------------------------------------------------------------
              // Selected indicator
              // -----------------------------------------------------------------
              // AnimatedOpacity(
              //   duration: const Duration(milliseconds: 150),
              //   opacity: isSelected ? 1 : 0,
              //   child: const Icon(
              //     Icons.check_circle_rounded,
              //     size: 19,
              //     color: AppColors.blue,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom action
  // ---------------------------------------------------------------------------

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedReason == null &&
              !_loadingReasons &&
              _reasons.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Select a reason to enable rejection',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _canReject ? AppColors.redText : AppColors.grayLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _canReject ? _handleReject : null,
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.assignment_return_outlined,
                                size: 18,
                                color: _canReject
                                    ? Colors.white
                                    : AppColors.textMuted,
                              ),

                              const SizedBox(width: 8),

                              Text(
                                'Reject order',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: _canReject
                                      ? Colors.white
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
