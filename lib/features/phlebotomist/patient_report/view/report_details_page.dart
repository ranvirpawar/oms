import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../theme/app_colors.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../controller/patient_report_controller.dart';
import '../model/patiet_report_data.dart';
import '../model/test_status_model.dart';

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PatientReportController>();
    final report = Get.arguments['report'] as PatientReportData;

    return Scaffold(
      appBar: CustomAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              HelperMethods.capitalizeFirstLetter(report.patientName ?? 'N/A'),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.surface,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Barcode: ${report.barcode}',
              style: const TextStyle(fontSize: 12, color: AppColors.surface),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryBar(controller),
            _buildFilterBar(controller),
            Expanded(child: _buildTestList(controller, report)),
          ],
        ),
      ),
    );
  }



  Widget _buildSummaryBar(PatientReportController controller) {
    return Obx(() {
      final tests = controller.testDetails;
      final ready = tests.where((t) => t.isReady).length;
      final inProcess = tests.where((t) => t.isInProcess).length;

      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            _statPill(tests.length.toString(), 'Total', null),
            const SizedBox(width: 8),
            _statPill(ready.toString(), 'Ready', const Color(0xFF3B6D11)),
            const SizedBox(width: 8),
            _statPill(inProcess.toString(), 'In process', const Color(0xFF854F0B)),
          ],
        ),
      );
    });
  }

  Widget _statPill(String num, String label, Color? numColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              num,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: numColor ?? Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(PatientReportController controller) {
    final filters = [
      {'key': 'all',       'label': 'All'},
      {'key': 'ready',     'label': 'Ready'},
      {'key': 'inprocess', 'label': 'In process'},
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: Obx(
        () => Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final isActive = controller.activeFilter.value == f['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => controller.applyTestFilter(f['key']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? _filterBg(f['key']!)
                            : Colors.transparent,
                        border: Border.all(
                          color: isActive
                              ? _filterBorder(f['key']!)
                              : Colors.grey.shade300,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? _filterText(f['key']!)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestList(
    PatientReportController controller,
    PatientReportData report,
  ) {
    return Obx(() {
      if (controller.isTestDetailLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final tests = controller.filteredTests;
      if (tests.isEmpty) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No tests found',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: tests.length,
        itemBuilder: (_, i) => _buildTestCard(tests[i], controller, report),
      );
    });
  }

  Widget _buildTestCard(
    TestStatusModel test,
    PatientReportController controller,
    PatientReportData report,
  ) {
    final isReady = test.isReady;

    final iconColor = isReady ? const Color(0xFF3B6D11) : const Color(0xFF854F0B);
    final iconBg    = isReady ? const Color(0xFFEAF3DE) : const Color(0xFFFAEEDA);
    final icon      = isReady ? Icons.verified_rounded : Icons.sync_rounded;
    final statusLabel = isReady ? 'Report ready' : 'In processing';
    final statusColor = isReady ? const Color(0xFF3B6D11) : const Color(0xFF854F0B);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.serviceName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, color: statusColor),
                  ),
                ],
              ),
            ),
            if (isReady) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => controller.viewReport(report),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3DE),
                    border: Border.all(
                      color: const Color(0xFF639922),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        color: Color(0xFF3B6D11),
                        size: 13,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'View',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3B6D11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _filterBg(String key) => switch (key) {
    'ready' => const Color(0xFFEAF3DE),
    'inprocess' => const Color(0xFFFAEEDA),
    'pending' => const Color(0xFFF1EFE8),
    _ =>  AppColors.primary900,
  };

  Color _filterBorder(String key) => switch (key) {
    'ready' => const Color(0xFF639922),
    'inprocess' => const Color(0xFFBA7517),
    'pending' => const Color(0xFFB4B2A9),
    _ => AppColors.primary900,
  };

  Color _filterText(String key) => switch (key) {
    'ready' => const Color(0xFF3B6D11),
    'inprocess' => const Color(0xFF854F0B),
    'pending' => const Color(0xFF5F5E5A),
    _ => Colors.white,
  };
}
