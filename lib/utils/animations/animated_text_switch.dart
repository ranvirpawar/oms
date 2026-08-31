import 'dart:ui';

import 'package:flutter/material.dart';

enum TextSwitchAnimationType {
  fade,
  typewriter,
  slide,
  scale,
  rotate,
  blur,
}

class AnimatedSwitchText extends StatefulWidget {
  /// First text to display
  final String text1;

  /// Second text to display
  final String text2;

  /// How long each text remains visible before switching
  final Duration displayDuration;

  /// How long the transition animation takes
  final Duration animationDuration;

  /// Animation style to use when switching texts
  final TextSwitchAnimationType animationType;

  /// Optional text style to apply
  final TextStyle? textStyle;

  /// Whether to automatically cycle between texts
  final bool autoCycle;

  /// Direction for slide animation ('horizontal' or 'vertical')
  final Axis slideDirection;

  /// Curve to use for the animations
  final Curve curve;

  const AnimatedSwitchText({
    super.key,
    required this.text1,
    required this.text2,
    this.displayDuration = const Duration(seconds: 4),
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationType = TextSwitchAnimationType.fade,
    this.textStyle,
    this.autoCycle = true,
    this.slideDirection = Axis.vertical,
    this.curve = Curves.easeInOut,
  });

  @override
  State<AnimatedSwitchText> createState() => _AnimatedSwitchTextState();
}

