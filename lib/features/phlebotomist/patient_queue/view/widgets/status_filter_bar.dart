import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../theme/app_colors.dart';
import '../../controller/patient_queue_controller.dart';
import '../../model/patient_queue_model.dart';
import 'emergency_badge.dart';
import 'priority_indicator.dart';

class StatusFilterBar extends StatelessWidget {
  final List<StatusFilterOption> filters;
  final PatientStatus? activeStatus;
  final ValueChanged<PatientStatus?> onFilterSelected;
  final bool isEmergencyActive;
  final int emergencyCount;
  final VoidCallback? onEmergencyToggle;

  const StatusFilterBar({
    super.key,
    required this.filters,
    required this.activeStatus,
    required this.onFilterSelected,
    this.isEmergencyActive = false,
    this.emergencyCount = 0,
    this.onEmergencyToggle,
  });

  @override
  Widget build(BuildContext context) {
    final showEmergencyChip = emergencyCount > 0 || isEmergencyActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (filters.isNotEmpty) ...[
              _FilterChip(
                label: filters.first.label,
                count: filters.first.count,
                isSelected: filters.first.status == activeStatus && !isEmergencyActive,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (isEmergencyActive && onEmergencyToggle != null) {
                    onEmergencyToggle!();
                  }
                  onFilterSelected(null);
                },
              ),
              const SizedBox(width: 8),
            ],

            if (showEmergencyChip) ...[
              _EmergencyFilterChip(
                count: emergencyCount,
                isSelected: isEmergencyActive,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (onEmergencyToggle != null) {
                    onEmergencyToggle!();
                  }
                },
              ),
              const SizedBox(width: 8),
            ],

            for (int i = 1; i < filters.length; i++) ...[
              _FilterChip(
                label: filters[i].label,
                count: filters[i].count,
                isSelected: filters[i].status == activeStatus && !isEmergencyActive,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (isEmergencyActive && onEmergencyToggle != null) {
                    onEmergencyToggle!();
                  }
                  final selected = filters[i].status == activeStatus;
                  onFilterSelected(selected ? null : filters[i].status);
                },
              ),
              if (i < filters.length - 1) const SizedBox(width: 8),
            ],
          ],
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
                const Icon(
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

class _EmergencyFilterChip extends StatefulWidget {
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmergencyFilterChip({
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_EmergencyFilterChip> createState() => _EmergencyFilterChipState();
}

class _EmergencyFilterChipState extends State<_EmergencyFilterChip>
    with SingleTickerProviderStateMixin {
  static const Color _emergencyRed = Color(0xFFB4413F);

  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _emergencyRed : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CountBadge(
                      count: widget.count,
                      isSelected: isSelected,
                      selectedColor: _emergencyRed,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Emergency',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _emergencyRed,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedPriorityBubble(
                      size: 5.5,
                      color: _emergencyRed,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: _emergencyRed,
                      ),
                    ],
                  ],
                ),

                // Shimmer sweep overlay — a translating gradient stripe,
                // no ShaderMask needed so it never occludes the content.
                // Shimmer sweep overlay — narrow, high-contrast "shine" band on a diagonal.
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRect(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final bandWidth = width * 0.5;
                          return AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, _) {
                              final t = _shimmerController.value; // 0 -> 1 -> 0
                              final dx = -bandWidth + ((width + bandWidth) * t);
                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: Transform.rotate(
                                  angle: -0.35, // slight diagonal for a glassy shine look
                                  child: Container(
                                    width: bandWidth,
                                    height: (constraints.maxHeight) * 2.2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [

                                          Colors.white.withOpacity(0.0),
                                          Colors.white.withOpacity(0.85),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                        stops: const [0.35, 0.5, 0.65],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final bool isSelected;
  final Color selectedColor;

  const _CountBadge({
    required this.count,
    required this.isSelected,
    this.selectedColor = AppColors.primary700,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? selectedColor : AppColors.grayLight,
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
