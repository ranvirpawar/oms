import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SampleRemarkShimmer extends StatelessWidget {
  const SampleRemarkShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // 🔹 Date Card Shimmer
        _buildCardShimmer(height: 60, margin: const EdgeInsets.all(16)),

        const SizedBox(height: 16),

        // 🔹 Facility Name Dropdown Shimmer
        _buildCardShimmer(height: 55, margin: const EdgeInsets.symmetric(horizontal: 16)),

        const SizedBox(height: 16),

        // 🔹 Reason Dropdown Shimmer
        _buildCardShimmer(height: 55, margin: const EdgeInsets.symmetric(horizontal: 16)),

        const SizedBox(height: 16),

        // 🔹 Sample Count Card Shimmer
        _buildCardShimmer(height: 90, margin: const EdgeInsets.symmetric(horizontal: 16)),

        const SizedBox(height: 16),
        const Spacer(),

        // 🔹 Submit Button Shimmer
        _buildCardShimmer(height: 48, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20)),
      ],
    );
  }

  Widget _buildCardShimmer({required double height, EdgeInsets? margin}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: double.infinity,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