class _AnimatedSwitchTextState extends State<AnimatedSwitchText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFirst = true;
  late String _currentText;

  // For typewriter effect
  late Animation<int> _typewriterAnimation;
  final String _typewriterText = '';

  // For blur effect
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _currentText = widget.text1;

    _controller =
        AnimationController(vsync: this, duration: widget.animationDuration);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFirst = !_showFirst;
          _currentText = _showFirst ? widget.text1 : widget.text2;
          _controller.value = 0.0;
        });
      }
    });

    _setupAnimations();

    if (widget.autoCycle) {
      _setupCycleTimer();
    }
  }

  void switchText() {
    _controller.forward(from: 0);
  }

  void _setupAnimations() {
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    // For typewriter effect
    final int maxLength = widget.text1.length > widget.text2.length
        ? widget.text1.length
        : widget.text2.length;
    _typewriterAnimation = IntTween(begin: 0, end: maxLength)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // For blur effect
    _blurAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
  }

  void _setupCycleTimer() {
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        switchText();
        _setupCycleTimer(); // Schedule next switch
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final textStyle = widget.textStyle ?? defaultStyle;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _buildAnimatedText(textStyle);
      },
    );
  }

  Widget _buildAnimatedText(TextStyle textStyle) {
    switch (widget.animationType) {
      case TextSwitchAnimationType.fade:
        return _buildFadeAnimatedText(textStyle);
      case TextSwitchAnimationType.typewriter:
        return _buildTypewriterAnimatedText(textStyle);
      case TextSwitchAnimationType.slide:
        return _buildSlideAnimatedText(textStyle);
      case TextSwitchAnimationType.scale:
        return _buildScaleAnimatedText(textStyle);
      case TextSwitchAnimationType.rotate:
        return _buildRotateAnimatedText(textStyle);
      case TextSwitchAnimationType.blur:
        return _buildBlurAnimatedText(textStyle);
    }
  }

  Widget _buildFadeAnimatedText(TextStyle textStyle) {
    double opacity;
    String text;

    if (_animation.value <= 0.5) {
      // First half of animation: fade out current text
      opacity = 1.0 - (_animation.value * 2);
      text = _showFirst ? widget.text2 : widget.text1;
    } else {
      // Second half of animation: fade in new text
      opacity = (_animation.value - 0.5) * 2;
      text = _showFirst ? widget.text1 : widget.text2;
    }

    return Opacity(
      opacity: opacity,
      child: Text(
        text,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTypewriterAnimatedText(TextStyle textStyle) {
    if (_animation.value <= 0.5) {
      // First half - erase current text
      final String currentText = _showFirst ? widget.text1 : widget.text2;
      final int len = currentText.length;
      final int visibleChars = (len * (1 - _animation.value * 2)).round();
      return Text(
        currentText.substring(0, visibleChars.clamp(0, len)),
        style: textStyle,
      );
    } else {
      // Second half - type new text
      final String nextText = _showFirst ? widget.text2 : widget.text1;
      final int len = nextText.length;
      final int visibleChars = (len * (_animation.value - 0.5) * 2).round();
      return Text(
        nextText.substring(0, visibleChars.clamp(0, len)),
        style: textStyle,
      );
    }
  }

  Widget _buildSlideAnimatedText(TextStyle textStyle) {
    // Calculate slide offset
    final double slideValue = _animation.value;
    final double offset = widget.slideDirection == Axis.vertical ? 20.0 : 50.0;

    if (_animation.value <= 0.5) {
      // First half: slide out current text
      final String text = _showFirst ? widget.text1 : widget.text2;
      final double slideOffset = slideValue * 2 * offset;

      return Transform.translate(
        offset: widget.slideDirection == Axis.vertical
            ? Offset(0, slideOffset)
            : Offset(slideOffset, 0),
        child: Opacity(
          opacity: 1 - slideValue * 2,
          child: Text(text, style: textStyle),
        ),
      );
    } else {
      // Second half: slide in new text
      final String text = _showFirst ? widget.text2 : widget.text1;
      final double slideOffset = (1 - slideValue) * 2 * offset;

      return Transform.translate(
        offset: widget.slideDirection == Axis.vertical
            ? Offset(0, -offset + slideOffset)
            : Offset(-offset + slideOffset, 0),
        child: Opacity(
          opacity: (slideValue - 0.5) * 2,
          child: Text(text, style: textStyle),
        ),
      );
    }
  }

  Widget _buildScaleAnimatedText(TextStyle textStyle) {
    double scaleValue;
    double opacity;
    String text;

    if (_animation.value <= 0.5) {
      // First half: scale down current text
      scaleValue = 1.0 - (_animation.value * 0.5);
      opacity = 1.0 - (_animation.value * 2);
      text = _showFirst ? widget.text1 : widget.text2;
    } else {
      // Second half: scale up new text
      scaleValue = 0.5 + ((_animation.value - 0.5) * 0.5);
      opacity = (_animation.value - 0.5) * 2;
      text = _showFirst ? widget.text2 : widget.text1;
    }

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scaleValue,
        child: Text(
          text,
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildRotateAnimatedText(TextStyle textStyle) {
    double rotateValue;
    double opacity;
    String text;

    if (_animation.value <= 0.5) {
      // First half: rotate out current text
      rotateValue = _animation.value * 0.5;
      opacity = 1.0 - (_animation.value * 2);
      text = _showFirst ? widget.text1 : widget.text2;
    } else {
      // Second half: rotate in new text
      rotateValue = (1.0 - _animation.value) * 0.5;
      opacity = (_animation.value - 0.5) * 2;
      text = _showFirst ? widget.text2 : widget.text1;
    }

    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(rotateValue),
        child: Text(
          text,
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildBlurAnimatedText(TextStyle textStyle) {
    double sigma;
    String text;

    if (_animation.value <= 0.5) {
      // First half: blur out current text
      sigma = _animation.value * 10.0;
      text = _showFirst ? widget.text1 : widget.text2;
    } else {
      // Second half: blur in new text
      sigma = (1.0 - _animation.value) * 10.0;
      text = _showFirst ? widget.text2 : widget.text1;
    }

    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
      ),
      child: Text(
        text,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// Example usage:
// AnimatedSwitchText(
//   text1: "© 2025 YourApp",
//   text2: "Making life easier",
//   animationType: TextSwitchAnimationType.typewriter,
// )
