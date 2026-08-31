import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../../theme/app_colors.dart';
import '../../controller/accept_bag_controller.dart';
import '../../model/accept_bag_model.dart';
import 'package:get/get.dart';



class ScannerBottomSheet extends StatelessWidget {
  final AcceptBagController controller;

  const ScannerBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  //  HEADER
  // -----------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Scan Bag QR Code',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                          'Bag: ${controller.selectedBag.value?.bagcode ?? ""}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13),
                        )),
                  ],
                ),
              ),
              Row(
                children: [
                  // Flash
                  Obx(() => IconButton(
                        onPressed: controller.toggleFlash,
                        icon: Icon(
                          controller.isTorchOn.value
                              ? Icons.flash_on
                              : Icons.flash_off,
                          color: controller.isTorchOn.value
                              ? Colors.yellow
                              : Colors.white,
                        ),
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2)),
                      )),
                  const SizedBox(width: 8),
                  // Close (always visible)
                  IconButton(
                    onPressed: controller.stopScanning,
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  //  BODY – reacts to every state
  // -----------------------------------------------------------------
  Widget _buildBody() {
    return Obx(() {
      final state = controller.acceptBagState.value;

      // ---------- SCANNING ----------
      if (state == AcceptBagState.scanning) {
        return Stack(
          children: [
            // Camera preview (fade-in)
            if (controller.scannerController.value != null)
              FadeTransition(
                opacity: const AlwaysStoppedAnimation(1),
                child: MobileScanner(
                  controller: controller.scannerController.value!,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.firstOrNull?.rawValue;
                    if (barcode != null) controller.handleBarcodeScan(barcode);
                  },
                ),
              )
            else
              const _CameraPlaceholder(),

            // Overlay + scan line
            CustomPaint(
              painter: ScannerOverlayPainter(),
              child: const Center(
                  child: AnimatedScanLine(height: 250, width: 250)),
            ),

            // Instructions
            const Positioned(
                bottom: 20, left: 20, right: 20, child: _Instructions()),
          ],
        );
      }

      // ---------- PROCESSING ----------
      if (state == AcceptBagState.processing) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Verifying bag…',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        );
      }

      // ---------- SUCCESS ----------
      if (state == AcceptBagState.success) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text('Bag accepted!',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ],
          ),
        );
      }

      // ---------- ERROR ----------
      // (also used for wrong-bag)
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 56),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage.value.isEmpty
                    ? 'Something went wrong'
                    : controller.errorMessage.value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ---- BIG RETRY / CLOSE BUTTONS ----
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: controller.retryScanning,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text(
                      'Retry',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: controller.stopScanning,
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      // Fallback
      // ignore: dead_code
      return const _CameraPlaceholder();
    });
  }
}


class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Icon(Icons.photo_camera, color: Colors.white54, size: 48),
      ),
    );
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
          SizedBox(height: 12),
          Text('Position the QR code within the frame',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          SizedBox(height: 8),
          Text(
            'The scanner will automatically detect the code',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


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
