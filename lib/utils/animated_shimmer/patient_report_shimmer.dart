import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PatientReportShimmer extends StatelessWidget {
  const PatientReportShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Shimmer for Collapsed Content
            _buildCollapsedContentShimmer(context),
            const SizedBox(height: 16),
            // Shimmer for Search Box
            _buildSearchBoxShimmer(context),
            const SizedBox(height: 16),
            // Shimmer for Report Card List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6, // Simulate 3 report cards
              itemBuilder: (context, index) => _buildReportCardShimmer(context, index + 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedContentShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(

              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white,
                ),
                const SizedBox(height: 2),
                Container(
                  width: 100,
                  height: 11,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 80,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
         /* const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            color: Colors.white,
          ),*/
        ],
      ),
    );
  }

  Widget _buildSearchBoxShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                color: Colors.white,
                margin: const EdgeInsets.only(left: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCardShimmer(BuildContext context, int srNo) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Name and Mobile Row
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 100,
                                  height: 14,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 80,
                                  height: 12,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Barcode and Visit Date Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 80,
                                  height: 12,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 80,
                                  height: 12,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Test Counts and Action Buttons
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}