import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../theme/app_colors.dart';
import '../../controller/patient_queue_controller.dart';
import '../../model/patient_queue_model.dart';

/// Compact, elevated status filter bar — cuboid chips (not pills), white
/// surface, thin border, subtle shadow. Mirrors the Instamart-style
/// filter row: a small filled count badge on the left, label, and a
/// close (x) affordance only when the chip is selected.
class StatusFilterBar extends StatelessWidget {
  final List<StatusFilterOption> filters;
  final PatientStatus? activeStatus;
  final ValueChanged<PatientStatus?> onFilterSelected;

  const StatusFilterBar({
    super.key,
    required this.filters,
    required this.activeStatus,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only( bottom: 10.0),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final option = filters[index];
            final isSelected = option.status == activeStatus;
            return _FilterChip(
              label: option.label,
              count: option.count,
              isSelected: isSelected,
              // Tapping the active chip clears back to "All"; tapping any
              // other chip selects it.
              onTap: () { HapticFeedback.selectionClick();onFilterSelected(isSelected ? null : option.status);},
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(

      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // Cuboid — small radius, not a pill.
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary700 : AppColors.border,
              width: 1,
            ),
            // Minor elevation — soft, close shadow, not a big drop shadow.
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CountBadge(count: count, isSelected: isSelected),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary700
                      : AppColors.textSecondary,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: AppColors.primary700,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small filled circular badge carrying the count — filled blue when
/// selected, neutral gray otherwise. Matches the "1" badge in the
/// reference chip.
class _CountBadge extends StatelessWidget {
  final int count;
  final bool isSelected;

  const _CountBadge({required this.count, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primary700 : AppColors.grayLight,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : AppColors.textTertiary,
          height: 1,
        ),
      ),
    );
  }
}