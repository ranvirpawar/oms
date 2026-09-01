import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';

/// Skeleton placeholder shown during the initial load.
///
/// A shimmering skeleton that mirrors the real card's layout keeps the
/// screen visually stable (no layout jump once data arrives) and reads as
/// "still working" rather than a generic blocking spinner.
class QueueLoadingSkeleton extends StatefulWidget {
  final int itemCount;

  const QueueLoadingSkeleton({super.key, this.itemCount = 4});

  @override
  State<QueueLoadingSkeleton> createState() => _QueueLoadingSkeletonState();
}

class _QueueLoadingSkeletonState extends State<QueueLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => _SkeletonCard(controller: _controller),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final AnimationController controller;

  const _SkeletonCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _bar(width: 48, height: 48, radius: 24, t: t),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(width: 140, height: 14, t: t),
                        const SizedBox(height: 8),
                        _bar(width: 90, height: 10, t: t),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _bar(width: double.infinity, height: 36, radius: 10, t: t),
              const SizedBox(height: 10),
              _bar(width: double.infinity, height: 44, radius: 10, t: t),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _bar(height: 40, radius: 12, t: t)),
                  const SizedBox(width: 8),
                  Expanded(child: _bar(height: 40, radius: 12, t: t)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bar({
    double? width,
    required double height,
    double radius = 6,
    required double t,
  }) {
    // Oscillate opacity to create a subtle "breathing" shimmer without
    // pulling in an external shimmer package.
    final opacity = 0.5 + 0.5 * (0.5 - (t - 0.5).abs()) * 2;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.outlineVariant.withOpacity(opacity.clamp(0.35, 1)),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
