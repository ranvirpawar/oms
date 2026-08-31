import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';


class FacilityListPageSkeleton extends StatelessWidget {


  const FacilityListPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [

        /// ---------------- DATE SELECTOR ----------------
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Row(
                children: [
                  SkeletonBox(height: 36, width: 36),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 10, width: 80),
                        SizedBox(height: 6),
                        SkeletonBox(height: 14, width: 160),
                      ],
                    ),
                  ),
                  SkeletonBox(height: 14, width: 14),
                ],
              ),
            ),
          ),
        ),

        /// ---------------- SEARCH + SORT ----------------
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                const SizedBox(height: 12),

                // Sort Chips
                const Row(
                  children: [
                    SkeletonBox(height: 20, width: 50),
                    SizedBox(width: 8),
                    SkeletonBox(height: 28, width: 70),
                    SizedBox(width: 8),
                    SkeletonBox(height: 28, width: 80),
                    SizedBox(width: 8),
                    SkeletonBox(height: 28, width: 60),
                  ],
                )
              ],
            ),
          ),
        ),

        /// ---------------- STATS HEADER ----------------
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(height: 14, width: 150),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _statSkeleton()),
                      const SizedBox(width: 12),
                      Expanded(child: _statSkeleton()),
                      const SizedBox(width: 12),
                      Expanded(child: _statSkeleton()),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),

        /// ---------------- FACILITY LIST ----------------
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _facilityCardSkeleton(),
              ),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }

  /// STAT CARD SKELETON
  static Widget _statSkeleton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          SkeletonBox(height: 24, width: 24),
          SizedBox(height: 8),
          SkeletonBox(height: 18, width: 40),
          SizedBox(height: 4),
          SkeletonBox(height: 10, width: 60),
        ],
      ),
    );
  }

  /// FACILITY CARD SKELETON
  static Widget _facilityCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              SkeletonBox(
                height: 24,
                width: 24,
                radius: BorderRadius.all(Radius.circular(12)),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SkeletonBox(height: 14, width: double.infinity),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _metricSkeleton()),
              const SizedBox(width: 10),
              Expanded(child: _metricSkeleton()),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _metricSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          SkeletonBox(height: 16, width: 16),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, width: 40),
                SizedBox(height: 4),
                SkeletonBox(height: 10, width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryDashboardSkeleton extends StatelessWidget {
  const SummaryDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              /// -------- Facility Navigation Card --------
              _facilityNavigationSkeleton(),
              const SizedBox(height: 24),

              /// -------- Hero Metrics --------
              _heroMetricsSkeleton(),
              const SizedBox(height: 24),

              /// -------- Monthly Report --------
              _monthlyReportSkeleton(),
              const SizedBox(height: 24),

              /// -------- TAT Performance --------
              _tatSkeleton(),
              const SizedBox(height: 50),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _facilityNavigationSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          SkeletonBox(height: 32, width: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, width: 160),
                SizedBox(height: 6),
                SkeletonBox(height: 10, width: 120),
              ],
            ),
          ),
          SkeletonBox(height: 14, width: 14),
        ],
      ),
    );
  }

  Widget _heroMetricsSkeleton() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          /// Header
          Container(
            height: 45,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              color: Colors.grey,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _heroCardSkeleton(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _heroCardSkeleton()),
                    const SizedBox(width: 16),
                    Expanded(child: _heroCardSkeleton()),
                  ],
                ),
                const SizedBox(height: 16),
                _processingSkeleton(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _heroCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _innerCardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(height: 24, width: 24),
              Spacer(),
              SkeletonBox(height: 18, width: 60),
            ],
          ),
          SizedBox(height: 12),
          SkeletonBox(height: 12, width: 120),
        ],
      ),
    );
  }

  Widget _processingSkeleton() {
    return const Column(
      children: [
        Row(
          children: [
            SkeletonBox(height: 14, width: 150),
            Spacer(),
            SkeletonBox(height: 14, width: 50),
          ],
        ),
        SizedBox(height: 16),
        SkeletonBox(height: 10, width: double.infinity),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 14, width: 80)),
            Expanded(child: SkeletonBox(height: 14, width: 80)),
          ],
        ),
      ],
    );
  }

  Widget _monthlyReportSkeleton() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 45,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              color: Colors.grey,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SkeletonBox(height: 200, width: double.infinity),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: SkeletonBox(height: 60, width: double.infinity)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonBox(height: 60, width: double.infinity)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonBox(height: 60, width: double.infinity)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _tatSkeleton() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 45,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              color: Colors.grey,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: SkeletonBox(height: 60, width: double.infinity)),
                SizedBox(width: 16),
                Expanded(child: SkeletonBox(height: 60, width: double.infinity)),
              ],
            ),
          )
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
  );

  BoxDecoration _innerCardDecoration() => BoxDecoration(
    color: const Color(0xFFF3F4F6),
    borderRadius: BorderRadius.circular(12),
  );
}
class FacilityTypeDashboardSkeleton extends StatelessWidget {
  const FacilityTypeDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [

        /// Date Selector
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: const Row(
                children: [
                  SkeletonBox(height: 36, width: 36),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 10, width: 80),
                        SizedBox(height: 6),
                        SkeletonBox(height: 14, width: 150),
                      ],
                    ),
                  ),
                  SkeletonBox(height: 14, width: 14),
                ],
              ),
            ),
          ),
        ),

        /// Search Bar
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: SkeletonBox(height: 48, width: double.infinity),
          ),
        ),

        /// Summary Stats
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecorationStatic(),
              child: const Row(
                children: [
                  Expanded(child: SkeletonBox(height: 70, width: double.infinity)),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonBox(height: 70, width: double.infinity)),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonBox(height: 70, width: double.infinity)),
                ],
              ),
            ),
          ),
        ),

        /// Facility Cards List
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _facilityCardSkeleton(),
              ),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _facilityCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecorationStatic(),
      child: const Column(
        children: [
          Row(
            children: [
              SkeletonBox(height: 28, width: 28),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 14, width: double.infinity)),
              SizedBox(width: 8),
              SkeletonBox(height: 14, width: 14),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 40, width: double.infinity)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 40, width: double.infinity)),
            ],
          )
        ],
      ),
    );
  }

  static BoxDecoration _cardDecorationStatic() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
  );
}



class SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? radius;

  const SkeletonBox({
    super.key,
    required this.height,
    required this.width,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}
