import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/priority_indicator.dart';

import '../../../../../theme/app_colors.dart';
import '../../model/patient_queue_model.dart';


class PriorityCornerBadge extends StatelessWidget {
  final PriorityLevel priority;

  const PriorityCornerBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    if (priority == PriorityLevel.normal) return const SizedBox.shrink();
    final isUrgent = priority == PriorityLevel.urgent;
    final label = isUrgent ? 'Urgent' : 'Emergency';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(

        gradient: const LinearGradient(
          colors: [Color(0xFFB4413F), Color(0xFFE1706A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),

      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.0,
            ),
          ), const SizedBox(width: 5),
          const AnimatedPriorityBubble(size: 5, color: Colors.white),

        ],
      ),
    );
  }
}

/// A subtle pulsing animated bubble dot with an expanding outer aura.
class AnimatedPriorityBubble extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedPriorityBubble({
    super.key,
    this.size = 6.0,
    this.color = Colors.white,
  });

  @override
  State<AnimatedPriorityBubble> createState() => _AnimatedPriorityBubbleState();
}

class _AnimatedPriorityBubbleState extends State<AnimatedPriorityBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 1.1);
        final opacity = (1.0 - _controller.value).clamp(0.0, 1.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(opacity * 0.6),
                ),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A subtle, continuously moving gradient border — soft opacity, thin
/// stroke, slow drift. Meant to read as "alive" without shouting.
class MovingGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final List<Color> colors;
  final Duration duration;
  final bool enabled;

  const MovingGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 10,
    this.borderWidth = 1.2,
    this.colors = const [Color(0xFFE1706A), Color(0xFFFFD9D5), Color(0xFFE1706A)],
    this.duration = const Duration(milliseconds: 3400),
    this.enabled = true,
  });

  @override
  State<MovingGradientBorder> createState() => _MovingGradientBorderState();
}

class _MovingGradientBorderState extends State<MovingGradientBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.enabled) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Padding(padding: EdgeInsets.all(widget.borderWidth), child: widget.child);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MovingBorderPainter(
            t: _controller.value,
            radius: widget.borderRadius,
            width: widget.borderWidth,
            colors: widget.colors,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _MovingBorderPainter extends CustomPainter {
  final double t;
  final double radius;
  final double width;
  final List<Color> colors;

  _MovingBorderPainter({
    required this.t,
    required this.radius,
    required this.width,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(width / 2),
      Radius.circular(radius),
    );

    final angle = t * 2 * math.pi;
    final base = colors.first;
    final accent = colors.length > 1 ? colors[1] : colors.first;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = SweepGradient(
        colors: [
          base.withOpacity(0.10),
          accent.withOpacity(0.45),
          base.withOpacity(0.10),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(angle),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _MovingBorderPainter oldDelegate) =>
      oldDelegate.t != t;
}