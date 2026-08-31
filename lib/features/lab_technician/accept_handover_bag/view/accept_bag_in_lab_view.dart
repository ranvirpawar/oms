// lib/features/lab_technician/accept_bag_in_lab/view/accept_bag_in_lab_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/lab_technician/accept_handover_bag/view/widgets/action_button.dart';
import 'package:lifenity_connect/features/lab_technician/accept_handover_bag/view/widgets/manual_input.dart';
import 'package:lifenity_connect/features/lab_technician/accept_handover_bag/view/widgets/scanner_widget.dart';
import 'package:lifenity_connect/features/lab_technician/accept_handover_bag/view/widgets/section_header.dart';
import 'package:lifenity_connect/features/lab_technician/accept_handover_bag/view/widgets/session_container.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../constants/app_strings.dart';

import '../../../../theme/app_colors.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../../../phlebotomist/accept_bag/view/widget/scanner_bottomsheet.dart';
import '../controller/accept_bag_in_lab_controller.dart';
import '../model/bag_details_extended_model.dart';
import '../model/bag_model_new.dart';

class AcceptBagInLabView extends StatelessWidget {
  const AcceptBagInLabView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AcceptBagInLabController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.acceptBagInLab,
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: IconButton(
                  icon: Icon(
                    controller.flashlightEnabled.value
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: controller.flashlightEnabled.value
                        ? Colors.amber
                        : AppColors.surfaceContainer,
                  ),
                  onPressed: controller.toggleFlashlight,
                ),
              )),
        ],
      ),
      body: Column(
        children: [
          // ────── Collapsible Scanner Section ──────────────────────────────
          Obx(() {
            final hasBag = controller.bagDetails.value != null;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: hasBag ? 100 : MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Scanner feed
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(hasBag ? 20 : 0)),
                    child: MobileScanner(
                      controller: controller.scannerController,
                      onDetect: controller.onBarcodeDetected,
                    ),
                  ),

                  // Scan overlay (full-screen mode)
                  if (!hasBag)
                    CustomPaint(
                      painter: ScannerOverlayPainter(),
                      child: const Center(
                          child: AnimatedScanLine(height: 250, width: 250)),
                    ),

                  // Collapsed header (after scan)
                  if (hasBag)
                    CollapsedScannerHeader(controller: controller),

                  // Loading overlay
                  Obx(() => controller.isLoading.value
                      ? Container(
                          color: Colors.black54,
                          child: const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white)))
                      : const SizedBox.shrink()),

                  // Bottom hint (full-screen only)
                  if (!hasBag)
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Obx(() => ScannerHint(
                            active: controller.scannerActive.value,
                          )),
                    ),
                ],
              ),
            );
          }),

          // ────── Details Panel ─────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Obx(() {
                final bag = controller.bagDetails.value;
                final scan = controller.scanResult.value;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      SectionHeader(theme: theme),
                      const SizedBox(height: 20),

                      // Manual input (only when no bag scanned)
                      if (bag == null)
                        ManualInputField(
                            controller: controller, isDark: isDark),

                      // Placeholder (nothing scanned yet)
                      if (bag == null && !controller.isLoading.value)
                        EmptyPlaceholder(theme: theme),

                      // ── Bag Details Card ──────────────────────────────────
                      if (bag != null) ...[
                        if (scan != null) SessionBadgeRow(scan: scan),
                        const SizedBox(height: 16),
                        _BagDetailsCard(bag: bag, theme: theme, controller: controller),
                        const SizedBox(height: 28),
                        ActionButtons(controller: controller, theme: theme),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
class _BagDetailsCard extends StatelessWidget {
  final BagDetailsForLabOutput bag;
  final ThemeData theme;
  final AcceptBagInLabController controller; // ← add this param

  const _BagDetailsCard({
    required this.bag,
    required this.theme,
    required this.controller, // ← add this
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final hasTransfer =
        bag.bagTransferredBy != null && bag.bagTransferredBy!.isNotEmpty;

    return Column(
      children: [
        // ── Bag QR Code banner ──────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code_2,
                      color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bag QR Code',
                          style:
                          TextStyle(fontSize: 11, color: Colors.grey[500])),
                      Text(
                        bag.bagQRCode.isNotEmpty ? bag.bagQRCode : '—',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.5),
                      ),
                    ],
                  ),

                  // Tube count pill (right side)
                  const Spacer(),
                  if (bag.tubeCount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Text('Tubes',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500])),
                          Text(
                            '${bag.tubeCount}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // ── View Details button ──────────────────────────────────────
              const SizedBox(height: 10),
              Obx(() {
                final hasFacilities =
                    controller.facilityList.value != null ||
                        controller.patientList.value != null;
                final isLoading = controller.isLoading.value;

                return GestureDetector(
                  onTap: isLoading
                      ? null
                      : () => showBagDetailsSheet(context, controller),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isLoading
                        ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasFacilities
                              ? Icons.open_in_new_rounded
                              : Icons.hourglass_empty_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasFacilities
                              ? 'View Details'
                              : 'Loading details…',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Submitted By card ───────────────────────────────────────────────
        _PersonCard(
          title: 'Submitted By',
          icon: Icons.person_pin_outlined,
          name: bag.bagSubmittedBy,
          designation: bag.bagSubmittedByDesignation,
          mobile: bag.bagSubmittedByMobile,
          theme: theme,
          isDark: isDark,
          accentColor: theme.colorScheme.primary,
        ),

        // ── Transferred By card (only if present) ───────────────────────────
        if (hasTransfer) ...[
          const SizedBox(height: 10),
          _PersonCard(
            title: 'Transferred By',
            icon: Icons.swap_horiz_rounded,
            name: bag.bagTransferredBy ?? '',
            designation: bag.bagTransferredDesignation ?? '',
            mobile: bag.bagTransferredMobile ?? '',
            theme: theme,
            isDark: isDark,
            accentColor: Colors.orange,
          ),
        ],

        // ── Accepted info (if already accepted) ─────────────────────────────
        if (bag.acceptedBy.isNotEmpty) ...[
          const SizedBox(height: 10),
          _PersonCard(
            title: 'Accepted By',
            icon: Icons.check_circle_outline,
            name: bag.acceptedBy,
            designation: '',
            mobile: bag.acceptedOn,
            theme: theme,
            isDark: isDark,
            accentColor: Colors.green,
            mobileIcon: Icons.access_time_outlined,
          ),
        ],
      ],
    );
  }
}

// ── Reusable person info card ─────────────────────────────────────────────────
class _PersonCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String name;
  final String designation;
  final String mobile;
  final ThemeData theme;
  final bool isDark;
  final Color accentColor;
  final IconData mobileIcon;

  const _PersonCard({
    required this.title,
    required this.icon,
    required this.name,
    required this.designation,
    required this.mobile,
    required this.theme,
    required this.isDark,
    required this.accentColor,
    this.mobileIcon = Icons.phone_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? Colors.grey[850] : Colors.grey[50])!
            .withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent icon
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  name.isNotEmpty ? name : '—',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                if (designation.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(designation,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                ],
                if (mobile.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(mobileIcon,
                          size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(mobile,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ─── Sub-widgets ──────────────────────────────────────────────────────────────














void showBagDetailsSheet(
    BuildContext context, AcceptBagInLabController controller) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BagDetailsSheet(controller: controller),
  );
}

// ─── Sheet root ───────────────────────────────────────────────────────────────

class _BagDetailsSheet extends StatelessWidget {
  final AcceptBagInLabController controller;
  const _BagDetailsSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH ,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                    theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_outlined,
                      color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bag Details',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Obx(() {
                        final patients =
                            controller.patientList.value?.length ?? 0;
                        final facilities =
                            controller.facilityList.value?.length ?? 0;
                        return Text(
                          '$facilities facilit${facilities == 1 ? 'y' : 'ies'} · $patients patient${patients == 1 ? '' : 's'}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        );
                      }),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close,
                      color: Colors.grey[400], size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor:
                    (isDark ? Colors.grey[800] : Colors.grey[100])!,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final facilities = controller.facilityList.value;
              final patients = controller.filteredPatients;

              if(controller.bagDetailsLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // if (facilities == null ) {
              //   // return empty facility list
              //   return const Center(child: Text('No facilities found'));
              // }

              return CustomScrollView(
                slivers: [
                  // ── Facility summary section ─────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _SectionLabel(
                        icon: Icons.local_hospital_outlined,
                        label: 'Facilities',
                        theme: theme,
                      ),
                    ),
                  ),

                  if (facilities == null || facilities.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'No facilities found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: _FacilityFilterRow(
                        facilities: facilities,
                        controller: controller,
                        theme: theme,
                      ),
                    ),

                  // Facility detail cards
                  if (facilities == null || facilities.isEmpty)
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 12),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (_, i) {
                            final filteredList = _filteredFacilities(
                              facilities,
                              controller.selectedFacility.value,
                            );

                            final f = filteredList[i];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FacilityCard(
                                facility: f,
                                theme: theme,
                              ),
                            );
                          },
                          childCount: _filteredFacilities(
                            facilities,
                            controller.selectedFacility.value,
                          ).length,
                        ),
                      ),
                    ),

                  // ── Patients section ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                      child: Row(
                        children: [
                          _SectionLabel(
                            icon: Icons.people_outline,
                            label: 'Patients',
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${patients.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (patients.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 20),
                        child: _EmptyPatients(theme: theme),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PatientCard(
                              patient: patients[i],
                              index: i,
                              theme: theme,
                            ),
                          ),
                          childCount: patients.length,
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  List<BagFacilityItem> _filteredFacilities(
      List<BagFacilityItem> all, String? selected) {
    if (selected == null) return all;
    return all.where((f) => f.facilityName == selected).toList();
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;
  const _SectionLabel(
      {required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

// ─── Facility filter chips row ────────────────────────────────────────────────

class _FacilityFilterRow extends StatelessWidget {
  final List<BagFacilityItem> facilities;
  final AcceptBagInLabController controller;
  final ThemeData theme;

  const _FacilityFilterRow({
    required this.facilities,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        children: [
          // "All" chip
          Obx(() => _FilterChip(
            label: 'All',
            count: facilities.fold<int>(0, (s, f) => s + f.tubeCount),
            isSelected: controller.selectedFacility.value == null,
            onTap: () => controller.selectedFacility.value = null,
            theme: theme,
          )),
          ...facilities.map((f) => Obx(() => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _FilterChip(
              label: f.facilityName,
              count: f.tubeCount,
              isSelected:
              controller.selectedFacility.value == f.facilityName,
              onTap: () =>
              controller.selectedFacility.value = f.facilityName,
              theme: theme,
            ),
          ))),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 6),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Facility detail card ─────────────────────────────────────────────────────

class _FacilityCard extends StatelessWidget {
  final BagFacilityItem facility;
  final ThemeData theme;
  const _FacilityCard({required this.facility, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.15),
        ),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon block
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(Icons.local_hospital_rounded,
                  color: theme.colorScheme.primary, size: 22),
            ),
          ),
          const SizedBox(width: 12),

          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.facilityName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  facility.fType,
                  style:
                  TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                if (facility.ward.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(
                        'Ward: ${facility.ward}',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Tube count badge
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${facility.tubeCount}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'tubes',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Patient card ──────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final BagPatientItem patient;
  final int index;
  final ThemeData theme;

  const _PatientCard({
    required this.patient,
    required this.index,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    // Avatar initials
    final nameParts = patient.patientName.trim().split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : patient.patientName.isNotEmpty
        ? patient.patientName[0].toUpperCase()
        : '?';

    // Avatar background color — rotate through a few accent colors
    final avatarColors = [
      const Color(0xFF7F77DD),
      const Color(0xFF1D9E75),
      const Color(0xFFD85A30),
      const Color(0xFFD4537E),
      const Color(0xFF378ADD),
    ];
    final avatarColor = avatarColors[index % avatarColors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.grey.withOpacity(0.15)
              : Colors.grey.withOpacity(0.12),
        ),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Order No row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        HelperMethods.capitalizeFirstLetter(patient.patientName),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Order badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        patient.orderNo,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey[300]
                              : Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Facility name
                Text(
                  patient.facilityName,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),

                // Meta row: collection time + ward
                Row(
                  children: [
                    if (patient.sampleCollectionTime.isNotEmpty) ...[
                      Icon(Icons.access_time_outlined,
                          size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        patient.sampleCollectionTime,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                    if (patient.ward.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          patient.ward,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────

class _EmptyPatients extends StatelessWidget {
  final ThemeData theme;
  const _EmptyPatients({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.person_search_outlined,
            size: 44, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(
          'No patients for this facility',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}