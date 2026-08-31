import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/cms_eho/controller/summary_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/cms_eho/model/summary_model.dart';

import '../../../../constants/app_assets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../../../utils/animated_shimmer/summary_shimmer_class.dart';
import '../../../utils/animations/animated_tap_scale.dart';
import 'facility_type_dashboard.dart';

class SummaryDashboard extends StatelessWidget {
  final SummaryController controller = Get.put(SummaryController());

  SummaryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Summary Dashboard',
        actions: [],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const SummaryDashboardSkeleton();
        }

        final summary = controller.summary.value;
        final details = controller.details.value;
        if (summary == null || details == null) {
          return const Center(child: Text('Failed to load data'));
        }

        final facilityCount = summary.facilityCount;

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildFacilityTypeNavigationCard(),
                    const SizedBox(height: 24),
                    _buildHeroMetrics(summary, facilityCount),
                    const SizedBox(height: 24),
                    _buildTestingProgress(summary),
                    const SizedBox(height: 24),
                    _buildDetailedInsights(details),
                    const SizedBox(height: 50),
                  ]),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFacilityTypeNavigationCard() {
    return AnimatedTapScale(
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Get.to(() => FacilityTypeDashboard(),
                transition: Transition.circularReveal);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Image.asset(
                    AppAssets.hospitalFacilityIcon,
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Facility Wise Summary',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'View detailed analytics',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF9CA3AF),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroMetrics(SummaryModel summary, int facilityCount) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.primary800,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    AppAssets.infoIcon,
                    height: 18,
                    color: AppColors.surface,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Reports Till Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white, // Changed from Color(0xFF1E293B)
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${controller.summary.value?.countDate} ${summary.countTime}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70, // Added color for better contrast
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                        child: _buildHeroCard(
                            'Total Facilities',
                            facilityCount.toString(),
                            AppAssets.facility,
                            AppColors.primary,
                            ''))
                  ]),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroCard(
                          'Total Patients',
                          summary.patientCount.toString(),
                          AppAssets.patient,
                          AppColors.primary,
                          '+${summary.patientCountToday} today',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildHeroCard(
                          'Total Tests',
                          summary.testTotal.toString(),
                          AppAssets.testTube,
                          AppColors.primary,
                          '+${summary.testTotalToday} today',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProcessingStatusCard(summary),

                  // card showing number of facilities
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
      String title, String value, String icon, Color color, String subtitle) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: SvgPicture.asset(icon, color: color, height: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingStatusCard(SummaryModel summary) {
    final reportedCount = summary.reportedCount;
    final pendingCount = summary.reportedPendingCount;
    final totalTests = reportedCount + pendingCount;
    final completionRate =
        totalTests > 0 ? (reportedCount / totalTests) * 100 : 0;

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      AppAssets.infoIcon,
                      height: 14,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Report Processing Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${completionRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: completionRate / 100,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.emerald700,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Completed Tests',
                    summary.reportedCount.toString(),
                    AppColors.emerald700,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                      'Pending Tests',
                      summary.reportedPendingCount.toString(),
                      AppColors.secondary900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTestingProgress(SummaryModel summary) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.primary800,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    AppAssets.infoIcon,
                    height: 18,
                    color: AppColors.surface,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Monthly Sample Collection Report',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Chart
                  SizedBox(
                    height: 210,
                    child: _buildTrendChart(summary),
                  ),

                  const SizedBox(height: 20),

                  // Month Cards
                  _buildMonthCards(summary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCards(SummaryModel summary) {
    final current = double.parse(summary.currentMonthSamp);
    final prev1 = double.parse(summary.pre1stMonthSamp);
    final prev2 = double.parse(summary.pre2ndMonthSamp);

    // Get month names
    final now = DateTime.now();
    final currentMonth = DateFormat('MMM yyyy').format(now);
    final lastMonth =
        DateFormat('MMM yyyy').format(DateTime(now.year, now.month - 1));
    final twoMonthsAgo =
        DateFormat('MMM yyyy').format(DateTime(now.year, now.month - 2));
    if (current == 0 && prev1 == 0 && prev2 == 0) {
      return const SizedBox.shrink();
    } else {
      return Row(
        children: [
          Expanded(
            child: _buildMonthCard(
              twoMonthsAgo,
              prev2,
              const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMonthCard(
              lastMonth,
              prev1,
              const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMonthCard(
                currentMonth, current, const Color(0xFF10B981),
                isCurrent: true),
          ),
        ],
      );
    }
  }

  Widget _buildMonthCard(
    String month,
    double count,
    Color color, {
    bool isCurrent = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count >= 1000
                ? '${(count / 1000).toStringAsFixed(1)}K'
                : count.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            month,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2), // ← fixed spacing
          Text(
            isCurrent ? '( till yesterday )' : '',
            // ← same height, just empty when not current
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: isCurrent ? color : Colors.transparent,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(SummaryModel summary) {
    double safeParse(String? value) {
      if (value == null || value.isEmpty) return 0;
      return double.tryParse(value) ?? 0;
    }

    final current = safeParse(summary.currentMonthSamp);
    final prev1 = safeParse(summary.pre1stMonthSamp);
    final prev2 = safeParse(summary.pre2ndMonthSamp);

    final maxValue = [current, prev1, prev2].reduce((a, b) => a > b ? a : b);

    // If everything is 0, show empty state instead of broken chart
    if (maxValue == 0) {
      return const Center(
        child: Text(
          'No monthly sample data available',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final double safeInterval =
    (maxValue / 4) == 0 ? 1.0 : maxValue / 4;


    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 2,
        minY: 0,
        maxY: maxValue + (maxValue * 0.1),

        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: safeInterval,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFFF1F5F9),
            strokeWidth: 1,
          ),
        ),

        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              minIncluded: false,
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value >= 1000
                    ? '${(value / 1000).toStringAsFixed(0)}K'
                    : value.toStringAsFixed(0),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final now = DateTime.now();

                final months = [
                  DateFormat('MMM').format(DateTime(now.year, now.month - 2)),
                  DateFormat('MMM').format(DateTime(now.year, now.month - 1)),
                  DateFormat('MMM').format(now),
                ];

                String text = '';

                if (value.toInt() >= 0 && value.toInt() <= 2) {
                  text = months[value.toInt()];
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),

          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),

        borderData: FlBorderData(show: false),

        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            tooltipPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final value = spot.y;
                final text = value >= 1000
                    ? '${(value / 1000).toStringAsFixed(2)}K'
                    : value.toStringAsFixed(0);

                return LineTooltipItem(
                  text,
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, prev2),
              FlSpot(1, prev1),
              FlSpot(2, current),
            ],
            isCurved: true,
            color: const Color(0xFF6366F1),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 6,
                    color: const Color(0xFF6366F1),
                    strokeColor: Colors.white,
                    strokeWidth: 3,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF6366F1).withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDetailedInsights(Map<String, dynamic> details) {
    final outputList = details['output'];

    if (outputList == null || outputList is! List || outputList.isEmpty) {
      return const SizedBox(); // or show "No Data"
    }

    final output = outputList.first as Map<String, dynamic>;

    final tatPass = _safePercent(output['TATPASS_PERC']);
    final tatFail = _safePercent(output['TATFAIL_PERC']);
    if (tatPass == 0 && tatFail == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'TAT data not available',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    } else {
      return Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.primary800,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      AppAssets.infoIcon,
                      height: 18,
                      color: AppColors.surface,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'TAT Performance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTATCard(
                        'On Time',
                        tatPass,
                        AppColors.emerald700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTATCard(
                        'Delayed',
                        tatFail,
                        AppColors.secondary900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTATCard(String label, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  double _safePercent(dynamic value) {
    if (value == null) return 0;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;

    return 0;
  }
}
