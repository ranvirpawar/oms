
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';

class PatientProfileCardShimmer extends StatelessWidget {
  const PatientProfileCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.primary700.withOpacity(0.1);
    // final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade300;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          _shimmerHeader(context),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerLine(width: 180), // Beneficiary ID
                const SizedBox(height: 16),
                _shimmerDoubleRow(), // Mobile + Gender
                const SizedBox(height: 16),
                _shimmerLine(width: 120), // Age
                const SizedBox(height: 16),
                _shimmerDoubleRow(), // District + Mandal
                const SizedBox(height: 16),
                _shimmerLine(width: double.infinity, height: 40), // Address
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Circle avatar shimmer
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name shimmer
          _shimmerLine(width: 140, height: 18),
          const Spacer(),
          // Tag shimmer
          _shimmerLine(width: 50, height: 20),
        ],
      ),
    );
  }

  Widget _shimmerLine({double width = double.infinity, double height = 16}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _shimmerDoubleRow() {
    return Row(
      children: [
        Expanded(child: _shimmerLine(height: 20)),
        const SizedBox(width: 16),
        Expanded(child: _shimmerLine(height: 20)),
      ],
    );
  }
}
