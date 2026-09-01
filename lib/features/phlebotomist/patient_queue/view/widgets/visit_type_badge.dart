import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../model/patient_queue_model.dart';

/// Ribbon-style tag identifying whether a visit is a home collection or a
/// clinic collection — this is the very first thing a phlebotomist needs
/// to register when scanning the queue, so it sits at the top-left of the
/// patient card with strong, distinct color coding.
class VisitTypeBadge extends StatelessWidget {
  final VisitType visitType;

  const VisitTypeBadge({super.key, required this.visitType});

  @override
  Widget build(BuildContext context) {
    final isHome = visitType == VisitType.home;
    final color = isHome ? AppColors.success : AppColors.purple;
    final icon = isHome ? Icons.home_rounded : Icons.local_hospital_rounded;
    final label = isHome ? 'Home Collection' : 'Clinic Collection';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
