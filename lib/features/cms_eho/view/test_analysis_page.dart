// lib/features/team_lead/test_analysis/view/test_analysis_dashboard.dart

import 'package:fl_chart/fl_chart.dart' as flc;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../constants/app_assets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../controller/test_analysis_controller.dart';
import '../model/test_analysis_model.dart';

class TestAnalysisDashboard extends StatelessWidget {
  final TestAnalysisController controller = Get.put(TestAnalysisController());

  TestAnalysisDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Test Analysis Dashboard',
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
          );
        }

        if (controller.testAnalysisList.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Current Month Section — only Test Type pie chart
                    if (controller.currentMonthData != null)
                      _buildAnalysisSection(
                        'Current Month',
                        controller.currentMonthData!,
                        showOnlyTestType: true,
                      ),
                    const SizedBox(height: 24),

                    // 3 Months Average Section — both pie charts
                    if (controller.threeMonthsAvgData != null)
                      _buildAnalysisSection(
                        'Last 3 Months Average',
                        controller.threeMonthsAvgData!,
                        showOnlyTestType: false,
                      ),
                    const SizedBox(height: 24),

                    // Comparison Card
                    if (controller.currentMonthData != null &&
                        controller.threeMonthsAvgData != null)
                      _buildComparisonCard(
                        controller.currentMonthData!,
                        controller.threeMonthsAvgData!,
                      ),
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

  Widget _buildAnalysisSection(
      String title,
      TestAnalysisModel data, {
        required bool showOnlyTestType,
      }) {
    return Column(
      children: [
        _buildPieChartCard(title, data, showOnlyTestType: showOnlyTestType),
        const SizedBox(height: 16),
        _buildDataTable(data),
      ],
    );
  }

  Widget _buildPieChartCard(
      String title,
      TestAnalysisModel data, {
        required bool showOnlyTestType,
      }) {
    return Container(
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
        children: [
          // Header
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Total Tests Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total Tests: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      Text(
                        data.totalTests.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Pie Charts Row
                if (showOnlyTestType)
                // Current month: only Test Type chart, centered
                  Center(
                    child: SizedBox(
                      width: 220,
                      child: _buildInteractivePieChart(
                        'Test Type Distribution',
                        [
                          PieChartData(
                            'Basic',
                            data.normalTest.toDouble(),
                            const Color(0xFF3B82F6),
                          ),
                          PieChartData(
                            'Advanced',
                            data.specialTest.toDouble(),
                            const Color(0xFF8B5CF6),
                          ),
                        ],
                        data.totalTests,
                      ),
                    ),
                  )
                else
                // 3-month avg: both charts side by side, scaled down
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildInteractivePieChart(
                          'TAT Performance',
                          [
                            PieChartData(
                              'On Time',
                              data.tatMetTests.toDouble(),
                              AppColors.emerald700,
                            ),
                            PieChartData(
                              'Delayed',
                              data.tatFailTests.toDouble(),
                              AppColors.secondary900,
                            ),
                          ],
                          data.totalTests,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInteractivePieChart(
                          'Test Type',
                          [
                            PieChartData(
                              'Basic',
                              data.normalTest.toDouble(),
                              const Color(0xFF3B82F6),
                            ),
                            PieChartData(
                              'Advanced',
                              data.specialTest.toDouble(),
                              const Color(0xFF8B5CF6),
                            ),
                          ],
                          data.totalTests,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive pie chart with tappable sections that elevate (explode) on tap.
  Widget _buildInteractivePieChart(
      String title,
      List<PieChartData> data,
      int totalTests, {
        bool compact = false,
      }) {
    return StatefulBuilder(
      builder: (context, setState) {
        int touchedIndex = -1;

        return StatefulBuilder(
          builder: (context, innerSetState) {
            final total = data.fold(0.0, (sum, item) => sum + item.value);
            final double chartHeight = compact ? 110 : 160;
            final double centerRadius = compact ? 22 : 38;
            final double normalRadius = compact ? 30 : 48;
            final double touchedRadius = compact ? 38 : 58;
            final double labelFontSize = compact ? 8 : 10;

            return Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: chartHeight,
                  child: flc.PieChart(
                    flc.PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: centerRadius,
                      pieTouchData: flc.PieTouchData(
                        touchCallback:
                            (flc.FlTouchEvent event, pieTouchResponse) {
                          innerSetState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: List.generate(data.length, (i) {
                        final item = data[i];
                        final isTouched = i == touchedIndex;
                        final percentage =
                        total > 0 ? (item.value / total) * 100 : 0.0;

                        return flc.PieChartSectionData(
                          value: item.value,
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: isTouched ? touchedRadius : normalRadius,
                          titleStyle: TextStyle(
                            fontSize: isTouched ? labelFontSize + 2 : labelFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.6),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          color: item.color,
                          badgeWidget: isTouched
                              ? _buildBadge(item.label, item.value.toInt())
                              : null,
                          badgePositionPercentageOffset: 1.3,
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Modern legend with visual proportion bars
                ...List.generate(data.length, (i) {
                  final item = data[i];
                  final percentage =
                  total > 0 ? (item.value / total) * 100 : 0.0;
                  final isSelected = i == touchedIndex;

                  return GestureDetector(
                    onTap: () {
                      innerSetState(() {
                        touchedIndex = touchedIndex == i ? -1 : i;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? item.color.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? item.color.withOpacity(0.4)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? item.color
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              // Count badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: item.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Visual proportion bar replaces bare "0.5%" text
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  // Track
                                  Container(
                                    height: 6,
                                    width: constraints.maxWidth,
                                    decoration: BoxDecoration(
                                      color: item.color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  // Fill
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                    height: 6,
                                    width: constraints.maxWidth *
                                        (percentage / 100).clamp(0.0, 1.0),
                                    decoration: BoxDecoration(
                                      color: item.color,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: item.color.withOpacity(0.4),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          // Percentage label next to bar — always readable
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: item.color.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  /// Floating badge shown on the exploded slice when tapped
  Widget _buildBadge(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '$label\n$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildDataTable(TestAnalysisModel data) {
    return Container(
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
        children: [
          // Header
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
                  'Test Distribution Analysis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Table Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Total Tests Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1).withOpacity(0.1),
                        const Color(0xFF6366F1).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Tests Performed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          Text(
                            data.totalTests.toString(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Test Type Distribution
                _buildModernTableSection(
                  title: 'Test Type Distribution',
                  icon: Icons.science_outlined,
                  color: const Color(0xFF3B82F6),
                  rows: [
                    _buildModernTableRow(
                      label: 'Basic Tests',
                      count: data.normalTest,
                      percentage: data.basicTestPercentage,
                      total: data.totalTests,
                      color: const Color(0xFF3B82F6),
                      icon: Icons.check_circle_outline,
                    ),
                    _buildModernTableRow(
                      label: 'Advanced Tests',
                      count: data.specialTest,
                      percentage: data.advancedTestPercentage,
                      total: data.totalTests,
                      color: const Color(0xFF8B5CF6),
                      icon: Icons.star_outline,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // TAT Performance
                _buildModernTableSection(
                  title: 'TAT Performance',
                  icon: Icons.timer_outlined,
                  color: AppColors.emerald700,
                  rows: [
                    _buildModernTableRow(
                      label: 'On Time',
                      count: data.tatMetTests,
                      percentage: data.tatMetPercentage,
                      total: data.totalTests,
                      color: AppColors.emerald700,
                      icon: Icons.check_circle,
                    ),
                    _buildModernTableRow(
                      label: 'Delayed',
                      count: data.tatFailTests,
                      percentage: data.tatFailPercentage,
                      total: data.totalTests,
                      color: AppColors.secondary900,
                      icon: Icons.access_time,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTableSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: rows,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTableRow({
    required String label,
    required int count,
    required double percentage,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
      TestAnalysisModel current,
      TestAnalysisModel threeMonth,
      ) {
    final totalTestsDiff = current.totalTests - threeMonth.totalTests;
    final tatMetDiff = current.tatMetTests - threeMonth.tatMetTests;
    final normalTestDiff = current.normalTest - threeMonth.normalTest;

    return Container(
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
        children: [
          // Header
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
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'Performance Comparison\n'),
                      TextSpan(
                        text: '(Current vs 3-Month Average)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildComparisonRow(
                  'Total Tests',
                  totalTestsDiff,
                  current.totalTests,
                  threeMonth.totalTests,
                ),
                const SizedBox(height: 12),
                _buildComparisonRow(
                  'TAT Met',
                  tatMetDiff,
                  current.tatMetTests,
                  threeMonth.tatMetTests,
                ),
                const SizedBox(height: 12),
                _buildComparisonRow(
                  'Basic Tests',
                  normalTestDiff,
                  current.normalTest,
                  threeMonth.normalTest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
      String label,
      int difference,
      int currentValue,
      int avgValue,
      ) {
    final isPositive = difference > 0;
    final isNegative = difference < 0;
    final percentageChange =
    avgValue > 0 ? ((difference / avgValue) * 100).abs() : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    currentValue.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? AppColors.emerald700.withOpacity(0.1)
                          : isNegative
                          ? AppColors.secondary900.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward
                              : isNegative
                              ? Icons.arrow_downward
                              : Icons.remove,
                          size: 12,
                          color: isPositive
                              ? AppColors.emerald700
                              : isNegative
                              ? AppColors.secondary900
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${percentageChange.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isPositive
                                ? AppColors.emerald700
                                : isNegative
                                ? AppColors.secondary900
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '3-Mo Avg',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    avgValue.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper class for pie chart data
class PieChartData {
  final String label;
  final double value;
  final Color color;

  PieChartData(this.label, this.value, this.color);
}