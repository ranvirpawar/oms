// Animated scan line painter
import 'package:flutter/material.dart';

class ScanLinePainter extends CustomPainter {
  final double progress;

  ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final y = size.height * progress;

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF4F46E5).withOpacity(0.0),
        const Color(0xFF4F46E5),
        const Color(0xFF4F46E5).withOpacity(0.0),
      ],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, y - 20, size.width, 40))
      ..strokeWidth = 2;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), gradientPaint);
  }

  @override
  bool shouldRepaint(ScanLinePainter oldDelegate) => oldDelegate.progress != progress;
}