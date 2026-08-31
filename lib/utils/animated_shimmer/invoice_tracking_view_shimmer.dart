import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class InvoiceTrackingShimmer extends StatelessWidget {
  const InvoiceTrackingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ward Dropdown
            _shimmerBox(height: 60, width: double.infinity),
            const SizedBox(height: 16),

            // Facility Dropdown
            _shimmerBox(height: 60, width: double.infinity),
            const SizedBox(height: 16),

            // Year and Month Row
            Row(
              children: [
                Expanded(child: _shimmerBox(height: 60)),
                const SizedBox(width: 16),
                Expanded(child: _shimmerBox(height: 60)),
              ],
            ),
            const SizedBox(height: 24),

            // Search Button
            _shimmerBox(height: 50, width: double.infinity, radius: 8),
            const SizedBox(height: 24),

          /*  // Section Title
            _shimmerBox(height: 20, width: 150),
            const SizedBox(height: 16),

            // Invoice Card List (simulating 3 items)
            ...List.generate(3, (index) => _invoiceCardShimmer()),*/
          ],
        ),
      ),
    );
  }

  // 🔹 Generic shimmer container
  static Widget _shimmerBox({
    double height = 20,
    double width = double.infinity,
    double radius = 12,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // 🔹 Simulate invoice card layout
  static Widget _invoiceCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row (facility + chip)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(height: 14, width: 120),
              _shimmerBox(height: 20, width: 50, radius: 8),
            ],
          ),
          const SizedBox(height: 12),

          // Invoice number row
          _infoRowShimmer(),
          const SizedBox(height: 8),

          // Current status row
          _infoRowShimmer(),
        ],
      ),
    );
  }

  // 🔹 Simulate info row (label + value)
  static Widget _infoRowShimmer() {
    return Row(
      children: [
        _shimmerBox(height: 12, width: 100),
        const SizedBox(width: 16),
        Expanded(child: _shimmerBox(height: 12, width: double.infinity)),
      ],
    );
  }
}
