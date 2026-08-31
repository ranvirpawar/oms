import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../controller/user_attendance_controller.dart';

import 'package:table_calendar/table_calendar.dart';


class UserAttendancePage extends StatelessWidget {
  final UserAttendanceController controller =
      Get.put(UserAttendanceController());

  UserAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(
        title: 'User Attendance',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildStatsCards(context),
            _buildCalendarCard(context),
          ],
        ),
      ),
      floatingActionButton: Obx(() {
        final today = DateTime.now();
        if (controller.isWeekend(today) ||
            controller.todayAttendanceMarked.value) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton(
          onPressed: controller.markTodayAttendance,
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.check, color: Colors.white),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Obx(
        () => Column(
          children: [
            Text(
              '${controller.getMonthName(controller.selectedMonth.value)} ${controller.selectedMonth.value.year}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Swipe calendar to change month',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Obx(() {
      final stats = controller.getMonthlyStats();
      final presentPercentage = stats['total']! > 0
          ? (stats['present']! / stats['total']! * 100).round()
          : 0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildStatCard(
              context,
              'Present',
              '${stats['present']}',
              Colors.green,
              Icons.check_circle_outline,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              context,
              'Absent',
              '${stats['absent']}',
              Colors.red,
              Icons.close,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              context,
              'Percentage',
              '$presentPercentage%',
              Theme.of(context).primaryColor,
              Icons.trending_up,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Present', Colors.green),
                _buildLegendItem('Absent', Colors.red),
                _buildLegendItem('Today', Theme.of(context).primaryColor),
              ],
            ),
          ),
          Obx(() => TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: controller.selectedMonth.value,
                calendarFormat: CalendarFormat.month,
                onPageChanged: (focusedDay) {
                  controller.selectedMonth.value = focusedDay;
                  controller.generateDummyAttendanceData();
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.grey[500]),
                  outsideDaysVisible: false,
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.grey[600]),
                  weekendStyle: TextStyle(color: Colors.grey[400]),
                ),
                headerVisible: false,
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final status = controller.getAttendanceStatus(day);
                    Color? bgColor;

                    if (controller.isWeekend(day)) {
                      bgColor = Colors.grey[200];
                    } else if (status == AttendanceStatus.present) {
                      bgColor = Colors.green[100];
                    } else if (status == AttendanceStatus.absent) {
                      bgColor = Colors.red[100];
                    }

                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: controller.isWeekend(day)
                                    ? Colors.grey[500]
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
