// lib/features/team_lead/performance_dashboard/view/performance_dashboard.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../constants/app_assets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../../../../utils/widgets/stick_tabbar_delegate.dart';
import '../controller/performance_controller.dart';
import '../model/pending_test_model.dart';
import '../model/test_type_model.dart';

class PerformanceDashboard extends StatelessWidget {
  final PerformanceController controller = Get.put(PerformanceController());

  PerformanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Performance Dashboard',
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            // Date Range Selector as a Sliver
            SliverToBoxAdapter(
              child: Obx(() => _buildDateRangeSelector(context)),
            ),

            // Sticky TabBar
            SliverPersistentHeader(
              pinned: true, // This makes it sticky
              delegate: StickyTabBarDelegate(
                TabBar(
                  controller: controller.tabController,
                  labelColor: const Color(0xFF6366F1),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF6366F1),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Pending Tests'),
                    Tab(text: 'Test Types'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            );
          }

          return TabBarView(
            controller: controller.tabController,
            children: [
              _buildPendingTestsTab(),
              _buildTestTypesTab(),
            ],
          );
        }),
      ),
    );
  }


  Widget _buildDateRangeSelector(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => controller.selectDateRange(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.date_range,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.dateRangeText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTestsTab() {
    final data = controller.singleLabData;

    if (data == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildPendingOverviewCard(data),
            const SizedBox(height: 16),
            _buildPendingPieChart(data),
            const SizedBox(height: 16),
            _buildPendingStackedChart(data),
            const SizedBox(height: 16),
            _buildPendingTable(data),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingOverviewCard(PendingPatientModel data) {
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
                  data.labName,
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
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Pending Patients',
                    data.pendingPatients.toString(),
                    Icons.people_outline,
                    const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Pending Tests',
                    data.pendingTests.toString(),
                    Icons.assignment_outlined,
                    const Color(0xFFEC4899),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPieChart(PendingPatientModel data) {
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
                  'Test Distribution by Source',
                  style: TextStyle(
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
            child: SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 60,
                  sections: [
                    if (data.totalInhouse > 0)
                      PieChartSectionData(
                        value: data.totalInhouse.toDouble(),
                        title: '${data.inhousePercentage.toStringAsFixed(1)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        color: const Color(0xFF10B981),
                      ),
                    if (data.totalReferred > 0)
                      PieChartSectionData(
                        value: data.totalReferred.toDouble(),
                        title: '${data.referredPercentage.toStringAsFixed(1)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        color: const Color(0xFF3B82F6),
                      ),
                    if (data.totalTyrocare > 0)
                      PieChartSectionData(
                        value: data.totalTyrocare.toDouble(),
                        title: '${data.tyrocarePercentage.toStringAsFixed(1)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        color: const Color(0xFF8B5CF6),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              children: [
                if (data.totalInhouse > 0)
                  _buildLegendItem(
                    'Inhouse Tests',
                    data.totalInhouse,
                    const Color(0xFF10B981),
                  ),
                if (data.totalReferred > 0)
                  _buildLegendItem(
                    'Referred Tests',
                    data.totalReferred,
                    const Color(0xFF3B82F6),
                  ),
                if (data.totalTyrocare > 0)
                  _buildLegendItem(
                    'Tyrocare Tests',
                    data.totalTyrocare,
                    const Color(0xFF8B5CF6),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingStackedChart(PendingPatientModel data) {
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
                  'Test Type Breakdown',
                  style: TextStyle(
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
            child: SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.pendingTests > 0 ? data.pendingTests.toDouble() * 1.2 : 10.0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String label = '';
                        switch (groupIndex) {
                          case 0:
                            label = rodIndex == 0 ? 'Basic' : 'Advanced';
                            break;
                          case 1:
                            label = rodIndex == 0 ? 'Basic' : 'Advanced';
                            break;
                          case 2:
                            label = rodIndex == 0 ? 'Basic' : 'Advanced';
                            break;
                        }
                        return BarTooltipItem(
                          '$label\n${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Inhouse',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              );
                            case 1:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Referred',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              );
                            case 2:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Tyrocare',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              );
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: data.pendingTests > 0 ? (data.pendingTests / 5).toDouble() : 2.0,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Color(0xFFF1F5F9),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    // Inhouse
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: data.inhouseNormal.toDouble(),
                          color: const Color(0xFF10B981),
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: data.inhouseSpecial.toDouble(),
                          color: const Color(0xFF059669),
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    // Referred
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: data.referredNormal.toDouble(),
                          color: const Color(0xFF3B82F6),
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: data.referredSpecial.toDouble(),
                          color: const Color(0xFF2563EB),
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    // Tyrocare
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: data.tyrocareNormal.toDouble(),
                          color: const Color(0xFF8B5CF6),
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: data.tyrocareSpecial.toDouble(),
                          color: const Color(0xFF7C3AED),
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegend('Basic', const Color(0xFF10B981)),
                const SizedBox(width: 16),
                _buildChartLegend('Advanced', const Color(0xFF059669)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }



  Widget _buildPendingTable(PendingPatientModel data) {
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
                  'Detailed Test Breakdown',
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
                _buildTableHeader(),

                _buildTableRow(
                  'Inhouse',
                  data.inhouseNormal,
                  data.inhouseSpecial,
                  const Color(0xFF10B981),
                ),
                _buildDivider(),
                _buildTableRow(
                  'Referred',
                  data.referredNormal,
                  data.referredSpecial,
                  const Color(0xFF3B82F6),
                ),
                _buildDivider(),
                _buildTableRow(
                  'Tyrocare',
                  data.tyrocareNormal,
                  data.tyrocareSpecial,
                  const Color(0xFF8B5CF6),
                ),
                _buildDivider(),
                _buildTableTotalRow(
                  data.inhouseNormal +
                      data.referredNormal +
                      data.tyrocareNormal,
                  data.inhouseSpecial +
                      data.referredSpecial +
                      data.tyrocareSpecial,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Source',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Basic',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Advanced',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Total',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String source, int normal, int special, Color color) {
    final total = normal + special;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  source,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              normal.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              special.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                total.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableTotalRow(int totalNormal, int totalSpecial) {
    final grandTotal = totalNormal + totalSpecial;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF6366F1).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              'Total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
          Expanded(
            child: Text(
              totalNormal.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              totalSpecial.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              grandTotal.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Color(0xFFF1F5F9),
      thickness: 1,
      height: 1,
    );
  }

// Test Types Tab
  Widget _buildTestTypesTab() {
    final data = controller.singleLabTestType;
    if (data == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildTestTypeOverview(data),
            const SizedBox(height: 16),
            _buildTestTypeBarChart(data),
            const SizedBox(height: 16),
            _buildTestTypeTable(data),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTestTypeOverview(TestTypeModel data) {
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
                  data.labName,
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
            child: Container(
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
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.science,
                    color: Color(0xFF6366F1),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Total Tests',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const Spacer(),

                  Text(
                    data.totalTests.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6366F1),
                    ),
                  ),
               /*   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Tests',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      Text(
                        data.totalTests.toString(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),*/
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTestTypeBarChart(TestTypeModel data) {
    final categories =
    data.testCategories.entries.where((e) => e.value > 0).toList();
    final List<Color> categoryColors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF14B8A6),
    ];

    // Map full names to short forms
    final shortNameMap = {
      'Biochemistry': 'BCH',
      'Clinical Pathology': 'CP',
      'Hematology': 'HEM',
      'Immunoassay': 'IMM',
      'Serology': 'SER',
      'Microbiology': 'MIC',
      'Pathology': 'PATH',
      'Special Tests': 'SPL',
    };

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
                  'Test Category Distribution',
                  style: TextStyle(
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
            child: SizedBox(
              height: 350,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: categories.isEmpty
                      ? 10.0
                      : categories
                      .map((e) => e.value.toDouble())
                      .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final fullName = categories[groupIndex].key;
                        return BarTooltipItem(
                          '$fullName\n${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < categories.length) {
                            final fullName = categories[value.toInt()].key;
                            final shortName = shortNameMap[fullName] ??
                                fullName.substring(0, 3).toUpperCase();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                shortName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Color(0xFFF1F5F9),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: categories.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color:
                          categoryColors[entry.key % categoryColors.length],
                          width: 24,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: categories.asMap().entries.map((entry) {
                final color = categoryColors[entry.key % categoryColors.length];
                final fullName = entry.value.key;
                final value = entry.value.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$fullName: $value',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
/*  Widget _buildTestTypeBarChart(TestTypeModel data) {
    final categories =
        data.testCategories.entries.where((e) => e.value > 0).toList();
    final List<Color> categoryColors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF14B8A6),
    ];

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
            decoration: BoxDecoration(
              color: AppColors.primary800,
              borderRadius: const BorderRadius.only(
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
                  'Test Category Distribution',
                  style: TextStyle(
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
            child: SizedBox(
              height: 350,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: categories
                          .map((e) => e.value.toDouble())
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${categories[groupIndex].key}\n${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < categories.length) {
                            final category = categories[value.toInt()].key;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                category.length > 10
                                    ? '${category.substring(0, 10)}...'
                                    : category,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: const Color(0xFFF1F5F9),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: categories.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color:
                              categoryColors[entry.key % categoryColors.length],
                          width: 24,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }*/

  Widget _buildTestTypeTable(TestTypeModel data) {
    final categories = data.testCategories.entries.toList();
    final List<Color> categoryColors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF14B8A6),
    ];

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
                  'Detailed Category Breakdown',
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
                ...categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final percentage = data.totalTests > 0
                      ? (category.value / data.totalTests) * 100
                      : 0.0;

                  return Column(
                    children: [
                      _buildCategoryRow(
                        category.key,
                        category.value,
                        percentage,
                        data.totalTests,
                        categoryColors[index % categoryColors.length],
                      ),
                      if (index < categories.length - 1)
                        const SizedBox(height: 12),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    String category,
    int count,
    double percentage,
    int total,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
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
    );
  }
}
