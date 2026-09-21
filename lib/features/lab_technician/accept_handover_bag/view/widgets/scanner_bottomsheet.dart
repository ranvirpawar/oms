import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../../theme/app_colors.dart';
import '../../controller/accept_bag_controller.dart';

import 'package:get/get.dart';






class ScannerOverlayPainter extends CustomPainter {
  // take size from input

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

    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final cornerLength = 30.0;

    void drawCorner(Offset start, Offset end) {
      canvas.drawLine(start, end, cornerPaint);
    }

    drawCorner(Offset(left, top + cornerLength), Offset(left, top));
    drawCorner(Offset(left, top), Offset(left + cornerLength, top));
    drawCorner(Offset(left + scanAreaSize - cornerLength, top),
        Offset(left + scanAreaSize, top));
    drawCorner(Offset(left + scanAreaSize, top),
        Offset(left + scanAreaSize, top + cornerLength));
    drawCorner(Offset(left, top + scanAreaSize - cornerLength),
        Offset(left, top + scanAreaSize));
    drawCorner(Offset(left, top + scanAreaSize),
        Offset(left + cornerLength, top + scanAreaSize));
    drawCorner(Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
        Offset(left + scanAreaSize, top + scanAreaSize));
    drawCorner(Offset(left + scanAreaSize, top + scanAreaSize),
        Offset(left + scanAreaSize, top + scanAreaSize - cornerLength));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnimatedScanLine extends StatefulWidget {
  final double height;
  final double width;

  const AnimatedScanLine(
      {super.key, required this.height, required this.width});

  @override
  State<AnimatedScanLine> createState() => _AnimatedScanLineState();
}

class _AnimatedScanLineState extends State<AnimatedScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: this)
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: widget.height)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => CustomPaint(
            painter: ScanLinePainter(
                position: _animation.value, width: widget.width)),
      ),
    );
  }
}

class ScanLinePainter extends CustomPainter {
  final double position;
  final double width;

  ScanLinePainter({required this.position, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(colors: [
        Colors.transparent,
        AppColors.primary.withOpacity(1),
        Colors.transparent
      ], stops: const [
        0.0,
        0.5,
        1.0
      ]).createShader(Rect.fromLTWH(0, position - 2, width, 4))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, position), Offset(width, position), paint);
  }

  @override
  bool shouldRepaint(ScanLinePainter oldDelegate) =>
      oldDelegate.position != position;
}
