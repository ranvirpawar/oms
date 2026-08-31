// ─────────────────────────────────────────────────────────────────────────────
// consumption_skeleton.dart
//
// Shows shimmer-style placeholder cards while data is loading.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class ConsumptionSkeleton extends StatefulWidget {
  const ConsumptionSkeleton({super.key});

  @override
  State<ConsumptionSkeleton> createState() => _ConsumptionSkeletonState();
}

class _ConsumptionSkeletonState extends State<ConsumptionSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(); // Repeat forever

    _shimmerAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: 3,
          itemBuilder: (_, index) => _SkeletonCard(
            shimmerX: _shimmerAnimation.value,
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double shimmerX;

  const _SkeletonCard({required this.shimmerX});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header placeholder
          Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment(shimmerX - 0.5, 0),
                end: Alignment(shimmerX + 0.5, 0),
                colors: const [
                  Color(0xFFE2E8F0),
                  Color(0xFFF8FAFC),
                  Color(0xFFE2E8F0),
                ],
              ),
            ),
          ),
          // Category rows
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(3, (i) => _shimmerRow(shimmerX, i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerRow(double shimmerX, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBox(shimmerX, width: 80, height: 12),
              const Spacer(),
              _shimmerBox(shimmerX, width: 60, height: 12),
            ],
          ),
          const SizedBox(height: 8),
          _shimmerBox(shimmerX, width: double.infinity, height: 7),
        ],
      ),
    );
  }

  Widget _shimmerBox(double shimmerX,
      {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        gradient: LinearGradient(
          begin: Alignment(shimmerX - 0.5, 0),
          end: Alignment(shimmerX + 0.5, 0),
          colors: const [
            Color(0xFFE2E8F0),
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
          ],
        ),
      ),
    );
  }
}
