import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../model/patient_queue_model.dart';

/// Priority indicator, shown only for [PriorityLevel.high] and
/// [PriorityLevel.urgent].
///
/// Deliberately invisible for normal priority — surfacing a badge for
/// every single card would create visual noise and dilute the signal for
/// the cases that actually need attention.
class PriorityIndicator extends StatelessWidget {
  final PriorityLevel priority;

  const PriorityIndicator({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    if (priority == PriorityLevel.normal) return const SizedBox.shrink();

    final isUrgent = priority == PriorityLevel.urgent;
    final color = isUrgent ? AppColors.error : AppColors.warning;
    final label = isUrgent ? 'Urgent' : 'High Priority';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
