import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../theme/app_colors.dart';
import '../../model/patient_queue_model.dart';
import 'priority_indicator.dart';
import 'queue_action_button.dart';
import 'queue_info_chip.dart';
import 'status_badge.dart';
import 'visit_type_badge.dart';

/// The card representing a single assignment in the queue.
///
/// This is the single most important reusable component in the module —
/// it renders all "at a glance" information a phlebotomist needs
/// (who / where / when / what / next action) and exposes callbacks for
/// each possible action rather than owning any business logic itself.
class PatientCard extends StatelessWidget {
  final AssignedPatient patient;
  final bool isProcessing;
  final VoidCallback onTapDetails;
  final VoidCallback? onReject;
  final VoidCallback? onReschedule;
  final VoidCallback? onPrimaryAction;

  const PatientCard({
    super.key,
    required this.patient,
    required this.isProcessing,
    required this.onTapDetails,
    this.onReject,
    this.onReschedule,
    this.onPrimaryAction,
  });

  bool get _isTerminal => patient.status.isTerminal;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isTerminal ? 0.72 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.shadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTapDetails,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIdentityRow(),
                      const SizedBox(height: 10),
                      if (patient.address != null) ...[
                        _buildAddressRow(),
                        const SizedBox(height: 8),
                      ],
                      _buildTagsRow(),
                      const SizedBox(height: 10),
                      _buildTestsRow(),
                      const SizedBox(height: 10),
                      _buildMetaRow(),
                      const SizedBox(height: 12),
                      _buildActionsRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -- Header: visit type ribbon + status badge ---------------------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(right: 10, top: 0),
      decoration: BoxDecoration(color: AppColors.bgCardAlt),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VisitTypeBadge(visitType: patient.visitType),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: StatusBadge(status: patient.status, compact: true),
          ),
        ],
      ),
    );
  }

  // -- Avatar, name, age/id, slot time, info icon --------------------------
  Widget _buildIdentityRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _identitySubtitle(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (patient.phone != null) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.call_outlined,
                        size: 11, color: AppColors.tealText),
                    const SizedBox(width: 4),
                    Text(
                      _maskedPhone(patient.phone!),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.tealText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                if (patient.slotDateTime != null) ...[
                  const Icon(Icons.access_time_rounded,
                      size: 13, color: AppColors.blueText),
                  const SizedBox(width: 3),
                  Text(
                    DateFormat('hh:mm a').format(patient.slotDateTime!),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blueText,
                    ),
                  ),
                ] else
                  const Text(
                    'Time TBD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.textQuaternary),
              ],
            ),
            const SizedBox(height: 6),
            PriorityIndicator(priority: patient.priority),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary100,
      backgroundImage:
          patient.avatarUrl != null ? NetworkImage(patient.avatarUrl!) : null,
      child: patient.avatarUrl == null
          ? Text(
              _initials(patient.name),
              style: const TextStyle(
                color: AppColors.primary800,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            )
          : null,
    );
  }

  Widget _buildAddressRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on_outlined,
            size: 14, color: AppColors.textQuaternary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            patient.address!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsRow() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: patient.isFastingRequired
                ? AppColors.amberLight
                : AppColors.greenLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: patient.isFastingRequired
                  ? AppColors.amberBorder
                  : AppColors.greenBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                patient.isFastingRequired
                    ? Icons.no_food_outlined
                    : Icons.restaurant_outlined,
                size: 12,
                color: patient.isFastingRequired
                    ? AppColors.amberText
                    : AppColors.greenText,
              ),
              const SizedBox(width: 4),
              Text(
                patient.isFastingRequired
                    ? 'Fasting Required'
                    : 'Fasting Not Required',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: patient.isFastingRequired
                      ? AppColors.amberText
                      : AppColors.greenText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestsRow() {
    if (patient.tests.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.redLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_outlined, size: 15, color: AppColors.redText),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              patient.tests.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          QueueInfoChip(
            icon: Icons.social_distance_outlined,
            iconColor: AppColors.blue,
            label: 'Distance',
            value: patient.distanceKm != null
                ? '${patient.distanceKm!.toStringAsFixed(1)} km away'
                : '—',
          ),
          QueueInfoChip(
            icon: Icons.event_outlined,
            iconColor: AppColors.purple,
            label: 'Slot',
            value: patient.slotDateTime != null
                ? DateFormat('dd MMM yyyy').format(patient.slotDateTime!)
                : 'Not set',
          ),
          QueueInfoChip(
            icon: Icons.vaccines_outlined,
            iconColor: AppColors.tealText,
            label: 'Tubes',
            value: patient.tubes.isNotEmpty
                ? patient.tubes.map((t) => t.label).join(', ')
                : '—',
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow() {
    if (_isTerminal) {
      // No actions for completed/cancelled/failed items — keep the
      // footer quiet rather than showing disabled buttons.
      return const SizedBox.shrink();
    }

    final isRescheduled = patient.status == PatientStatus.rescheduled;

    // A rescheduled visit has nothing to "start" until its new slot
    // arrives, so it only offers Reject + a disabled Rescheduled marker —
    // showing a live "Accept & Start" button here would be misleading.
    if (isRescheduled) {
      return Row(
        children: [
          QueueActionButton(
            label: 'Reject',
            icon: Icons.close_rounded,
            color: AppColors.redText,
            style: QueueActionStyle.outlined,
            isDisabled: isProcessing,
            onPressed: onReject,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: QueueActionButton(
              label: 'Rescheduled',
              icon: Icons.event_repeat_rounded,
              color: AppColors.blue,
              style: QueueActionStyle.outlined,
              isDisabled: true,
              onPressed: null,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        QueueActionButton(
          label: 'Reject',
          icon: Icons.close_rounded,
          color: AppColors.redText,
          style: QueueActionStyle.outlined,
          isDisabled: isProcessing,
          onPressed: onReject,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: QueueActionButton(
            label: 'Reschedule',
            icon: Icons.calendar_month_outlined,
            color: AppColors.blue,
            style: QueueActionStyle.filled,
            isDisabled: isProcessing,
            onPressed: onReschedule,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: QueueActionButton(
            label: patient.status == PatientStatus.accepted
                ? 'Start Route'
                : 'Accept & Start',
            icon: patient.status == PatientStatus.accepted
                ? Icons.alt_route_rounded
                : Icons.play_circle_outline_rounded,
            color: AppColors.accent700,
            gradient: AppColors.accentGradient,
            style: QueueActionStyle.gradient,
            isLoading: isProcessing,
            onPressed: onPrimaryAction,
          ),
        ),
      ],
    );
  }

  String _identitySubtitle() {
    final parts = <String>[];
    if (patient.age != null) parts.add('Age: ${patient.age} Years');
    parts.add('ID: ${patient.orderId}');
    return parts.join('  |  ');
  }

  String _maskedPhone(String phone) {
    if (phone.length < 4) return phone;
    return '${phone.substring(0, 4)}${'*' * (phone.length - 4)}';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
