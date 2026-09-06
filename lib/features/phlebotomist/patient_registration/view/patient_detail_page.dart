import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lifenity_connect/componenents/info_row_widget.dart';
import 'package:lifenity_connect/constants/app_assets.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/view/widget/trf_gallery_viewer.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';
import 'package:lifenity_connect/utils/helper_functions/input_formatter.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

// views/patient_registration_list.dart
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../controller/registered_patient_controller.dart';

import '../models/registered_patient_model.dart';

class PatientDetailPage extends StatefulWidget {
  final Map<String, dynamic> patient;
  final RegisteredPatientController controller;

  const PatientDetailPage({
    super.key,
    required this.patient,
    required this.controller,
  });

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  late final List<RegisteredPatient> tests;
  late final RegisteredPatient firstPatient;
  late final List<String> trfImages;

  @override
  void initState() {
    super.initState();
    tests = widget.patient['tests'] as List<RegisteredPatient>;
    firstPatient = tests.first;
    trfImages = tests
        .where((t) => t.hasValidTrfLink)
        .map((t) => t.trfFilePath)
        .where((url) => url.startsWith('http://') || url.startsWith('https://'))
        .toSet() // deduplicate
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.patient);
    for (final test in widget.patient['tests']) {
      print(test.toJson().toString());
    }
    final barcode = widget.patient['barcode'] as String;
    final fullName = widget.patient['fullname'] as String;
    final age = widget.patient['age'] as String;
    final addDate = widget.patient['adddate'] as DateTime?;
    final isImported = firstPatient.importStatus == 1;
    final mobile = firstPatient.mobile as String;

