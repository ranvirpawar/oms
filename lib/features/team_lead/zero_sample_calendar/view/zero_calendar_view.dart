// 2. SERVICE CLASS
// services/zero_sample_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/constants/app_assets.dart';
import 'package:lifenity_connect/utils/animated_shimmer/calendar_shimmer.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../theme/app_colors.dart';
import '../controller/zero_sample_calendar_controller.dart';
import '../model/zero_sample_data_model.dart';

class ZeroSampleCalendarView extends StatelessWidget {
  final ZeroSampleController controller = Get.put(ZeroSampleController());

  ZeroSampleCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Zero Sample Calendar'),
      body: Obx(
        () => controller.isLoading.value
            ? const CalendarShimmerWidget()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalendarCard(),
                    const SizedBox(height: 20),
                    _buildSelectedDateInfo(),
                    const SizedBox(height: 20),
                    _buildRemarksSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCalendarHeader(),
            const SizedBox(height: 10),
            _buildCalendar(),
            const SizedBox(height: 12),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            final previousMonth = DateTime(
              controller.currentMonth.value.year,
              controller.currentMonth.value.month - 1,
            );
            controller.changeMonth(previousMonth);
          },
          icon: const Icon(Icons.chevron_left),
        ),
        Obx(() => Text(
              DateFormat('MMMM yyyy').format(controller.currentMonth.value),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )),
        IconButton(
          onPressed: () {
            final nextMonth = DateTime(
              controller.currentMonth.value.year,
              controller.currentMonth.value.month + 1,
            );
            controller.changeMonth(nextMonth);
          },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Obx(() => TableCalendar<ZeroSampleData>(
          key: ValueKey(controller.selectedDate.value),
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime(controller.runningMonth.year,
              controller.runningMonth.month + 1, 0),
          focusedDay: controller.currentMonth.value,
          selectedDayPredicate: (day) {
            return isSameDay(controller.selectedDate.value, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            if (selectedDay.month == controller.currentMonth.value.month &&
                selectedDay.year == controller.currentMonth.value.year) {
              controller.selectDate(selectedDay);
            }
          },
          onPageChanged: (focusedDay) {
            controller.changeMonth(focusedDay);
          },
          calendarBuilders: CalendarBuilders<ZeroSampleData>(
            defaultBuilder: (context, day, focusedDay) {
              if (day.month != controller.currentMonth.value.month) {
                return null;
              }
              return _buildCalendarDay(day, false);
            },
            selectedBuilder: (context, day, focusedDay) {
              return _buildCalendarDay(day, true);
            },
            todayBuilder: (context, day, focusedDay) {
              return _buildCalendarDay(day, false, isToday: true);
            },
            markerBuilder: (context, day, events) {
              return const SizedBox.shrink();
            },
          ),
          eventLoader: (day) {
            final data = controller.getZeroSampleDataForDate(day);
            return data != null ? [data] : [];
          },
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            markersMaxCount: 0,
            markerDecoration: BoxDecoration(),
            markersAlignment: Alignment.center,
            canMarkersOverflow: false,
          ),
          headerVisible: false,
        ));
  }

  Widget _buildCalendarDay(DateTime day, bool isSelected,
      {bool isToday = false}) {
    final data = controller.getZeroSampleDataForDate(day);
    final hasData = data != null;
    final zeroSampleCount = controller.getActualZeroSampleCount(day);
    final percentage = controller.getSampleCollectionPercentage(day);

    Color textColor = const Color(0xFF1F2937);
    Color countBackgroundColor = const Color(0xFFF3F4F6);
    Color countTextColor = const Color(0xFF6B7280);
    final BorderRadius borderRadius = BorderRadius.circular(40);
    BoxDecoration decoration = BoxDecoration(
      color: Colors.transparent,
      borderRadius: borderRadius,
    );

    if (isSelected) {
      decoration = BoxDecoration(
        color: AppColors.primary700, // Blue for selected
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
      textColor = Colors.white;
      countBackgroundColor = Colors.white.withOpacity(0.2);
      countTextColor = Colors.white.withOpacity(0.9);
    } else if (isToday) {
      decoration = BoxDecoration(
        color: const Color(0xFFEFF6FF), // Light blue for today
        borderRadius: borderRadius,
        border: Border.all(color: const Color(0xFF1E40AF), width: 1),
      );
      textColor = const Color(0xFF1E40AF);
      countBackgroundColor = const Color(0xFFDDEAFF);
      countTextColor = const Color(0xFF3B82F6);
    } else if (hasData) {
      // Vertical progress indicator using LinearGradient
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [percentage / 100, percentage / 100],
          colors: const [
            Color(0xFF22C55E), // Muted green for % collected
            Color(0xFFF3F4F6), // Neutral grey for remaining
          ],
        ),
        borderRadius: borderRadius,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      );
      countBackgroundColor =
          Colors.white.withOpacity(0.7); // Semi-transparent for readability
      countTextColor = const Color(0xFF1F2937);
    }

    return Container(
      margin: const EdgeInsets.all(0),
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: decoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontWeight:
                  isSelected || isToday ? FontWeight.w600 : FontWeight.w500,
              fontSize: 10,
            ),
          ),
          if (hasData) ...[
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: countBackgroundColor,
                shape: BoxShape.circle, // This makes it perfectly circular
              ),
              child: Center(
                child: Text(
                  zeroSampleCount > 0
                      ? '$zeroSampleCount' // Show facilities without samples
                      : '✓', // Show checkmark if all samples collected
                  style: TextStyle(
                    color: countTextColor,
                    fontSize: zeroSampleCount > 0 ? 8 : 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(const Color(0xFF22C55E), 'Collection Progress',
                const Color(0xFF22C55E)),
            _buildLegendItem(const Color(0xFFF3F4F6), 'Facilities w/o Samples',
                const Color(0xFFE5E7EB)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Numbers show facilities without samples; fill shows % collected',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, Color borderColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: borderColor, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSelectedDateInfo() {
    return Obx(() {
      final selectedData =
          controller.getZeroSampleDataForDate(controller.selectedDate.value);
      final dateString =
          DateFormat('dd MMM yyyy').format(controller.selectedDate.value);
      final zeroSampleCount =
          controller.getActualZeroSampleCount(controller.selectedDate.value);
      final samplesCollected =
          controller.getSamplesCollected(controller.selectedDate.value);
      final totalFacilities =
          controller.getTotalFacilities(controller.selectedDate.value);
      final percentage = controller
          .getSampleCollectionPercentage(controller.selectedDate.value);
      final status =
          controller.getCompletionStatus(controller.selectedDate.value);

      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected Date: $dateString',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedData != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(status)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (selectedData != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Facilities',
                        '$totalFacilities',
                        Icons.business,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Facilities with collections',
                        '$samplesCollected',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Facilities w/o collection',
                        '$zeroSampleCount',
                        Icons.warning,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Collection Progress',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          AlwaysStoppedAnimation(_getStatusColor(status)),
                      minHeight: 8,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                  ],
                ),
              ] else ...[
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No data available for this date',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Complete':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Average':
        return Colors.orange;
      case 'Poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Obx(() => Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // show month for selected date
                Row(
                  children: [
                    SvgPicture.asset(AppAssets.infoIcon,
                        width: 18, height: 18, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Remarks for ${DateFormat('MMMM yyyy').format(controller.selectedDate.value)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up,
                          color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Most Frequent Issue: ${controller.getMostFrequentRemark()}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...controller
                    .getActiveRemarks()
                    .map((
                      remark,
                    ) =>
                        _buildRemarkItem(
                          remark,
                        ))
                    ,
                if (controller.getActiveRemarks().isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.green.shade400,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No active remarks for this month',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ));
  }

  Widget _buildRemarkItem(RemarkData remark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // bullet point

              Icon(Icons.file_present_outlined,
                  color: Colors.orange.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  remark.remarkHeader,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reported Count: ${remark.remark}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
