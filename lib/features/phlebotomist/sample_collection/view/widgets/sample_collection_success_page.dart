import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../routes/route_manager.dart';
import '../../controller/sample_collection_controller.dart';
import '../../model/sample_collection_models.dart';

// import 'sample_collection_controller.dart';
// import 'sample_collection_models.dart';
// import 'route_manager.dart'; // wherever RouteManager already lives

/// Terminal screen for the collection flow. No back button, no swipe-back —
/// the collector's only way out is the Done button at the bottom.
class SampleCollectionSuccessPage extends StatelessWidget {
  const SampleCollectionSuccessPage({
    super.key,
    required this.controller,
    required this.result,
  });

  final SampleCollectionController controller;
  final SampleSubmissionResult result;

  void _onDonePressed(BuildContext context) {
    if (result.needsDishaSync && !controller.dishaSyncResolved.value) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('LIS sync pending'),
          content: const Text(
            'This order hasn\'t synced to LIS yet. You can finish now and '
                'sync it later, or stay and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () {
                Get.back();
                _finish();
              },
              child: const Text('Finish anyway'),
            ),
          ],
        ),
      );
      return;
    }
    _finish();
  }

  void _finish() {
    RouteManager.redirectToHomeDashboard();
    RouteManager.navigateToPatientQueue();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const _AnimatedCheckCircle(size: 128),
                      const SizedBox(height: 28),
                      _FadeSlideIn(
                        child: Column(
                          children: [
                            Text(
                              'Sample Collection Complete',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Order #${result.orderId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (result.needsDishaSync)
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: _DishaSyncCard(
                            controller: controller,
                            result: result,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _DoneButtonBar(onPressed: () => _onDonePressed(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, c) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 14),
          child: c,
        ),
      ),
      child: child,
    );
  }
}

class _AnimatedCheckCircle extends StatefulWidget {
  const _AnimatedCheckCircle({this.size = 120});
  final double size;

  @override
  State<_AnimatedCheckCircle> createState() => _AnimatedCheckCircleState();
}

class _AnimatedCheckCircleState extends State<_AnimatedCheckCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScale;
  late final Animation<double> _checkProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _circleScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _checkProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.scale(
          scale: _circleScale.value.clamp(0.0, 1.15),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _CheckCirclePainter(progress: _checkProgress.value),
            ),
          ),
        );
      },
    );
  }
}

class _CheckCirclePainter extends CustomPainter {
  _CheckCirclePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    final checkPath = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.34);

    final metrics = checkPath.computeMetrics().first;
    final extractPath = metrics.extractPath(0, metrics.length * progress);

    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(extractPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckCirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DishaSyncCard extends StatelessWidget {
  const _DishaSyncCard({required this.controller, required this.result});
  final SampleCollectionController controller;
  final SampleSubmissionResult result;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final resolved = controller.dishaSyncResolved.value;
      final isLoading = controller.isRetryingDisha.value;
      final message = controller.dishaRetryMessage.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: resolved ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: resolved ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  resolved ? Icons.verified_rounded : Icons.sync_problem_rounded,
                  color: resolved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    resolved
                        ? 'Synced to Disha'
                        : 'Order saved — Disha sync pending',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: resolved
                          ? const Color(0xFF065F46)
                          : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              resolved
                  ? (message.isEmpty
                  ? 'This order is now synced to Disha.'
                  : message)
                  : 'The sample data was saved, but the push to Disha failed. '
                  'You can retry now or later from the queue.',
              style: TextStyle(
                fontSize: 13,
                color:
                resolved ? const Color(0xFF065F46) : const Color(0xFF92400E),
              ),
            ),
            if (!resolved) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : controller.retryDishaSubmission,
                  icon: isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.cloud_sync_rounded, size: 18),
                  label: Text(isLoading ? 'Syncing…' : 'Sync to Disha'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF92400E),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (message.isNotEmpty && !isLoading) ...[
                const SizedBox(height: 6),
                Text(message,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB45309))),
              ],
            ],
          ],
        ),
      );
    });
  }
}

class _DoneButtonBar extends StatelessWidget {
  const _DoneButtonBar({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text(
            'Done',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }
}