    return Scaffold(
      appBar: CustomAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              HelperMethods.capitalizeFirstLetter(fullName),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
            const SizedBox(height: 4),
            Row(children: [_statusBadge(context, isImported)]),
          ],
        ),
        /* actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _showEditBottomSheet(context, widget.controller),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ],*/
      ),
      bottomNavigationBar: firstPatient.billFreezed == 0
          ? Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, color: Colors.red, size: 18),
                  SizedBox(width: 10),
                  FittedBox(
                    child: Text(
                      'Editing is disabled once the invoice is generated',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showEditBottomSheet(context, widget.controller),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Edit Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      /* bottomNavigationBar:TextButton.icon(
        onPressed: () => _showEditBottomSheet(context, widget.controller),
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Edit'),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
      ) ,*/
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info cards row
                  Row(
                    children: [
                      Expanded(
                        child: InfoRow(
                          title: 'Barcode',
                          icon: AppAssets.barcodeIcon,
                          value: barcode,
                        ),
                      ),
                      Expanded(
                        child: InfoRow(
                          title: 'Mobile',
                          icon: AppAssets.mobileIcon,
                          value: mobile,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InfoRow(
                          title: 'Age',
                          value: age,
                          icon: AppAssets.calendarIcon,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InfoRow(
                          title: 'Date',
                          value: widget.controller.formatDate(addDate),
                          icon: AppAssets.calendarIcon,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (firstPatient.patientType != null &&
                          firstPatient.patientType!.isNotEmpty)
                        Expanded(
                          child: InfoRow(
                            title: 'Patient Type',
                            value: firstPatient.patientType!,
                            icon: AppAssets.patient,
                          ),
                        ),
                      if (firstPatient.patientType != null &&
                          firstPatient.patientType!.isNotEmpty)
                        const SizedBox(width: 10),
                      if (firstPatient.opdNumber != null &&
                          firstPatient.opdNumber!.isNotEmpty)
                        Expanded(
                          child: InfoRow(
                            title: 'OPD No.',
                            value: firstPatient.opdNumber!,
                            icon: AppAssets.fileNoteIcon,
                          ),
                        ),
                    ],
                  ),
                  // receipt number row
                  if (firstPatient.basicReceipt != null &&
                          firstPatient.basicReceipt!.isNotEmpty ||
                      firstPatient.advanceReceipt != null &&
                          firstPatient.advanceReceipt!.isNotEmpty)
                    const SizedBox(height: 10),
                  Row(
                    children: [
                      if (firstPatient.basicReceipt != null &&
                          firstPatient.basicReceipt!.isNotEmpty)
                        Expanded(
                          child: InfoRow(
                            title: 'Basic Receipt',
                            value: firstPatient.basicReceipt!,
                            icon: AppAssets.fileNoteIcon,
                          ),
                        ),
                      if (firstPatient.advanceReceipt != null &&
                          firstPatient.advanceReceipt!.isNotEmpty)
                        const SizedBox(width: 10),
                      if (firstPatient.advanceReceipt != null &&
                          firstPatient.advanceReceipt!.isNotEmpty)
                        Expanded(
                          child: InfoRow(
                            title: 'Advance Receipt',
                            value: firstPatient.advanceReceipt!,
                            icon: AppAssets.fileNoteIcon,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // TRF Gallery Section
                  if (trfImages.isNotEmpty) ...[
                    _sectionHeader(
                      context,
                      'TRF Documents',
                      '${trfImages.length} image${trfImages.length > 1 ? 's' : ''}',
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: trfImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () => _openGallery(context, i),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  trfImages[i],
                                  width: 110,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (_, child, progress) =>
                                      progress == null
                                      ? child
                                      : Container(
                                          width: 110,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 110,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              // Overlay icon
                              Positioned(
                                right: 6,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                              // Index badge
                              Positioned(
                                left: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Tests section
                  _sectionHeader(context, 'Tests', '${tests.length} total'),
                  const SizedBox(height: 10),
                  ...tests.asMap().entries.map(
                    (e) => _buildTestTile(context, e.value, e.key),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context, bool isImported) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.1),

        /*color: isImported
            ? Colors.green.withOpacity(0.12)
            : Colors.orange.withOpacity(0.12),*/
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isImported ? 'Authenticated' : 'Report Pending',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.surface,
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
          ),
        ),
      ],
    );
  }

  Widget _buildTestTile(
    BuildContext context,
    RegisteredPatient test,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              test.serviceName,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: test.importStatus == 1
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              test.importStatus == 1 ? 'Done' : 'Pending',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: test.importStatus == 1
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TrfGalleryViewer(imageUrls: trfImages, initialIndex: initialIndex),
      ),
    );
  }

  void _showEditBottomSheet(
    BuildContext context,
    RegisteredPatientController controller,
  ) {
    final isImported = firstPatient.importStatus == 1;

    final opdCtrl = TextEditingController(text: firstPatient.opdNumber ?? '');
    final basicCtrl = TextEditingController(
      text: firstPatient.basicReceipt ?? '',
    );
    final advCtrl = TextEditingController(
      text: firstPatient.advanceReceipt ?? '',
    );
    final mobileCtrl = TextEditingController(text: firstPatient.mobile ?? '');

    const patientTypes = ['OPD', 'IPD', 'Emergency', 'Camp'];
    String selectedType = patientTypes.contains(firstPatient.patientType)
        ? firstPatient.patientType!
        : patientTypes.first;

    // Reset verification states when opening bottom sheet
    controller.isOpdVerified.value = true;
    controller.isOPDVerifying.value = false;
    controller.isMobileVerified.value = true; // ← reset mobile state
    controller.isMobileVerifying.value = false;
    controller.mobileNumberError.value = '';

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*     // ── drag handle ──
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),*/
                Text(
                  'Edit Patient Info',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (isImported) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Patient Type cannot be changed once the report is authenticated.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // ── OPD Number ──
                Obx(
                  () => TextField(
                    controller: opdCtrl,

                    decoration: InputDecoration(
                      labelText: 'OPD Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorText: controller.isOpdVerified.value
                          ? null
                          : 'OPD number already exists',
                      suffixIcon: controller.isOPDVerifying.value
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : opdCtrl.text.trim().isNotEmpty
                          ? (controller.isOpdVerified.value
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ))
                          : null,
                    ),
                    onChanged: (val) {
                      setModalState(() {});
                      controller.autoVerifyOpd(
                        val.trim(),
                        firstPatient.opdNumber,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ── Basic & Advance Receipt ──
                Row(
                  children: [
                    Expanded(
                      child: _editField(context, 'Basic Receipt', basicCtrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _editField(context, 'Advance Receipt', advCtrl),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Mobile Number with live validation ──
                Obx(
                  () => TextField(
                    controller: mobileCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: InputFormatters.digits,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorText: controller.mobileNumberError.value.isNotEmpty
                          ? controller.mobileNumberError.value
                          : null,
                      suffixIcon: controller.isMobileVerifying.value
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : mobileCtrl.text.trim().length == 10
                          ? (controller.isMobileVerified.value
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ))
                          : null,
                    ),
                    onChanged: (val) {
                      setModalState(() {}); // refresh suffix icon reactively
                      if (val.trim().length == 10) {
                        controller.validateMobileNumber(
                          val.trim(),
                          firstPatient.mobile,
                        );
                      } else {
                        // clear stale error while user is still typing
                        controller.isMobileVerified.value = false;
                        controller.mobileNumberError.value = '';
                      }
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ── Patient Type ──
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Patient Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabled: !isImported,
                  ),
                  items: isImported
                      ? null
                      : patientTypes
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                  onChanged: isImported
                      ? null
                      : (val) {
                          if (val != null) {
                            setModalState(() => selectedType = val);
                          }
                        },
                ),

                const SizedBox(height: 24),

                // ── Save Button ──
                Obx(() {
                  // Disable if any verification is in-progress or failed
                  final bool canSave =
                      !controller.isOPDVerifying.value &&
                      controller.isOpdVerified.value &&
                      !controller.isMobileVerifying.value &&
                      controller.isMobileVerified.value;

                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: canSave
                          ? () {
                              final newOpd = isImported
                                  ? (firstPatient.opdNumber ?? '')
                                  : opdCtrl.text.trim();

                              widget.controller.updatePatient(
                                orderId: firstPatient.orderno,
                                opdNumber: newOpd,
                                basicReceipt: basicCtrl.text.trim(),
                                advanceReceipt: advCtrl.text.trim(),
                                patientType: isImported
                                    ? (firstPatient.patientType ?? '')
                                    : selectedType,
                                mobile: mobileCtrl.text.trim(),
                                importStat: firstPatient.importStatus
                                    .toString(),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        controller.isMobileVerifying.value
                            ? 'Verifying Mobile...'
                            : controller.isOPDVerifying.value
                            ? 'Verifying OPD...'
                            : 'Save Changes',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField(
    BuildContext context,
    String label,
    TextEditingController ctrl, {
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
