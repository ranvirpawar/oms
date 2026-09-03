import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Purely presentational scanner sheet. Lifecycle (start/stop/dispose) of the
/// [MobileScannerController] is still owned by the controller — this widget
/// just renders it with an Apple-style frame, torch, and camera-flip controls.
class BarcodeScannerSheet extends StatelessWidget {
  final String sampleType;
  final MobileScannerController scannerController;
  final ValueChanged<String> onCodeDetected;
  final VoidCallback onClose;

  const BarcodeScannerSheet({
    super.key,
    required this.sampleType,
    required this.scannerController,
    required this.onCodeDetected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Scan $sampleType barcode',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: scannerController,
                      onDetect: (capture) {
                        for (final barcode in capture.barcodes) {
                          if (barcode.rawValue != null) {
                            onCodeDetected(barcode.rawValue!);
                            break;
                          }
                        }
                      },
                    ),
                    const IgnorePointer(child: _ScanFrame()),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: _RoundIconButton(
                        icon: Icons.flash_on_rounded,
                        onTap: () => scannerController.toggleTorch(),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: _RoundIconButton(
                        icon: Icons.cameraswitch_rounded,
                        onTap: () => scannerController.switchCamera(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Align the barcode within the frame',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScanFramePainter());
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const inset = 32.0;
    const cornerLen = 22.0;
    final rect = Rect.fromLTWH(inset, size.height / 2 - 70, size.width - inset * 2, 140);

    void corner(Offset a, Offset b, Offset c) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy);
      canvas.drawPath(path, paint);
    }

    corner(Offset(rect.left, rect.top + cornerLen), rect.topLeft, Offset(rect.left + cornerLen, rect.top));
    corner(Offset(rect.right - cornerLen, rect.top), rect.topRight, Offset(rect.right, rect.top + cornerLen));
    corner(Offset(rect.left, rect.bottom - cornerLen), rect.bottomLeft, Offset(rect.left + cornerLen, rect.bottom));
    corner(Offset(rect.right - cornerLen, rect.bottom), rect.bottomRight, Offset(rect.right, rect.bottom - cornerLen));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}