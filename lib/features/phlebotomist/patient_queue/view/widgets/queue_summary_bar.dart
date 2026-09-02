import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../controller/patient_queue_controller.dart';


class QueueSummaryBar extends StatelessWidget {
  final QueueFilter activeFilter;
  final int allCount;
  final int rescheduledCount;
  final int homeCount;
  final int clinicCount;
  final ValueChanged<QueueFilter> onFilterSelected;

  const QueueSummaryBar({
    super.key,
    required this.activeFilter,
    required this.allCount,
    required this.rescheduledCount,
    required this.homeCount,
    required this.clinicCount,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadowMd,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.inventory_2_outlined,
              color: AppColors.warning,
              label: 'All',
              count: allCount,
              isActive: activeFilter == QueueFilter.all,
              onTap: () => onFilterSelected(QueueFilter.all),
            ),
          ),
          _divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.event_repeat_rounded,
              color: AppColors.error,
              label: 'Rescheduled',
              count: rescheduledCount,
              isActive: activeFilter == QueueFilter.rescheduled,
              onTap: () => onFilterSelected(QueueFilter.rescheduled),
            ),
          ),
          _divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.home_rounded,
              color: AppColors.success,
              label: 'Home Visit',
              count: homeCount,
              isActive: activeFilter == QueueFilter.homeVisit,
              onTap: () => onFilterSelected(QueueFilter.homeVisit),
            ),
          ),
          _divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.local_hospital_rounded,
              color: AppColors.purple,
              label: 'Clinic Visit',
              count: clinicCount,
              isActive: activeFilter == QueueFilter.clinicVisit,
              onTap: () => onFilterSelected(QueueFilter.clinicVisit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 40,
        width: 1,
        color: AppColors.outlineVariant,
      );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,

              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 12, color: color),
                ),

                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isActive ? color : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
           /* const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isActive ? color : AppColors.textPrimary,
              ),
            ),*/
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textQuaternary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
