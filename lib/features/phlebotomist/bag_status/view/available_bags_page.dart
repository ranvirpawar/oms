import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../theme/app_colors.dart';
import '../controller/bag_status_controller.dart';


class AvailableBagsPage extends StatelessWidget {
  final BagStatusController controller;
  const AvailableBagsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Available Inventory',
        actions: [
          // Count Badge
          Obx(() => Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer, // Light Teal
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color:
                      AppColors.surfaceContainer.withOpacity(0.3)),
                ),
                child: Text(
                  '${controller.filteredAvailableBags.length} Ready',
                  style: const TextStyle(
                    color: AppColors.emerald900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ))
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredAvailableBags.isEmpty) {
                return _buildEmptyState(
                    controller.availableSearchController.text);
              }

              // TABLE VIEW
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.vertical,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          AppColors.primary50), // Light teal header
                      columnSpacing: 20,
                      dataRowMinHeight: 50,
                      dataRowMaxHeight: 60,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Sr. No',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text(
                            'Bag Number',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: controller.filteredAvailableBags
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final bag = entry.value;

                        return DataRow(

                          cells: [
                            // Serial Number Cell
                            DataCell(Text('${index + 1}')),

                            // Bag Number Cell (with copy function)
                            DataCell(
                              Row(
                                children: [
                                  Text(
                                    bag.bagcode,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Copy on tap
                                Clipboard.setData(ClipboardData(text: bag.bagcode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied ${bag.bagcode}'),
                                    duration: const Duration(milliseconds: 800),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            
                            // Status Cell
                            DataCell(
                              // check is bag available otherwise empty container
                              bag.isAvailable ?Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: const Text('Available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ):Container())

                        

                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BagStatusController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: TextField(
        controller: controller.availableSearchController,
        onChanged: (val) => controller.filterAvailableBags(val),
        decoration: InputDecoration(
          hintText: 'Search available bag...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: controller.availableSearchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              controller.availableSearchController.clear();
              controller.filterAvailableBags('');
            },
          )
              : null,
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String searchText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            searchText.isEmpty ? 'No available bags' : 'No matching bags found',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700),
          ),
          if (searchText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Checked for "$searchText"',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }
}


