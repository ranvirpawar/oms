import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../componenents/c_textformfeild.dart';
import '../../../../constants/app_assets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../controller/merge_barcode_controller.dart';
import '../model/merge_test_patient_model.dart';


class MergeBarcodeView extends GetView<MergeBarcodeController> {
   MergeBarcodeView({super.key});
  final MergeBarcodeController controller = Get.put(MergeBarcodeController());

  static const Color kPrimaryAccent = Color(0xFF3B6DF5); // primary barcode
  static const Color kGlucoseAccent = Color(0xFFE8590C); // sugar barcode
  static const Color kSurface = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: const  CustomAppBar(
        title: 'Merge Barcode',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scan or enter both barcodes to merge the sugar (glucose) '
                'test into the primary order.',
                style: TextStyle(fontSize: 13.5, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 24),

              _StepSection(
                stepNumber: 1,
                title: 'Primary Barcode',
                accent: kPrimaryAccent,
                child: _buildBarcodeBlock(
                  fieldController: controller.primaryBarcodeController,
                  label: 'Primary Barcode',
                  isChecking: controller.isPrimaryChecking,
                  patient: controller.primaryPatient,
                  error: controller.primaryError,
                  accent: kPrimaryAccent,
                  suffix: Obx(() => _buildSuffixIcon(controller.isPrimaryChecking, controller.primaryPatient, kPrimaryAccent, isPrimary: true)),

                ),
              ),
              const SizedBox(height: 20),

              _StepSection(
                stepNumber: 2,
                title: 'Sugar Barcode',
                accent: kGlucoseAccent,
                child: _buildBarcodeBlock(
                  fieldController: controller.glucoseBarcodeController,
                  label: 'Sugar / Glucose Barcode',
                  isChecking: controller.isGlucoseChecking,
                  patient: controller.glucosePatient,
                  error: controller.glucoseError,
                  accent: kGlucoseAccent,
                  suffix: Obx(() => _buildSuffixIcon(controller.isGlucoseChecking, controller.glucosePatient, kGlucoseAccent, isPrimary: false)),
                ),
              ),

              const SizedBox(height: 32),
              _buildMergeButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarcodeBlock({
    required TextEditingController fieldController,
    required String label,
    required RxBool isChecking,
    required Rxn<MergeTestPatientModel> patient,
    required RxString error,
    required Color accent,
    required Widget suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CFormTextField(
          controller: fieldController,
          label: label,
          iconPath: AppAssets.barcodeIcon,
          isRequired: true,
          keyboardType: TextInputType.text,
          maxLength: 20,
          suffix: suffix,

          onChanged: (value) {
            // Listener on the controller handles debounced validation.
          },
        ),
        Obx(() {
          if (isChecking.value) {
            return const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Fetching patient details...',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Obx(() {
          if (error.value.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _ErrorBanner(message: error.value),
            );
          }
          return const SizedBox.shrink();
        }),
        Obx(() {
          final p = patient.value;
          if (p == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _PatientInfoCard(patient: p, accent: accent),
          );
        }),
      ],
    );
  }

   Widget _buildSuffixIcon(
       RxBool isChecking,
       Rxn<MergeTestPatientModel> patient,
       Color accent,
       {required bool isPrimary} // NEW param, needed to route the tap
       ) {
     if (isChecking.value) {
       return const SizedBox(
         width: 20,
         height: 20,
         child: Padding(
           padding: EdgeInsets.all(4.0),
           child: CircularProgressIndicator(strokeWidth: 2),
         ),
       );
     }

     if (patient.value != null) {
       return Icon(Icons.check_circle, color: accent, size: 24);
     }

     // Idle state: show scanner icon, tappable
     return GestureDetector(
       onTap: () => controller.openBarcodeScanner(isPrimary: isPrimary),
       child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 24),
     );
   }

  Widget _buildMergeButton() {
    return Obx(() {
      final enabled = controller.canMerge;
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: enabled
                ? const LinearGradient(
                    colors: [kPrimaryAccent, kGlucoseAccent],
                  )
                : null,
            color: enabled ? null : Colors.grey.shade300,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: kPrimaryAccent.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: enabled ? controller.mergeBarcodes : null,
              child: Center(
                child: controller.isMerging.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Merge Barcodes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: enabled ? Colors.white : Colors.black38,
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Numbered step header ("1  Primary Barcode") wrapping its field/card.
class _StepSection extends StatelessWidget {
  final int stepNumber;
  final String title;
  final Color accent;
  final Widget child;

  const _StepSection({
    required this.stepNumber,
    required this.title,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Compact card showing the fetched patient/visit metadata for a barcode.
class _PatientInfoCard extends StatelessWidget {
  final MergeTestPatientModel patient;
  final Color accent;

  const _PatientInfoCard({required this.patient, required this.accent});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  patient.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (patient.genderAgeInfo.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    patient.genderAgeInfo,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.badge_outlined, label: 'Order ID', value: patient.orderId),
          _InfoRow(icon: Icons.science_outlined, label: 'Service', value: patient.serviceName),
          _InfoRow(icon: Icons.local_hospital_outlined, label: 'Facility', value: patient.facilityName),
          _InfoRow(icon: Icons.event_outlined, label: 'Visit date', value: patient.formattedVisitDate),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.black45),
          const SizedBox(width: 6),
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
