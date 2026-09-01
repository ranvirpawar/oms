import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../model/patient_queue_model.dart';

/// Small pill showing the current [PatientStatus].
///
/// Centralizing the status → (color, label, icon) mapping here means any
/// other screen in the app (patient details, history, etc.) can reuse the
/// exact same visual language for statuses without duplicating logic.
class StatusBadge extends StatelessWidget {
  final PatientStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  _StatusStyle get _style {
    switch (status) {
      case PatientStatus.assigned:
        return _StatusStyle('Assigned', AppColors.blueText, AppColors.blueLight,
            Icons.assignment_outlined);
      case PatientStatus.pending:
        return _StatusStyle('Pending', AppColors.amberText,
            AppColors.amberLight, Icons.hourglass_top_rounded);
      case PatientStatus.accepted:
        return _StatusStyle('Accepted', AppColors.tealText,
            AppColors.tealLight, Icons.check_circle_outline);
      case PatientStatus.inProgress:
        return _StatusStyle('In Progress', AppColors.purpleText,
            AppColors.purpleLight, Icons.directions_run_rounded);
      case PatientStatus.arrived:
        return _StatusStyle('Arrived', AppColors.blueText, AppColors.blueLight,
            Icons.location_on_outlined);
      case PatientStatus.sampleCollectionStarted:
        return _StatusStyle('Collecting', AppColors.purpleText,
            AppColors.purpleLight, Icons.colorize_outlined);
      case PatientStatus.sampleCollected:
        return _StatusStyle('Sample Collected', AppColors.tealText,
            AppColors.tealLight, Icons.check_circle_outline);
      case PatientStatus.completed:
        return _StatusStyle('Completed', AppColors.greenText,
            AppColors.greenLight, Icons.task_alt_rounded);
      case PatientStatus.cancelled:
        return _StatusStyle('Cancelled', AppColors.redText, AppColors.redLight,
            Icons.cancel_outlined);
      case PatientStatus.failed:
        return _StatusStyle('Failed', AppColors.redText, AppColors.redLight,
            Icons.error_outline);
      case PatientStatus.rescheduled:
        return _StatusStyle('Rescheduled', AppColors.blueText,
            AppColors.blueLight, Icons.event_repeat_rounded);
      case PatientStatus.unableToCollect:
        return _StatusStyle('Unable to Collect', AppColors.redText,
            AppColors.redLight, Icons.block_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: s.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: compact ? 12 : 14, color: s.foreground),
          const SizedBox(width: 4),
          Text(
            s.label,
            style: TextStyle(
              color: s.foreground,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  final String label;
  final Color foreground;
  final Color background;
  final IconData icon;

  const _StatusStyle(this.label, this.foreground, this.background, this.icon);
}
