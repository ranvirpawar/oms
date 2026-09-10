import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../../patient_queue/model/patient_queue_model.dart';
import 'order_summary_card.dart';

/// Shown when the order is accepted but the phlebotomist hasn't started
/// the route yet — nothing has been fetched, so this is purely informational.
class NeedsRouteStartView extends StatelessWidget {
  final AssignedPatient patient;

  const NeedsRouteStartView({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        OrderPatientSummaryCard.fromAssignedPatient(
          patient: patient,
          initiallyExpanded: true,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.amberLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.amberBorder),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.route_outlined, size: 18, color: AppColors.amberText),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You need to start the route and mark yourself as '
                      'arrived at the collection location before you can '
                      'collect the sample.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}