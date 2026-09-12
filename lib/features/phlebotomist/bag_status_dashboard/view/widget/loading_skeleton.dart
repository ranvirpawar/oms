import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/view/widget/spacing_and_radius.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(BagDashboardSpacing.lg, BagDashboardSpacing.xl, BagDashboardSpacing.lg, 100),
      child: _Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                3,
                    (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? BagDashboardSpacing.md : 0),
                    child: const _SkeletonSummaryTile(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BagDashboardSpacing.xxl),
            const _SkeletonBox(width: 100, height: 18, radius: 6),
            const SizedBox(height: 14),
            const _SkeletonBagCard(),
            const SizedBox(height: 14),
            const _SkeletonBagCard(collapsed: true),
          ],
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final dx = _ctrl.value * 3 - 1.5; // sweep -1.5..1.5
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(-1 + dx, 0),
                end: Alignment(1 + dx, 0),
                colors: const [
                  Color(0xFFE9EEF3),
                  Color(0xFFF6F9FC),
                  Color(0xFFE9EEF3),
                ],
                stops: const [0.35, 0.5, 0.65],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonSummaryTile extends StatelessWidget {
  const _SkeletonSummaryTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: BagDashboardSpacing.lg, horizontal: BagDashboardSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BagDashboardRadius.lg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 30, height: 30, radius: 9),
          SizedBox(height: 10),
          _SkeletonBox(width: 36, height: 20, radius: 6),
          SizedBox(height: 6),
          _SkeletonBox(width: 50, height: 10, radius: 4),
        ],
      ),
    );
  }
}

class _SkeletonBagCard extends StatelessWidget {
  final bool collapsed;
  const _SkeletonBagCard({this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BagDashboardSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BagDashboardRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SkeletonBox(width: 44, height: 44, radius: 13),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SkeletonBox(width: 90, height: 14, radius: 4),
                    SizedBox(height: 8),
                    _SkeletonBox(width: 120, height: 10, radius: 4),
                  ],
                ),
              ),
            ],
          ),
          if (!collapsed) ...[
            const SizedBox(height: BagDashboardSpacing.xl),
            const _SkeletonBox(width: double.infinity, height: 8, radius: 8),
            const SizedBox(height: BagDashboardSpacing.lg),
            Row(
              children: const [
                Expanded(child: _SkeletonBox(width: double.infinity, height: 40, radius: BagDashboardRadius.sm)),
                SizedBox(width: 10),
                Expanded(child: _SkeletonBox(width: double.infinity, height: 40, radius: BagDashboardRadius.sm)),
                SizedBox(width: 10),
                Expanded(child: _SkeletonBox(width: double.infinity, height: 40, radius: BagDashboardRadius.sm)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}