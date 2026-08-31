import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';

class UserAttendanceController extends GetxController {
  var selectedMonth = DateTime.now().obs;
  var attendanceData = <String, AttendanceStatus>{}.obs;
  var isLoading = false.obs;
  var todayAttendanceMarked = false.obs;

  @override
  void onInit() {
    super.onInit();
    generateDummyAttendanceData();
    checkTodayAttendance();
  }

  void generateDummyAttendanceData() {
    attendanceData.clear();
    final now = DateTime.now();
    final startOfMonth =
    DateTime(selectedMonth.value.year, selectedMonth.value.month, 1);
    final endOfMonth =
    DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0);

    for (int day = 1; day <= endOfMonth.day; day++) {
      final date =
      DateTime(selectedMonth.value.year, selectedMonth.value.month, day);
      if (isWeekend(date)) continue;
      if (date.isBefore(DateTime(now.year, now.month, now.day))) {
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final random = DateTime.now().millisecond % 10;
        attendanceData[dateKey] =
        random < 7 ? AttendanceStatus.present : AttendanceStatus.absent;
      }
    }
  }

  void checkTodayAttendance() {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    todayAttendanceMarked.value = attendanceData.containsKey(todayKey);
  }

  void markTodayAttendance() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 200,
              maxWidth: 300,
              // You can also add height constraints if needed
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.how_to_reg,
                    size: 48,
                    color: Get.theme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mark Attendance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () {
                            _confirmAttendance();
                            Get.back();
                          },
                          child: const Text('Mark Present'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmAttendance() {
    isLoading.value = true;
    Future.delayed(const Duration(seconds: 1), () {
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      attendanceData[todayKey] = AttendanceStatus.present;
      todayAttendanceMarked.value = true;
      isLoading.value = false;
      SnackBarService.to.showMessage(message: 'Attendance marked successfully!',);
       // Show success snackbar

    });
  }

  AttendanceStatus? getAttendanceStatus(DateTime date) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return attendanceData[dateKey];
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool isWeekend(DateTime date) {
    return date.weekday == 6 || date.weekday == 7;
  }

  Map<String, int> getMonthlyStats() {
    int presentDays = 0;
    int absentDays = 0;
    int totalWorkingDays = 0;
    final now = DateTime.now();
    final endOfMonth =
    DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0);

    for (int day = 1; day <= endOfMonth.day; day++) {
      final date =
      DateTime(selectedMonth.value.year, selectedMonth.value.month, day);
      if (isWeekend(date) || date.isAfter(now)) continue;
      totalWorkingDays++;
      final status = getAttendanceStatus(date);
      if (status == AttendanceStatus.present) {
        presentDays++;
      } else if (status == AttendanceStatus.absent) {
        absentDays++;
      }
    }

    return {
      'present': presentDays,
      'absent': absentDays,
      'total': totalWorkingDays,
    };
  }

  String getMonthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[date.month - 1];
  }
}

enum AttendanceStatus { present, absent }
