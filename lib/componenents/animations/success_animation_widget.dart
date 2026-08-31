import 'dart:math';
import 'package:flutter/material.dart';

/// A modern, sequenced success animation widget.
///
/// Animation sequence:
///   1. Scale up from 0 → 1.15 (pop in)
///   2. Scale down to 0.92 (settle)
///   3. Scale back to 1.0 (land)
///   4. Wiggle (rotate ±8°, three times, dampening)
///   5. Idle pulse (subtle breathe loop)
///
/// Usage:
///   SuccessAnimationWidget(
///     size: 120,
///     onAnimationComplete: () => debugPrint('done'),
///   )
class SuccessAnimationWidget extends StatefulWidget {
  final double size;
  final Color? primaryColor;
  final Color? iconColor;
  final VoidCallback? onAnimationComplete;

  const SuccessAnimationWidget({
    super.key,
    this.size = 120,
    this.primaryColor,
    this.iconColor,
    this.onAnimationComplete,
  });

  @override
  State<SuccessAnimationWidget> createState() => _SuccessAnimationWidgetState();
}

class _SuccessAnimationWidgetState extends State<SuccessAnimationWidget>
    with TickerProviderStateMixin {

  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _scaleController;
  late final AnimationController _wiggleController;
  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  late final AnimationController _checkController;

  // ── Scale animations ─────────────────────────────────────────────────────
  late final Animation<double> _scaleAnim;

  // ── Wiggle ───────────────────────────────────────────────────────────────
  late final Animation<double> _wiggleAnim;

  // ── Pulse (idle breathe) ─────────────────────────────────────────────────
  late final Animation<double> _pulseAnim;

  // ── Expanding ring ───────────────────────────────────────────────────────
  late final Animation<double> _ringScaleAnim;
  late final Animation<double> _ringOpacityAnim;

  // ── Check draw ───────────────────────────────────────────────────────────
  late final Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runSequence();
  }

  void _setupAnimations() {
    // Scale: pop-in with overshoot
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 0.90)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.90, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_scaleController);

    // Wiggle: dampened rotation oscillation
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _wiggleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -7.0), weight: 22),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 5.5), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 5.5, end: -3.5), weight: 18),
      TweenSequenceItem(tween: Tween(begin: -3.5, end: 2.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.0), weight: 13),
    ]).animate(CurvedAnimation(
      parent: _wiggleController,
      curve: Curves.linear,
    ));

    // Pulse: subtle idle breathe, loops forever
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.055)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.055, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50),
    ]).animate(_pulseController);

    // Expanding ring burst
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ringScaleAnim = Tween<double>(begin: 0.6, end: 1.8).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );
    _ringOpacityAnim = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeIn),
    );

    // Check draw progress
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _checkAnim = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 80));

    // Fire ring burst and scale-in together
    _ringController.forward();
    await _scaleController.forward();

    // Draw check tick
    await _checkController.forward();

    // Wiggle
    await _wiggleController.forward();

    // Start idle pulse loop
    _pulseController.repeat();

    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _wiggleController.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ??  Colors.green.shade600;
    final iconColor = widget.iconColor ?? Colors.white;
    final size = widget.size;

    return SizedBox(
      width: size * 1.8,
      height: size * 1.8,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleController,
            _wiggleController,
            _pulseController,
            _ringController,
            _checkController,
          ]),
          builder: (context, _) {
            final scale = _scaleController.isCompleted && _wiggleController.isCompleted
                ? _pulseAnim.value
                : _scaleAnim.value;

            final rotateDeg = _wiggleController.isAnimating
                ? _wiggleAnim.value
                : 0.0;

            return Stack(
              alignment: Alignment.center,
              children: [
                // ── Expanding ring burst ──────────────────────────────
                if (_ringController.isAnimating || _ringController.isCompleted)
                  Opacity(
                    opacity: _ringOpacityAnim.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _ringScaleAnim.value,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withOpacity(0.6),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Second ring (staggered) ───────────────────────────
                if (_ringController.value > 0.2)
                  Opacity(
                    opacity: ((_ringOpacityAnim.value - 0.15) * 1.5).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: (_ringScaleAnim.value * 0.75).clamp(0.0, 2.0),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withOpacity(0.35),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Main circle + check ───────────────────────────────
                Transform.rotate(
                  angle: rotateDeg * pi / 180,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            color,
                            Color.lerp(color, Colors.white, 0.15)!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.45),
                            blurRadius: size * 0.35,
                            offset: Offset(0, size * 0.12),
                          ),
                          BoxShadow(
                            color: color.withOpacity(0.15),
                            blurRadius: size * 0.6,
                            offset: Offset(0, size * 0.05),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _CheckPainter(
                          progress: _checkAnim.value,
                          color: iconColor,
                          strokeWidth: size * 0.075,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Check painter — draws the tick progressively ─────────────────────────────

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _CheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Check path: two segments
    // Segment 1: short leg (left-bottom)
    // Segment 2: long leg (up-right)
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    final p1 = Offset(cx - size.width * 0.22, cy + size.height * 0.02);
    final p2 = Offset(cx - size.width * 0.04, cy + size.height * 0.20);
    final p3 = Offset(cx + size.width * 0.26, cy - size.height * 0.18);

    // Total path length ratio: seg1 ~35%, seg2 ~65%
    const seg1Weight = 0.35;
    const seg2Weight = 0.65;

    final path = Path();

    if (progress <= seg1Weight) {
      final t = progress / seg1Weight;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(
        lerpDouble(p1.dx, p2.dx, t),
        lerpDouble(p1.dy, p2.dy, t),
      );
    } else {
      final t = (progress - seg1Weight) / seg2Weight;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(
        lerpDouble(p2.dx, p3.dx, t),
        lerpDouble(p2.dy, p3.dy, t),
      );
    }

    canvas.drawPath(path, paint);
  }

  double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}
