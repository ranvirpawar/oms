// Custom painter for scanner overlay
import 'package:flutter/material.dart';

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanAreaSize = 250.0;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bracketLength = 30.0;

    // Top-left
    canvas.drawLine(Offset(left, top + bracketLength), Offset(left, top), bracketPaint);
    canvas.drawLine(Offset(left, top), Offset(left + bracketLength, top), bracketPaint);

    // Top-right
    canvas.drawLine(Offset(left + scanAreaSize - bracketLength, top),
        Offset(left + scanAreaSize, top), bracketPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top),
        Offset(left + scanAreaSize, top + bracketLength), bracketPaint);

    // Bottom-left
    canvas.drawLine(Offset(left, top + scanAreaSize - bracketLength),
        Offset(left, top + scanAreaSize), bracketPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize),
        Offset(left + bracketLength, top + scanAreaSize), bracketPaint);

    // Bottom-right
    canvas.drawLine(Offset(left + scanAreaSize - bracketLength, top + scanAreaSize),
        Offset(left + scanAreaSize, top + scanAreaSize), bracketPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize - bracketLength),
        Offset(left + scanAreaSize, top + scanAreaSize), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}