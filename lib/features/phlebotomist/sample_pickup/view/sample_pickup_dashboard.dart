import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../controller/sample_pickup_controller.dart';
import '../model/work_item_model.dart';





// sample_pickup_dashboard.dart

class SamplePickupDashboard extends StatelessWidget {
  const SamplePickupDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SamplePickupController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Sample Pickup',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDateSelector(controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                );
              }

              if (controller.workList.isEmpty) {
                return _buildEmptyState();
              }
              return  FacilityWorkCardsWidget(workList: controller.workList.value);


              /*return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.workList.length,
                itemBuilder: (context, index) {
                  return _buildFacilityCard(controller.workList[index], controller);
                },
              );*/
            }),
          ),
        ],
      ),
      floatingActionButton: Obx(() => controller.showFloatingButton.value
          ? _buildFloatingActionButton(controller)
          : const SizedBox.shrink()),
    );
  }

  /// 📅 Date selector
  Widget _buildDateSelector(SamplePickupController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => Text(
              'Date: ${controller.selectedDate.value.toString().split(' ')[0]}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            )),
          ),
          GestureDetector(
            onTap: () => controller.selectDate(Get.context!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.calendar_month, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Pick Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🗃 Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No facilities found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Text('No sample pickup work for selected date', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  /// 🏥 Facility card with collapsible stats table
  Widget _buildFacilityCard(WorkItem facility, SamplePickupController controller) {
    final isSelected = controller.selectedFacility.value == facility;

    return GestureDetector(
      onTap: () => isSelected ? controller.deselectFacility() : controller.selectFacility(facility),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.grey.withOpacity(0.08),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_hospital, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(facility.facilityName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('Code: ${facility.facilityCode}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  if (facility.isSubmittedAccepted == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Submitted', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),

            // Stats Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatChip('Samples', facility.sampleCount.toString(), Icons.biotech, AppColors.info),
                  const SizedBox(width: 8),
                  _buildStatChip('Tubes', facility.tubeCount.toString(), Icons.science, AppColors.warning),
                  const SizedBox(width: 8),
                  _buildStatChip('TRF P', facility.trfP?.toString() ?? '0', Icons.description, AppColors.success),
                ],
              ),
            ),

            // Expanded table when selected
            if (isSelected) _buildDetailTable(facility),
          ],
        ),
      ),
    );
  }

  /// 📊 Stat chip
  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  /// 📋 Tubes & TRF Table (Pathology + Laboratory)
  Widget _buildDetailTable(WorkItem facility) {
    final rows = [
      {
        'type': 'Pathology',
        'icon': Icons.science,
        'color': Colors.red,
        'tubes': facility.tubeCountP ?? 0,
        'trf': facility.trfP ?? 0,
      },
      {
        'type': 'Laboratory',
        'icon': Icons.biotech,
        'color': Colors.blue,
        'tubes': facility.tubeCountL ?? 0,
        'trf': facility.trfCountL ?? 0,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Type', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Tubes', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('TRF', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          // Data rows
          ...rows.map((row) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: (row['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Icon(row['icon'] as IconData, color: row['color'] as Color, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(row['type'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text("${row['tubes']}", textAlign: TextAlign.center, style: TextStyle(color: row['color'] as Color, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Text("${row['trf']}", textAlign: TextAlign.center, style: TextStyle(color: row['color'] as Color, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// ⬆ Floating submit button
  Widget _buildFloatingActionButton(SamplePickupController controller) {
    return FloatingActionButton.extended(
      onPressed: controller.submitToLab,
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.upload, color: Colors.white),
      label: const Text('Submit to Lab', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}



class FacilityWorkCardsWidget extends StatelessWidget {
  final List<WorkItem> workList;

  const FacilityWorkCardsWidget({
    super.key,
    required this.workList,
  });

  // Group work items by facility
  Map<String, List<WorkItem>> _groupByFacility() {
    final Map<String, List<WorkItem>> grouped = {};
    for (var item in workList) {
      if (!grouped.containsKey(item.facilityName)) {
        grouped[item.facilityName] = [];
      }
      grouped[item.facilityName]!.add(item);
    }
    return grouped;
  }

  // Calculate totals for a facility
  Map<String, int> _calculateTotals(List<WorkItem> items) {
    int totalSamples = 0;
    int totalTubes = 0;
    int totalTrfP = 0;
    int totalTubecountP = 0;
    int totalTrfL = 0;
    int totalTubecountL = 0;

    for (var item in items) {
      totalSamples += item.sampleCount;
      totalTubes += item.tubeCount;
      totalTrfP += item.trfP ?? 0;
      totalTubecountP += item.tubeCountP ?? 0;
      totalTrfL += item.trfCountL ?? 0;
      totalTubecountL += item.tubeCountL ?? 0;
    }

    return {
      'samples': totalSamples,
      'tubes': totalTubes,
      'trfP': totalTrfP,
      'tubecountP': totalTubecountP,
      'trfL': totalTrfL,
      'tubecountL': totalTubecountL,
    };
  }

  @override
  Widget build(BuildContext context) {
    final groupedWork = _groupByFacility();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedWork.keys.length,
      itemBuilder: (context, index) {
        final facilityName = groupedWork.keys.elementAt(index);
        final facilityItems = groupedWork[facilityName]!;
        final totals = _calculateTotals(facilityItems);
        final firstItem = facilityItems.first;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facilityName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Code: ${firstItem.facilityCode}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${facilityItems.length} Work${facilityItems.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Summary Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Samples',
                        totals['samples'].toString(),
                        Icons.science,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total Tubes',
                        totals['tubes'].toString(),
                        Icons.science_outlined ,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // P/R/L Table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Count Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Table(
                          border: TableBorder.all(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                              ),
                              children: [
                                _buildTableHeader('Type'),
                                _buildTableHeader('P'),
                                _buildTableHeader('R'),
                                _buildTableHeader('L'),
                              ],
                            ),
                            TableRow(
                              children: [
                                _buildTableCell('TRF', isRowHeader: true),
                                _buildTableCell(totals['trfP'].toString()),
                                _buildTableCell('0'), // Assuming R is always 0 for now
                                _buildTableCell(totals['trfL'].toString()),
                              ],
                            ),
                            TableRow(
                              children: [
                                _buildTableCell('Tubes', isRowHeader: true),
                                _buildTableCell(totals['tubecountP'].toString()),
                                _buildTableCell('0'), // Assuming R is always 0 for now
                                _buildTableCell(totals['tubecountL'].toString()),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Location and Time Info
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${firstItem.latitude.toStringAsFixed(4)}, ${firstItem.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      firstItem.createdDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isRowHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isRowHeader ? FontWeight.w500 : FontWeight.normal,
          color: isRowHeader ? Colors.black87 : Colors.black54,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}