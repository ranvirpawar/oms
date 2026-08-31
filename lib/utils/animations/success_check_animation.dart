// success_check_animation.dart
import 'package:flutter/material.dart';

class SuccessCheckAnimation extends StatefulWidget {
  final Duration scaleDuration;
  final Duration wiggleDuration;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;

  const SuccessCheckAnimation({
    super.key,
    this.scaleDuration = const Duration(milliseconds: 800),
    this.wiggleDuration = const Duration(milliseconds: 600),
    this.iconSize = 70,
    this.backgroundColor = const Color(0xFFE8F5E9),
    this.iconColor = const Color(0xFF2E7D32),
  });

  @override
  State<SuccessCheckAnimation> createState() => _SuccessCheckAnimationState();
}

class _SuccessCheckAnimationState extends State<SuccessCheckAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _wiggleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _wiggleAnimation;

  @override
  void initState() {
    super.initState();

    // Scale Animation
    _scaleController = AnimationController(
      vsync: this,
      duration: widget.scaleDuration,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Wiggle Animation (starts after scale)
    _wiggleController = AnimationController(
      vsync: this,
      duration: widget.wiggleDuration,
    );

    _wiggleAnimation = Tween<double>(begin: -0.12, end: 0.12).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
    );

    // Start scale
    _scaleController.forward().then((_) {
      // Start wiggle after scale ends
      _wiggleController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _wiggleController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _wiggleController.isAnimating ? _wiggleAnimation.value : 0,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: widget.iconSize,
                color: widget.iconColor,
              ),
            ),
          ),
        );
      },
    );
  }
}