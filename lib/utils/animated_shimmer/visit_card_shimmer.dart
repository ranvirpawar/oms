import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class VisitCardShimmerWidget extends StatelessWidget {
  final int count;

  const VisitCardShimmerWidget({
    super.key,
    this.count = 3, // Default to 3 shimmer cards
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Facility Name Shimmer
                  _buildShimmerInfoRow(context),
                  const SizedBox(height: 6),
                  // Type + Time Shimmer
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildShimmerInfoRow(context, widthFactor: 0.6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildShimmerInfoRow(context, widthFactor: 0.8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerInfoRow(BuildContext context, {double widthFactor = 1.0}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon placeholder
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Text placeholders
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title placeholder
              Container(
                width: 40,
                height: 12,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 4),
              // Value placeholder
              Container(
                width: MediaQuery.of(context).size.width * 0.2 * widthFactor,
                height: 14,
                color: Colors.grey[300],
              ),
            ],
          ),
        ],
      ),
    );
  }
}