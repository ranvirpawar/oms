import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../theme/app_colors.dart';
import '../../model/patient_queue_model.dart';




class VisitTypeTabs extends StatefulWidget {
  final VisitType active;
  final int clinicCount;
  final int homeCount;
  final ValueChanged<VisitType> onChanged;

  const VisitTypeTabs({
    super.key,
    required this.active,
    required this.clinicCount,
    required this.homeCount,
    required this.onChanged,
  });

  @override
  State<VisitTypeTabs> createState() => _VisitTypeTabsState();
}

class _VisitTypeTabsState extends State<VisitTypeTabs> {
  // Identity colors — each tab owns its color even when inactive (dimmed),
  // and in full saturation when active. Move these into AppColors if other
  // screens need the same Clinic/Home color coding.
  static const _clinicColor = Color(0xFF2F6FED); // clinical blue
  static const _homeColor = Color(0xFFE0721E); // warm terracotta

  VisitType? _pressed;

  Color _colorFor(VisitType type) =>
      type == VisitType.clinic ? _clinicColor : _homeColor;

  void _select(VisitType type) {
    if (type == widget.active) return;
    HapticFeedback.selectionClick();
    widget.onChanged(type);
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _colorFor(widget.active);

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCardAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Stack(
        children: [
          // Sliding pill — tinted shadow + hairline border matching the
          // active tab's identity color, so depth itself is color-coded.
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: widget.active == VisitType.clinic
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: activeColor.withOpacity(0.16)),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.22),
                      blurRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _Segment(
                label: 'Clinic',
                icon: Icons.local_hospital_rounded,
                count: widget.clinicCount,
                color: _clinicColor,
                selected: widget.active == VisitType.clinic,
                pressed: _pressed == VisitType.clinic,
                onTapDown: () => setState(() => _pressed = VisitType.clinic),
                onTapCancel: () => setState(() => _pressed = null),
                onTap: () {
                  setState(() => _pressed = null);
                  _select(VisitType.clinic);
                },
              ),
              _Segment(
                label: 'Home',
                icon: Icons.home_rounded,
                count: widget.homeCount,
                color: _homeColor,
                selected: widget.active == VisitType.home,
                pressed: _pressed == VisitType.home,
                onTapDown: () => setState(() => _pressed = VisitType.home),
                onTapCancel: () => setState(() => _pressed = null),
                onTap: () {
                  setState(() => _pressed = null);
                  _select(VisitType.home);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final Color color;
  final bool selected;
  final bool pressed;
  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapCancel;

  const _Segment({
    required this.label,
    required this.icon,
    required this.count,
    required this.color,
    required this.selected,
    required this.pressed,
    required this.onTap,
    required this.onTapDown,
    required this.onTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? color : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onTapDown(),
        onTapCancel: onTapCancel,
        onTapUp: (_) => onTap(),
        child: AnimatedScale(
          scale: pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          // Center wraps a min-size Row so the whole label+icon+badge
          // cluster stays visually centered as the badge fades in/out,
          // instead of drifting toward one edge.
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    icon,
                    size: 16,
                    color: selected ? color : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    fontSize: selected ? 13.5 : 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: -0.1,
                    color: fg,
                  ),
                  child: Text(label),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 5),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: selected ? 1 : 0.55,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5.5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withOpacity(0.12)
                            : AppColors.border.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
