import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CalendarShimmerWidget extends StatelessWidget {
  const CalendarShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // // app bar height
          const SizedBox(height: kToolbarHeight-6),

          _buildCalendarShimmer(context),
          const SizedBox(height: 16),
          // Selected Date Card Shimmer
          _buildSelectedDateShimmer(context),
        ],
      ),
    );
  }

  Widget _buildCalendarHeaderShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(5),

            ),

          ),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 100,
              height: 16,
              color: Colors.grey[300],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(5),

            ),

          ),
        ],
      ),
    );
  }

  Widget _buildCalendarShimmer(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildCalendarHeaderShimmer(context),
            const SizedBox(height: 10),
            Table(
              children: [
                // Weekday headers
                TableRow(
                  children: List.generate(
                    7,
                        (index) => Container(
                      margin: const EdgeInsets.all(4),
                      height: 12,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                // Calendar days (5 rows to simulate a month)
                ...List.generate(
                  5,
                      (rowIndex) => TableRow(
                    children: List.generate(
                      7,
                          (colIndex) => Container(
                        margin: const EdgeInsets.symmetric(horizontal:6, vertical: 2),
                        padding: const EdgeInsets.all(4),
                        height: 49,




                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 10,
                                height: 10,
                                color: Colors.grey[300],
                              ),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateShimmer(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date and Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    color: Colors.grey[300],
                  ),
                  Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Summary Cards
              Row(
                children: List.generate(
                  3,
                      (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 12,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: 16,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Progress Bar Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 100,
                    height: 12,
                    color: Colors.grey[300],
                  ),
                  Container(
                    width: 40,
                    height: 12,
                    color: Colors.grey[300],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}