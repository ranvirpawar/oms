import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';


class FacilityCardShimmer extends StatelessWidget {
  const FacilityCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildShimmerFacilityCard(),
    );
  }

  Widget _buildShimmerFacilityCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Placeholder (No Shimmer)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration:  BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Facility Icon Placeholder
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Facility Name Placeholder
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Patient Count Placeholder
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Data Table Placeholder (No Shimmer)
          _buildShimmerDataTable(),
        ],
      ),
    );
  }

  Widget _buildShimmerDataTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        // Header Row
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          children: [
            _buildShimmerTableHeader(),
            _buildShimmerTableHeader(),
            _buildShimmerTableHeader(),
          ],
        ),
        // P Row
        TableRow(
          children: [
            _buildShimmerTableCell(true),
            _buildShimmerTableCell(),
            _buildShimmerTableCell(),
          ],
        ),
        // R Row
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[25],
          ),
          children: [
            _buildShimmerTableCell(true),
            _buildShimmerTableCell(),
            _buildShimmerTableCell(),
          ],
        ),
        // L Row
        TableRow(
          children: [
            _buildShimmerTableCell(true),
            _buildShimmerTableCell(),
            _buildShimmerTableCell(),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerTableHeader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Container(
          width: 50,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerTableCell([bool hasDot = false]) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (hasDot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              width: hasDot ? 80 : 40,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
