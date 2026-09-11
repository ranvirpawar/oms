import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../theme/app_colors.dart';
import '../../model/patient_queue_model.dart';
import 'priority_indicator.dart';
import 'queue_action_button.dart';
import 'queue_info_chip.dart';
import 'status_badge.dart';
import 'visit_type_badge.dart';
class PatientCard extends StatelessWidget {
  final AssignedPatient patient;
  final bool isProcessing;
  final VoidCallback onTapDetails;
  final VoidCallback? onReject;
  final VoidCallback? onReschedule;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onStartRoute;
  final VoidCallback? onSyncToLis;

  const PatientCard({
    super.key,
    required this.patient,
    required this.isProcessing,
    required this.onTapDetails,
    this.onReject,
    this.onReschedule,
    this.onPrimaryAction,
    this.onStartRoute,
    this.onSyncToLis,
  });

  bool get _isTerminal => patient.status.isTerminal;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isTerminal ? 0.72 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), // was 14
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16), // was 18
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
                  // was fromLTRB(14, 10, 14, 14)
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIdentityRow(),
                      const SizedBox(height: 8), // was 10
                      if (patient.address != null) ...[
                        _buildAddressRow(),
                        const SizedBox(height: 6), // was 8
                      ],
                      // Fasting tag + slot + tubes now live in ONE
                      // combined meta block instead of three separate
                      // sections with their own spacing/padding.
                      _buildMetaBlock(),
                      const SizedBox(height: 10), // was 12
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

  // -- Header: visit type ribbon (edge-to-edge) + status badge ------------
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: AppColors.bgCardAlt),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            VisitTypeBadge(visitType: patient.visitType, cornerRadius: 16),
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
              child: StatusBadge(status: patient.status, compact: true),
            ),
          ],
        ),
      ),
    );
  }

  // -- Avatar + name + age/id, call icon trailing ---------------------------
  Widget _buildIdentityRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAvatar(),
        const SizedBox(width: 10), // was 12
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5, // was 15.5
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (patient.age != null) ...[
                const SizedBox(height: 2), // was 3
                Text(
                  _identitySubtitle(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5, // was 12
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (patient.phone?.isNotEmpty == true) ...[
          const SizedBox(width: 8),
          _buildCallButton(patient.phone!),
        ],
      ],
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16, // was 18
      backgroundColor: AppColors.primary100,
      backgroundImage: patient.avatarUrl != null
          ? NetworkImage(patient.avatarUrl!)
          : null,
      child: patient.avatarUrl == null
          ? Text(
        _initials(patient.name),
        style: const TextStyle(
          color: AppColors.primary800,
          fontWeight: FontWeight.w700,
          fontSize: 13, // was 14
        ),
      )
          : null,
    );
  }

  // -- Compact call action: icon-only, no masked number text --------------
  Widget _buildCallButton(String phone) {
    return InkWell(
      onTap: () => _launchDialer(phone),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 30, // was 34
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.tealText.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.call_rounded,
          size: 15, // was 16
          color: AppColors.tealText,
        ),
      ),
    );
  }

  Future<void> _launchDialer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildAddressRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 13, // was 14
          color: AppColors.textQuaternary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            patient.address!,
            maxLines: 1, // was 2 — one line keeps the card from growing
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5, // was 12
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // -- Single combined block: fasting tag inline with slot, tubes below ---
  // Replaces the old _buildTagsRow + _buildMetaRow + _buildTubesRow trio
  // (each with its own container/border/padding) with one shared surface.
  Widget _buildMetaBlock() {
    final hasSlotOrFasting = true; // slot chip always renders
    final hasTubes = patient.tubes.isNotEmpty;

    if (!hasSlotOrFasting && !hasTubes) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              QueueInfoChip(
                icon: Icons.event_outlined,
                iconColor: AppColors.purple,
                label: 'Slot',
                value: patient.slotDateTime != null
                    ? '${DateFormat('dd MMM').format(patient.slotDateTime!)} • '
                    '${DateFormat('hh:mm a').format(patient.slotDateTime!)}'
                    : 'Not set',
              ),
              if (patient.isFastingRequired) ...[
                const SizedBox(width: 6),
                _buildFastingChip(),
              ],
            ],
          ),
          if (hasTubes) ...[
            const SizedBox(height: 6), // was 10 (separate box before)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.vaccines_outlined,
                  size: 13, // was 14
                  color: AppColors.purpleText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    patient.tubes.map((t) => t.label).join(', '),
                    maxLines: 1, // was 2
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11, // was 11.5
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Compact pill version for inline placement next to the slot chip.
  Widget _buildFastingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.no_food_outlined, size: 11, color: AppColors.amberText),
          SizedBox(width: 3),
          Text(
            'Fasting',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.amberText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow() {
    if (_isTerminal) return const SizedBox.shrink();

    switch (patient.status) {
      case PatientStatus.rescheduled:
        return Row(
          children: [
            Expanded(
              child: QueueActionButton(
                label: 'Reschedule',
                color: AppColors.blue,
                style: QueueActionStyle.filled,
                isDisabled: isProcessing,
                onPressed: onReschedule,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: QueueActionButton(
                label: 'Collect',
                color: AppColors.accent700,
                gradient: AppColors.accentGradient,
                style: QueueActionStyle.gradient,
                isDisabled: false,
                onPressed: onTapDetails,
              ),
            ),
          ],
        );

      case PatientStatus.accepted:
        return Row(
          children: [
            Expanded(
              child: QueueActionButton(
                label: 'Reschedule',
                color: AppColors.blue,
                style: QueueActionStyle.filled,
                isDisabled: isProcessing,
                onPressed: onReschedule,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: QueueActionButton(
                label: 'Start Route',
                color: AppColors.accent700,
                gradient: AppColors.accentGradient,
                style: QueueActionStyle.gradient,
                isLoading: isProcessing,
                onPressed: onStartRoute,
              ),
            ),
          ],
        );

      case PatientStatus.inRoute:
        return Row(
          children: [

            Expanded(
              child: QueueActionButton(
                label: 'View Direction',
                color: AppColors.blue,
                style: QueueActionStyle.filled,
                isDisabled: false,
                onPressed: () {
                  final lat = patient.destinationLat;
                  final lng = patient.destinationLng;
                  if (lat != null && lng != null) _launchDirections(lat, lng);
                },
              ),
            ),
            const SizedBox(width: 8),
            //mark arrived button need to add action correctly
            Expanded(
              child: QueueActionButton(
                label: 'Mark Arrived',
                color: AppColors.accent700,
                gradient: AppColors.accentGradient,
                style: QueueActionStyle.gradient,
                isLoading: isProcessing,
                onPressed: onTapDetails,
              ),),
          ],
        );

      case PatientStatus.arrived:
        return QueueActionButton(
          label: 'Collect',
          color: AppColors.accent700,
          gradient: AppColors.accentGradient,
          style: QueueActionStyle.gradient,
          isDisabled: false,
          onPressed: onTapDetails,
        );

      case PatientStatus.sampleCollected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLisSyncCallout(),
            const SizedBox(height: 8), // was 10
            QueueActionButton(
              label: 'Sync to LIS',
              color: AppColors.accent700,
              gradient: AppColors.accentGradient,
              style: QueueActionStyle.gradient,
              isLoading: isProcessing,
              onPressed: onSyncToLis,
            ),
          ],
        );

      case PatientStatus.assigned:
      case PatientStatus.pending:
      default:
        return Row(
          children: [
            Expanded(
              child: QueueActionButton(
                label: 'Reject',
                color: AppColors.redText,
                style: QueueActionStyle.outlined,
                isDisabled: isProcessing,
                onPressed: onReject,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: QueueActionButton(
                label: 'Accept',
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
  }

  Future<void> _launchDirections(double lat, double lng) async {
    final uri = Platform.isIOS
        ? Uri.parse('https://maps.apple.com/?daddr=$lat,$lng')
        : Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(
        Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
        ),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Widget _buildLisSyncCallout() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // was 10 v
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded, size: 14, color: AppColors.amberText),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIS sync pending',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amberText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sample data was saved, but sharing with the lab failed. '
                      'Tap Sync to LIS to retry.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: AppColors.onWarningContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _identitySubtitle() {
    return patient.age != null ? 'Age: ${patient.age} Years' : ' ';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

