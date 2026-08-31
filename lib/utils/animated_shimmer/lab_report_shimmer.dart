import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LabReportShimmer extends StatelessWidget {
  const LabReportShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 6,
            itemBuilder: (context, index) {
              return _buildShimmerCard(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final baseColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
    final highlightColor = Colors.grey.shade300;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? const Color.fromARGB(255, 30, 30, 40) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Collection Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildCircle(height: 24, width: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBox(width: 100, height: 14),
                          const SizedBox(height: 4),
                          _buildBox(width: 80, height: 14),
                        ],
                      ),
                    ],
                  ),
                  _buildBox(width: 50, height: 20),
                ],
              ),
              const SizedBox(height: 16),

              // Barcode and Consultant Row
              Row(
                children: [
                  // Barcode
                  Expanded(
                    child: Row(
                      children: [
                        _buildCircle(height: 24, width: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBox(width: 80, height: 14),
                            const SizedBox(height: 4),
                            _buildBox(width: 100, height: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Consultant
                  Expanded(
                    child: Row(
                      children: [
                        _buildCircle(height: 24, width: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBox(width: 80, height: 14),
                            const SizedBox(height: 4),
                            _buildBox(width: 100, height: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status and Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBox(width: 100, height: 20),
                  Row(
                    children: [
                      _buildCircle(height: 32, width: 32),
                      const SizedBox(width: 16),
                      _buildCircle(height: 32, width: 32),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBox({double width = 100, double height = 14}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildCircle({double width = 24, double height = 24}) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
