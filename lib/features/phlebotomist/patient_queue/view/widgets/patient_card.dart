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
              Expanded(
                child: QueueInfoChip(
                  icon: Icons.event_outlined,
                  iconColor: AppColors.purple,
                  label: 'Slot',
                  value: patient.slotDateTime != null
                      ? '${DateFormat('dd MMM').format(patient.slotDateTime!)} • '
                      '${DateFormat('hh:mm a').format(patient.slotDateTime!)}'
                      : 'Not set',
                ),
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
        return QueueActionButton(
          label: 'Collect',
          color: AppColors.accent700,
          gradient: AppColors.accentGradient,
          style: QueueActionStyle.gradient,
          isDisabled: false,
          onPressed: onTapDetails,
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
        return QueueActionButton(
          label: 'View Direction',
          color: AppColors.blue,
          style: QueueActionStyle.filled,
          isDisabled: false,
          onPressed: () {
            final lat = patient.destinationLat;
            final lng = patient.destinationLng;
            if (lat != null && lng != null) _launchDirections(lat, lng);
          },
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
class PatientCard1 extends StatelessWidget {
  final AssignedPatient patient;
  final bool isProcessing;
  final VoidCallback onTapDetails;
  final VoidCallback? onReject;
  final VoidCallback? onReschedule;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onStartRoute;
  final VoidCallback? onSyncToLis;

  const PatientCard1({
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
                      if (patient.tests.isNotEmpty ||
                          patient.tubes.isNotEmpty) ...[
                        if (patient.tubes.isNotEmpty) ...[
                          _buildTubesRow(),
                        ],
                        const SizedBox(height: 10),
                      ],
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

  // -- Header: visit type ribbon (edge-to-edge) + status badge ------------
  // IntrinsicHeight gives the Row a bounded height to stretch against —
  // without it, `crossAxisAlignment: stretch` inside the ListView's loose
  // Column constraints tries to stretch to infinite height and crashes.
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: AppColors.bgCardAlt),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            VisitTypeBadge(visitType: patient.visitType, cornerRadius: 18),
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 6, bottom: 6),
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
              if (patient.age != null)...[
              const SizedBox(height: 3),

              Text(
                _identitySubtitle(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),]
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
      radius: 18,
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
          fontSize: 14,
        ),
      )
          : null,
    );
  }

  // -- Compact call action: icon-only, no masked number text --------------
  Widget _buildCallButton(String phone) {
    return InkWell(
      onTap: () => _launchDialer(phone),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.tealText.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.call_rounded,
          size: 16,
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
          size: 14,
          color: AppColors.textQuaternary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            patient.address!,
            maxLines: 2,
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
    if (!patient.isFastingRequired) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.amberLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.amberBorder),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_food_outlined,
                size: 12,
                color: AppColors.amberText,
              ),
              SizedBox(width: 4),
              Text(
                'Fasting Required',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amberText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -- Tubes row: sample types required for the tests ---------------------
  Widget _buildTubesRow() {
    if (patient.tubes.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.purpleLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.vaccines_outlined,
            size: 14,
            color: AppColors.purpleText,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              patient.tubes.map((t) => t.label).join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
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
            icon: Icons.event_outlined,
            iconColor: AppColors.purple,
            label: 'Slot',
            value: patient.slotDateTime != null
                ? '${DateFormat('dd MMM yyyy').format(patient.slotDateTime!)}  •  '
                '${DateFormat('hh:mm a').format(patient.slotDateTime!)}'
                : 'Not set',
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow() {
    if (_isTerminal) return const SizedBox.shrink();

    switch (patient.status) {
      case PatientStatus.rescheduled:
        return QueueActionButton(
          label: 'Collect',
          color: AppColors.accent700,
          gradient: AppColors.accentGradient,
          style: QueueActionStyle.gradient,
          isDisabled: false,
          onPressed: onTapDetails,
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
        return QueueActionButton(
          label: 'View Direction',
          color: AppColors.blue,
          style: QueueActionStyle.filled,
          isDisabled: false,
          onPressed: () {
            final lat = patient.destinationLat;
            final lng = patient.destinationLng;
            if (lat != null && lng != null) _launchDirections(lat, lng);
          },
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
            const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded, size: 15, color: AppColors.amberText),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIS sync pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amberText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sample data was saved, but sharing with the lab failed. '
                      'Tap Sync to LIS to retry.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
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
    final ageLine = patient.age != null ? 'Age: ${patient.age} Years' : ' ';
    final idLine = patient.orderId;

    return ageLine;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
class PatientCardold extends StatelessWidget {
  final AssignedPatient patient;
  final bool isProcessing;
  final VoidCallback onTapDetails;
  final VoidCallback? onReject;
  final VoidCallback? onReschedule;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onStartRoute;
  final VoidCallback? onSyncToLis;

  const PatientCardold({
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
                      if (patient.phone?.isNotEmpty == true) ...[
                        _buildPhoneAction(),
                        const SizedBox(height: 6),
                      ],
                      if (patient.address != null) ...[
                        _buildAddressRow(),
                        const SizedBox(height: 8),
                      ],
                      _buildTagsRow(),
                      const SizedBox(height: 10),
                      if (patient.tests.isNotEmpty ||
                          patient.tubes.isNotEmpty) ...[
                        // _buildTestsRow(),
                        if (patient.tubes.isNotEmpty) ...[
                          // const SizedBox(height: 10),
                          _buildTubesRow(),
                        ],
                        const SizedBox(height: 10),
                      ],
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
      decoration: const BoxDecoration(color: AppColors.bgCardAlt),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // cornerRadius matches the card's 18px border radius so the ribbon
          // sits flush against the card border — no gap in the top-left corner.
          VisitTypeBadge(visitType: patient.visitType, cornerRadius: 18),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: StatusBadge(status: patient.status, compact: true),
          ),
        ],
      ),
    );
  }

  // -- Avatar + name + age/id, with priority indicator on the right --------
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),


      ],
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 18,
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
                fontSize: 14,
              ),
            )
          : null,
    );
  }

  Widget _buildAddressRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 14,
          color: AppColors.textQuaternary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            patient.address!,
            maxLines: 2,
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

  // -- Dialable mobile number, shown above the address --------------------
  Widget _buildPhoneAction() {
    final phone = patient.phone;
    if (phone == null || phone.isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: () => _launchDialer(phone),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.call_outlined,
              size: 13,
              color: AppColors.tealText,
            ),
            const SizedBox(width: 5),
            Text(
              _maskedPhone(phone),
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.tealText,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.tealText,
              ),
            ),
          ],
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

  Widget _buildTagsRow() {
    // The fasting chip is only surfaced when fasting is actually required —
    // a "not required" state adds noise to every card, so it stays hidden.
    if (!patient.isFastingRequired) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.amberLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.amberBorder),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_food_outlined,
                size: 12,
                color: AppColors.amberText,
              ),
              SizedBox(width: 4),
              Text(
                'Fasting Required',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amberText,
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
          const Icon(
            Icons.science_outlined,
            size: 15,
            color: AppColors.redText,
          ),
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

  // -- Tubes row: sample types required for the tests ---------------------
  /// Mirrors [_buildTestsRow] and lists the tube types (sample types) that
  /// need to be collected for this order, e.g. "2 Plain, 1 EDTA".
  Widget _buildTubesRow() {
    if (patient.tubes.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.purpleLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.vaccines_outlined,
            size: 15,
            color: AppColors.purpleText,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              patient.tubes.map((t) => t.label).join(', '),
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
          /*if (patient.distanceKm != null)
            QueueInfoChip(
              icon: Icons.social_distance_outlined,
              iconColor: AppColors.blue,
              label: 'Distance',
              value: '${patient.distanceKm!.toStringAsFixed(1)} km away',
            ),*/
          // Slot now carries date *and* time in a single row (the time used
          // to live in the header above, next to the info icon).
          QueueInfoChip(
            icon: Icons.event_outlined,
            iconColor: AppColors.purple,
            label: 'Slot',
            value: patient.slotDateTime != null
                ? '${DateFormat('dd MMM yyyy').format(patient.slotDateTime!)}  •  '
                      '${DateFormat('hh:mm a').format(patient.slotDateTime!)}'
                : 'Not set',
          ),
          // Tube section is intentionally disabled for now — kept commented
          // so it can be re-enabled trivially once tube details go live.
          // QueueInfoChip(
          //   icon: Icons.vaccines_outlined,
          //   iconColor: AppColors.tealText,
          //   label: 'Tubes',
          //   value: patient.tubes.isNotEmpty
          //       ? patient.tubes.map((t) => t.label).join(', ')
          //       : '—',
          // ),
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
              flex: 2,
              child: QueueActionButton(
                label: 'Reject',
                color: AppColors.redText,
                style: QueueActionStyle.outlined,
                isDisabled: isProcessing,
                onPressed: onReject,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              flex: 3,
              child: QueueActionButton(
                label: 'Collect',
                color: AppColors.blue,
                style: QueueActionStyle.outlined,
                isDisabled: true,
                onPressed: null,
              ),
            ),
          ],
        );

      case PatientStatus.accepted:
        // No reject once accepted — only Reschedule + Start Route.
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
        // En route — tracking is active; from the queue the phlebotomist
        // can jump straight into turn-by-turn navigation.
        return QueueActionButton(
          label: 'View Direction',
          color: AppColors.blue,
          style: QueueActionStyle.filled,
          isDisabled: false,
          onPressed: () {
            final lat = patient.destinationLat;
            final lng = patient.destinationLng;
            if (lat != null && lng != null) _launchDirections(lat, lng);
          },
        );

      case PatientStatus.arrived:
        // At the patient's location — continue into the collection flow.
        return QueueActionButton(
          label: 'Collect',
          color: AppColors.accent700,
          gradient: AppColors.accentGradient,
          style: QueueActionStyle.gradient,
          isDisabled: false,
          onPressed: onTapDetails,
        );

      case PatientStatus.sampleCollected:
        // "Collect" means collection is done but the LIS push failed — the
        // only action is re-syncing to Disha. No reject/accept/reschedule.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLisSyncCallout(),
            const SizedBox(height: 10),
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
        // Assigned/pending — just Reject + Accept, nothing else.
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

  /// Opens turn-by-turn navigation to the patient's location — the native
  /// maps app when available, browser Google Maps as a fallback.
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

  /// Amber warning surfaced only on "collect" orders: the collection is
  /// done, but the push to Disha failed and needs a manual retry.
  Widget _buildLisSyncCallout() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded, size: 15, color: AppColors.amberText),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIS sync pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amberText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sample data was saved, but sharing with the lab failed. '
                  'Tap Sync to LIS to retry.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
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
    final ageLine = patient.age != null ? 'Age: ${patient.age} Years' : null;
    final idLine = patient.orderId;

    if (ageLine != null) {
      return '$ageLine\n$idLine';
    }
    return idLine;
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
