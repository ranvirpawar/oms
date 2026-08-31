import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../componenents/c_textformfeild.dart';
import '../../../../constants/app_assets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/helper_functions/input_formatter.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../../../../utils/widgets/modern_dropdown.dart';
import '../../../phlebotomist/sample_pickup/model/work_item_model.dart';
import '../controller/accept_in_lab_controller.dart';
import '../model/resource_model.dart';



class AcceptInLabView extends StatelessWidget {
  final ResourcesData resource;
  final DateTime selectedDate;
  final String labCode;
  final String labTechnicianId;

  const AcceptInLabView({super.key, required this.resource, required this.selectedDate, required this.labCode,required this.labTechnicianId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AcceptInLabController(resource, selectedDate, labCode, labTechnicianId),);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Accept in Lab'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: controller.workList.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No facilities available for lab acceptance',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: controller.workList.length,
                  itemBuilder: (context, index) {
                    final facility = controller.workList[index];
                    return Obx(() {
                      final isSelected = controller.selectedLabFacilities.contains(facility);
                      final isSubmitted = facility.trfCountL != null && facility.tubeCountL != null;
                      final controllers = controller.getTextControllers(facility);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              blurRadius: isSelected ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: isSubmitted ? null : () => controller.toggleLabFacilitySelection(facility),
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradientRev,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        facility.facilityName ,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    isSubmitted
                                        ? _buildSubmittedTag()
                                        : _buildModernCheckbox(isSelected),
                                  ],
                                ),
                              ),
                              _buildLabDataTable(
                                facility,
                                isSelected,
                                isSubmitted,
                                controllers['trfL']!,
                                controllers['tubeCountL']!,
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
              Obx(() => controller.selectedLabFacilities.isNotEmpty
                  ? Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Text(
                      '${controller.selectedLabFacilities.length} facilities selected',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => ModernDropdown(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      label: 'Select Temperature',
                      value: controller.selectedTemperature.value,
                      items: controller.temperatureData.map((temp) => temp.sampleTempName).toList(),
                      onChanged: controller.selectTemperature,
                    )),
                    const SizedBox(height: 16),
                    CFormTextField(

                      controller: controller.remarkController,
                      label: 'Remark',
                      iconPath: AppAssets.infoIcon,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.submitToLab,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Accept in Lab',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : const SizedBox.shrink()),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSubmittedTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Submitted',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLabDataTable(WorkItem facility, bool isSelected, bool isSubmitted, TextEditingController trfLController, TextEditingController tubeCountLController) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          children: [
            _buildTableHeader('Type'),
            _buildTableHeader('TRF'),
            _buildTableHeader('Tubes'),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('P (Phlebotomist)', Colors.green[600]!),
            _buildTableCell(facility.trfP?.toString() ?? '-'),
            _buildTableCell(facility.tubeCountP?.toString() ?? '-'),
          ],
        ),
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[25],
          ),
          children: [
            _buildTableCell('R (RunnerBoy)', Colors.orange[600]!),
            _buildTableCell(facility.sampleCount.toString() ),
            _buildTableCell(facility.tubeCount.toString() ),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('L (Lab)', Colors.purple[600]!),
            isSelected && !isSubmitted
                ? _buildEditableTableCell(trfLController, (value) => trfLController.text = value)
                : _buildTableCell(facility.trfCountL?.toString() ?? '-'),
            isSelected && !isSubmitted
                ? _buildEditableTableCell(tubeCountLController, (value) => tubeCountLController.text = value)
                : _buildTableCell(facility.tubeCountL?.toString() ?? '-'),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.grey,
        ),
        textAlign: TextAlign.start,
      ),
    );
  }

  Widget _buildTableCell(String text, [Color? labelColor]) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (labelColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: labelColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: labelColor ?? Colors.grey[800],
                fontWeight: labelColor != null ? FontWeight.w500 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableTableCell(TextEditingController controller, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: InputFormatters.digits,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        style:  const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold
        ),
        textAlign: TextAlign.center,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildModernCheckbox(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        border: Border.all(
          color: isSelected ? Colors.white : Colors.grey[400]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: isSelected
          ? const Icon(
        Icons.check,
        color: AppColors.primary,
        size: 16,
      )
          : null,
    );
  }
}



