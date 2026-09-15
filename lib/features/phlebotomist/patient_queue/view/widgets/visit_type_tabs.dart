import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../theme/app_colors.dart';
import '../../model/patient_queue_model.dart';



import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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

class _VisitTypeTabsState extends State<VisitTypeTabs>
    with SingleTickerProviderStateMixin {
  // Identity colors — each tab owns its color even when inactive (dimmed),
  // and in full saturation when active.
  static const _clinicColor = Color(0xFF2F6FED); // clinical blue
  static const _homeColor = Color(0xFFE0721E); // warm terracotta

  // Spring tuned for a subtle iOS-style rubber-band settle: enough
  // overshoot to feel alive, not enough to feel bouncy/toy-like.
  static const _spring = SpringDescription(mass: 1, stiffness: 380, damping: 26);

  late final AnimationController _controller;
  VisitType? _pressed;
  bool _isDragging = false;
  // Set right before we call widget.onChanged() as a result of a drag
  // release, so the didUpdateWidget spring (velocity 0) doesn't stomp on
  // the velocity-aware spring the drag handler already kicked off.
  bool _suppressNextExternalAnimate = false;

  double get _target => widget.active == VisitType.clinic ? 0.0 : 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: _target);
  }

  @override
  void didUpdateWidget(covariant VisitTypeTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (_suppressNextExternalAnimate) {
        // The drag handler already started a velocity-aware spring toward
        // this same target — don't restart it from a standing stop.
        _suppressNextExternalAnimate = false;
        return;
      }
      _animateToTarget(velocity: 0);
    }
  }

  void _animateToTarget({required double velocity}) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.animateTo(
        _target,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
      return;
    }
    final simulation = SpringSimulation(_spring, _controller.value, _target, velocity);
    _controller.animateWith(simulation);
  }

  /// Called continuously while a finger drags across the track — the pill
  /// follows 1:1, no animation, just direct tracking.
  void _onDragUpdate(double localDx, double trackWidth) {
    final progress = (localDx / trackWidth).clamp(0.0, 1.0);
    _controller.value = progress;
  }

  /// Called on release/cancel — decides which side to snap to (crossed the
  /// midpoint, or a fast-enough flick in either direction overrides that),
  /// then launches a spring seeded with the actual release velocity so a
  /// hard flick keeps its momentum into the snap, like a native control.
  void _onDragSettle(double velocityPxPerSec, double trackWidth) {
    _isDragging = false;
    final velocityUnitsPerSec = velocityPxPerSec / trackWidth;
    const flingThreshold = 1.2; // progress-units/sec to count as a flick

    final VisitType target;
    if (velocityUnitsPerSec.abs() > flingThreshold) {
      target = velocityUnitsPerSec > 0 ? VisitType.home : VisitType.clinic;
    } else {
      target = _controller.value > 0.5 ? VisitType.home : VisitType.clinic;
    }

    final changed = target != widget.active;
    if (changed) {
      HapticFeedback.selectionClick();
      _suppressNextExternalAnimate = true;
      widget.onChanged(target);
    }

    // Animate ourselves either way — if `changed` is false the parent
    // won't rebuild us, so we still need to spring back to rest.
    final targetValue = target == VisitType.clinic ? 0.0 : 1.0;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.animateTo(targetValue,
          duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
    } else {
      final simulation =
      SpringSimulation(_spring, _controller.value, targetValue, velocityUnitsPerSec);
      _controller.animateWith(simulation);
    }
  }

  Color _colorFor(VisitType type) =>
      type == VisitType.clinic ? _clinicColor : _homeColor;

  void _select(VisitType type) {
    if (type == widget.active) return;
    HapticFeedback.selectionClick();
    widget.onChanged(type);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      child: ClipRRect(
        // Keeps the spring's slight overshoot from poking past the track
        // edges instead of clamping the motion (which would kill the bounce).
        borderRadius: BorderRadius.circular(11),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final pillWidth = trackWidth / 2;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {
                _controller.stop();
                _isDragging = true;
                if (_pressed != null) setState(() => _pressed = null);
              },
              onHorizontalDragUpdate: (details) =>
                  _onDragUpdate(details.localPosition.dx, trackWidth),
              onHorizontalDragEnd: (details) =>
                  _onDragSettle(details.primaryVelocity ?? 0, trackWidth),
              onHorizontalDragCancel: () => _onDragSettle(0, trackWidth),
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = _controller.value;
                      // Squash/stretch: the pill widens slightly mid-flight
                      // and relaxes back to normal at rest — reads as a
                      // physical object being flicked, not a tween sliding.
                      final distanceFromRest = (t - t.roundToDouble()).abs();
                      final stretch = 1.0 + (distanceFromRest * 0.16);

                      return Positioned(
                        left: t * pillWidth,
                        width: pillWidth,
                        top: 0,
                        bottom: 0,
                        child: Transform.scale(
                          scaleX: stretch,
                          child: Container(
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
                      );
                    },
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
                        progress: _controller,
                        restValue: 0.0,
                        slideDirection: -1,
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
                        progress: _controller,
                        restValue: 1.0,
                        slideDirection: 1,
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
          },
        ),
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
  final Animation<double> progress;
  final double restValue; // 0 for the left/clinic segment, 1 for the right/home segment
  final int slideDirection; // -1 or 1, which way this segment's content drifts
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
    required this.progress,
    required this.restValue,
    required this.slideDirection,
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
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, child) {
              // How far the pill has traveled away from this segment's
              // resting spot — 0 when the pill sits under this segment,
              // growing as it slides toward the other one. Driving the
              // label's own translate/fade off this makes the content
              // move WITH the pill instead of hard-cutting color.
              final delta = (progress.value - restValue).abs().clamp(0.0, 1.0);
              final dx = slideDirection * delta * 8.0;
              final opacity = 1.0 - (delta * 0.25);

              return Transform.translate(
                offset: Offset(dx, 0),
                child: Opacity(opacity: opacity, child: child),
              );
            },
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
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
                          padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
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
        ),
      ),
    );
  }
}

/*
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
            child: FittedBox(
              fit: BoxFit.scaleDown,

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
      ),
    );
  }
}
*/
