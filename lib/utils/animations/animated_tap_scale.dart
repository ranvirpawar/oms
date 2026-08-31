import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AnimatedTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleValue;
  final Duration duration;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;

  const AnimatedTapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleValue = 0.97,
    this.duration = const Duration(milliseconds: 150),
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
  });

  @override
  State<AnimatedTapScale> createState() => _AnimatedTapScaleState();
}

class _AnimatedTapScaleState extends State<AnimatedTapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleValue,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
            splashColor: widget.splashColor ?? AppColors.primary.withOpacity(0.1),
            highlightColor: widget.highlightColor ?? AppColors.primary.withOpacity(0.05),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}