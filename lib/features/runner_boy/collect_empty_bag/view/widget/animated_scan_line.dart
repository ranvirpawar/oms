
import 'package:flutter/material.dart';
import 'package:lifenity_connect/features/runner_boy/collect_empty_bag/view/widget/scan_line_painter.dart';

/// ---------------------------------------------------------------
/// 1. Animated scan line with bounce (top to bottom to top)
/// ---------------------------------------------------------------
class AnimatedScanLine extends StatefulWidget {
  final double width;
  final double height;
  const AnimatedScanLine({super.key, this.width=250, this.height=250});

  @override
  State<AnimatedScanLine> createState() => AnimatedScanLineState();
}

class AnimatedScanLineState extends State<AnimatedScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // total round-trip time
    )..repeat(); // loops forever

    // 0 to 0.5 → 0 to 1
    // 0.5 to 1 → 1 to 0
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 1, // 50% of the total duration
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 1, // the other 50%
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ScanLinePainter(_bounceAnimation.value),
          child:  SizedBox(width:widget.width, height: widget.height),
        );
      },
    );
  }
}


