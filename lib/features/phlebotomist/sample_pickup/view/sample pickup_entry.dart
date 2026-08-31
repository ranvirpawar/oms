import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lifenity_connect/componenents/c_textformfeild.dart';
import 'package:lifenity_connect/constants/app_assets.dart';
import 'package:lifenity_connect/constants/app_strings.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_pickup/model/phlebo_sample_pickup.dart';
import 'package:lifenity_connect/utils/helper_functions/input_formatter.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/utils/widgets/modern_dropdown.dart';
import 'package:signature/signature.dart';

import '../../../../theme/app_colors.dart';

import '../controller/sample_pickup_entry_controller.dart';
import '../model/work_item_model.dart';
class SamplePickupEntryView extends StatelessWidget {
  SamplePickupEntryView({super.key});

  final SamplePickUpEntryViewController samplePickupEntryController =
  Get.put(SamplePickUpEntryViewController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Sample Pickup'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildModernTabBar(),
            Expanded(
              child: Obx(() {
                if (samplePickupEntryController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return TabBarView(
                  controller: samplePickupEntryController.tabController,
                  children: [
                    _buildSamplePickUpSection(),
                    _buildSubmitToLabSection(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Obx(() => Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0 , 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: samplePickupEntryController.tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.primary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AppAssets.medBackpack,
                  color: samplePickupEntryController.currentTabIndex.value == 0
                      ? Colors.white
                      : AppColors.primary400,
                ),
                const SizedBox(width: 8),
                const Text('Sample Pickup'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AppAssets.labTechnician,
                  height: 30,
                  color: samplePickupEntryController.currentTabIndex.value == 1
                      ? Colors.white
                      : AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text('Send to Lab'),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildSamplePickUpSection() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDateSelector(samplePickupEntryController),
          const SizedBox(height: 16),
          Obx(() => ModernDropdown(
            enableSearch: true,
            label: 'Select Facility',
            value: samplePickupEntryController
                .selectedFacility.value?.facilityName ??
                '',
            items: samplePickupEntryController.facilityPickupList
                .map((item) => item.facilityName ?? '')
                .toList(),
            onChanged: (value) {
              final selected = samplePickupEntryController
                  .facilityPickupList
                  .firstWhere((item) => item.facilityName == value);
              samplePickupEntryController.selectFacility(selected);
            },
          )),
          const SizedBox(height: 16),
          Obx(() => samplePickupEntryController.selectedFacility.value != null
              ? Column(
            children: [
              _buildFacilityCard(
                  samplePickupEntryController.selectedFacility.value!),
              // Remark
              CFormTextField(
                controller: samplePickupEntryController.remarkController,
                label: AppStrings.remark,
                iconPath: AppAssets.infoIcon,
              ),
              const SizedBox(height: 16),
              // Signature Pad
              _buildSignatureSection(samplePickupEntryController),

              const SizedBox(height: 16),
              // Clear and Submit Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          samplePickupEntryController.submitData(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Submit',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          )
              : Container()),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSubmitToLabSection() {
    return Column(
      children: [
        _buildDateSelector(samplePickupEntryController),
        const SizedBox(height: 16),
        Expanded(
          child: Obx(() {
            if (samplePickupEntryController.workList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No facilities available for lab submission',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: samplePickupEntryController.workList.length,
                    itemBuilder: (context, index) {
                      final facility =
                      samplePickupEntryController.workList[index];
                      // Check if facility has lab data (either TRF count or tube count for lab)
                      /*final hasLabData = (facility.trfCountL != null && facility.trfCountL! > 0) ||
                          (facility.tubeCountL != null && facility.tubeCountL! > 0);*/
                      final hasLabData = facility.isSubmittedAccepted == 1;
                      return _buildLabFacilityCard(facility, hasLabData);

                    },
                  ),
                ),
                Obx(() => samplePickupEntryController
                    .selectedLabFacilities.isNotEmpty
                    ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        '${samplePickupEntryController.selectedLabFacilities.length} facilities selected',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              samplePickupEntryController.submitToLab(),
                          style: ElevatedButton.styleFrom(
                            // backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Submit to Lab',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
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
      ],
    );
  }

  Widget _buildLabFacilityCard(WorkItem facility, bool hasLabData) {
    return Obx(() {
      final isSelected =
      samplePickupEntryController.isLabFacilitySelected(facility);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasLabData
                ? Colors.grey[300]!
                : (isSelected ? AppColors.primary : Colors.grey[200]!),
            width: isSelected && !hasLabData ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected && !hasLabData
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: isSelected && !hasLabData ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: hasLabData ? null : () {

            samplePickupEntryController.toggleLabFacilitySelection(facility);
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasLabData ? AppColors.accent900 : null,
                  gradient: hasLabData
                      ? null
                      : AppColors.primaryGradientRev,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        facility.facilityName ?? '',
                        style: TextStyle(
                          color: hasLabData
                              ? Colors.white
                              : (isSelected ? Colors.white : Colors.white),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    hasLabData
                        ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Submitted',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                        : _buildModernCheckbox(isSelected),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(0),
                child: _buildLabDataTable(facility),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLabDataTable(WorkItem facility) {
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
            _buildTableCell(facility.sampleCount.toString() ?? '-'),
            _buildTableCell(facility.tubeCount.toString() ?? '-'),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('L (Lab)', Colors.purple[600]!),
            _buildTableCell(facility.trfCountL?.toString() ?? '-'),
            _buildTableCell(facility.tubeCountL?.toString() ?? '-'),
          ],
        ),
      ],
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

  Widget _buildSignatureSection(controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // rich text to make it mandatory
              RichText(
                text: const TextSpan(
                  text: 'Runner Boy Signature',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  children: [
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: controller.clearSignature,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(Get.context!)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.refresh,
                      size: 18,
                      color: Theme.of(Get.context!).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Signature(
              controller: controller.signatureController,
              backgroundColor: Colors.grey[50]!,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please sign above',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          // Signature error
        ],
      ),
    );
  }

  Widget _buildDateSelector(SamplePickUpEntryViewController controller) {
    return Container(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          SvgPicture.asset(AppAssets.calendarIcon,
              color: AppColors.primary, height: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => Text(
              'Date: ${controller.selectedDate.value.toString().split(' ')[0]}',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800]),
            )),
          ),
          GestureDetector(
            onTap: () => controller.selectDate(Get.context!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.calendar_month, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Pick Date',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(PhleboSamplePickup facility) {
    final TextEditingController trfRController =
    TextEditingController(text: facility.trfP?.toString() ?? '');
    final TextEditingController tubeCountRController =
    TextEditingController(text: facility.sampleCount?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradientRev,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.facilityName ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                _buildDataTable(facility, trfRController, tubeCountRController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(
      PhleboSamplePickup facility,
      TextEditingController trfRController,
      TextEditingController tubeCountRController) {
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
            _buildTableCell(facility.sampleCount?.toString() ?? '-'),
          ],
        ),
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[25],
          ),
          children: [
            _buildTableCell('R (RunnerBoy)', Colors.orange[600]!),
            _buildEditableTableCell(trfRController, (value) {
              samplePickupEntryController.trfRController.text = value;
            }),
            _buildEditableTableCell(tubeCountRController, (value) {
              samplePickupEntryController.tubeCountRController.text = value;
            }),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('L (Lab)', Colors.purple[600]!),
            _buildTableCell('-'),
            _buildTableCell('-'),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.grey[700],
        ),
        textAlign: TextAlign.start,
      ),
    );
  }

  Widget _buildTableCell(String text, [Color? labelColor]) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
                fontSize: 12,
                color: labelColor ?? Colors.grey[800],
                fontWeight:
                labelColor != null ? FontWeight.w500 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableTableCell(
      TextEditingController controller, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: InputFormatters.digits,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
        ),
        textAlign: TextAlign.center,
        onChanged: onChanged,
      ),
    );
  }
}
