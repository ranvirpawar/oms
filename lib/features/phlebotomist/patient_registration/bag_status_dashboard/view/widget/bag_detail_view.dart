import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../constants/app_assets.dart';
import '../../../../../../theme/app_colors.dart';
import '../../../../../../utils/widgets/custom_appbar.dart';
import '../../controller/patient_list_controller.dart';
import '../../controller/registrarion_bag_controller.dart';
import '../../model/active_bag_model.dart';
import '../../model/qr_bag_details.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'collected_order_card.dart';

class BagDetailView extends StatefulWidget {
  const BagDetailView({super.key});

  @override
  State<BagDetailView> createState() => _BagDetailViewState();
}

class _BagDetailViewState extends State<BagDetailView>
    with SingleTickerProviderStateMixin {
  late final int sessionId;
  late final int bagId;
  late final String bagcode;

  final BagRegistrationController _ctrl = Get.find();
  late final PatientListController _patientCtrl;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, dynamic>;
    sessionId = args['sessionId'] as int;
    bagId = args['bagId'] as int;
    bagcode = args['bagcode'] as String;

    _patientCtrl = Get.put(
      PatientListController(),
      tag: 'detail_$bagId',
    );

    _patientCtrl.isScoped = true;

    _patientCtrl.preSelectBag(
      sessionId: sessionId,
      bagId: bagId,
      bagcode: bagcode,
    );

    _ctrl.ensureBagDetailsLoaded(bagId);
  }

  @override
  void dispose() {
    Get.delete<PatientListController>(tag: 'detail_$bagId');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: CustomAppBar(
          title: 'Bag · $bagcode',
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorPadding: const EdgeInsets.all(2),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                tabs: const [
                  Tab(
                    height: 38,
                    icon: Icon(Icons.analytics_outlined, size: 16),
                    text: 'Overview',
                  ),
                  Tab(
                    height: 38,
                    icon: Icon(Icons.people_alt_outlined, size: 16),
                    text: 'Collected Orders',
                  ),

                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(
                    ctrl: _ctrl,
                    bagId: bagId,
                    patientCtrl: _patientCtrl,
                  ),
                  _InlinePatientTab(
                    ctrl: _patientCtrl,
                    bagId: bagId,
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ─── Tab 1: Overview ──────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final BagRegistrationController ctrl;
  final int bagId;

    final PatientListController patientCtrl;


   const _OverviewTab({required this.ctrl, required this.bagId, required this.patientCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final details = ctrl.bagDetailsMap[bagId];
      final session =
          ctrl.allSessions.firstWhereOrNull((s) => s.bagId == bagId);
      final isOpen = session?.isOpen ?? false;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusBanner(isOpen: isOpen, bagcode: session?.bagcode ?? ''),
            const SizedBox(height: 20),
            if (details != null) ...[
              _CapacityCard(details: details),
              const SizedBox(height: 16),
              _StatGrid(details: details),
              const SizedBox(height: 16),

              /// submit to lab button
              Obx(() {
                final isOpen = session?.isOpen ?? false;
                final isSubmitting = patientCtrl.isSubmittingToLab.value;

                if (!isOpen) return const SizedBox.shrink(); // already closed

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: isSubmitting
                        ? null
                        : const LinearGradient(
                      colors: [Color(0xFFE65100), Color(0xFFFF7043)],
                    ),
                    color: isSubmitting ? Colors.grey.shade200 : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSubmitting
                        ? []
                        : [
                      BoxShadow(
                        color: const Color(0xFFE65100).withOpacity(0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: isSubmitting
                          ? null
                          : () => _showSubmitToLabSheet(context, patientCtrl),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Center(
                          child: isSubmitting
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Submitting to Lab…',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.5,
                                ),
                              ),
                            ],
                          )
                              : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                color: Colors.white,
                                size: 19,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Submit Bag to Lab',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      );
    });
  }
  void _showSubmitToLabSheet(
      BuildContext context,
      PatientListController ctrl,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SubmitToLabSheet(ctrl: ctrl),
    );
  }
}
class _SubmitToLabSheet extends StatelessWidget {
  final PatientListController ctrl;
  const _SubmitToLabSheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Color(0xFFE65100),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          // ── title
          const Text(
            'Submit Bag to Lab?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // ── message
          Obx(() {
            final bagcode =
                ctrl.selectedSession.value?.bagcode ?? 'this bag';
            return Text(
              'You\'re about to submit bag $bagcode to the lab for processing. '
                  'Once submitted, no new patients can be registered to this bag '
                  'and the action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade600,
                height: 1.55,
              ),
            );
          }),
          const SizedBox(height: 8),

          // ── warning chip
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFCC80),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 15,
                  color: Color(0xFFE65100),
                ),
                SizedBox(width: 6),
                Text(
                  'This action is irreversible',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── buttons
          Row(
            children: [
              // Cancel
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Confirm — with loading state
              Expanded(
                flex: 2,
                child: Obx(() {
                  final isLoading = ctrl.isSubmittingToLab.value;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isLoading
                          ? null
                          : const LinearGradient(
                        colors: [
                          Color(0xFFE65100),
                          Color(0xFFFF7043),
                        ],
                      ),
                      color: isLoading ? Colors.grey.shade200 : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isLoading
                          ? []
                          : [
                        BoxShadow(
                          color:
                          const Color(0xFFE65100).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: isLoading ? null : ctrl.submitToLab,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: isLoading
                                ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Submitting…',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                                : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Yes, Submit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _InlinePatientTab extends StatelessWidget {
  final PatientListController ctrl;
  final int bagId;

  const _InlinePatientTab({
    required this.ctrl,
    required this.bagId,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingPatients.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: ctrl.fetchPatients,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search bar ─────────────────────────────────────────────
              _SearchBar(ctrl: ctrl),
              const SizedBox(height: 20),

              // ── Patient list ───────────────────────────────────────────
              _PatientListBody(ctrl: ctrl),
            ],
          ),
        ),
      );
    });
  }
}

class _SearchBar extends StatelessWidget {
  final PatientListController ctrl;

  const _SearchBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl.searchTextController,
      onChanged: ctrl.onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search by name or barcode',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFB0BAC9)),
        prefixIcon: const Icon(Icons.search_rounded,
            color: Color(0xFFB0BAC9), size: 20),
        suffixIcon: Obx(() => ctrl.searchQuery.value.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Color(0xFFB0BAC9), size: 18),
                onPressed: () {
                  ctrl.searchTextController.clear();
                  ctrl.onSearchChanged('');
                },
              )
            : const SizedBox.shrink()),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _PatientListBody extends StatelessWidget {
  final PatientListController ctrl;

  const _PatientListBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.filteredPatientList.isEmpty) {
        return _EmptyPatients(isSearching: ctrl.searchQuery.value.isNotEmpty);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 2),
            child: Text(
              '${ctrl.filteredPatientList.length} of ${ctrl.patientList.length} '
              'Patient${ctrl.patientList.length != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF718096),
              ),
            ),
          ),
          ...ctrl.filteredPatientList.asMap().entries.map((entry) {
            return CollectedOrderCard(order: entry.value, );
          }),
        ],
      );
    });
  }
}




// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyPatients extends StatelessWidget {
  final bool isSearching;

  const _EmptyPatients({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF48BB78).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              AppAssets.patient,
              width: 40,
              height: 40,
              colorFilter:
                  const ColorFilter.mode(Color(0xFF48BB78), BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No Results Found' : 'No Patients Registered',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No patients match your search.\nTry a different name or barcode.'
                : 'No patient samples have been registered\nfor this bag session yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Overview Widgets ─────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final bool isOpen;
  final String bagcode;

  const _StatusBanner({required this.isOpen, required this.bagcode});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? const Color(0xFF48BB78) : const Color(0xFFED8936);
    final label = isOpen ? 'Active · Collecting' : 'Closed · Not Collecting';
    final icon = isOpen ? Icons.fiber_manual_record : Icons.lock_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bagcode,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A202C),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  final QRBagDetails details;

  const _CapacityCard({required this.details});

  @override
  Widget build(BuildContext context) {
    final pct = details.capacity > 0
        ? (details.patientCount / details.capacity).clamp(0.0, 1.0)
        : 0.0;
    final Color fillColor = pct >= 0.9
        ? const Color(0xFFFC8181)
        : pct >= 0.6
            ? const Color(0xFFED8936)
            : const Color(0xFF48BB78);

    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Space Utilization',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${details.patientCount}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: fillColor,
                        letterSpacing: -1,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${details.capacity}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: fillColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFFEDF2F7),
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${details.spaceVacant} slot${details.spaceVacant == 1 ? '' : 's'} remaining',
            style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final QRBagDetails details;

  const _StatGrid({required this.details});

  @override
  Widget build(BuildContext context) {
    final pct = details.capacity > 0
        ? (details.patientCount / details.capacity * 100).toStringAsFixed(0)
        : '0';

    final items = [
      _GridItem('Total Capacity', details.capacity.toString(),
          Icons.all_inbox_rounded, const Color(0xFF4299E1)),
      _GridItem('Tubes Filled', details.patientCount.toString(),
          Icons.colorize_rounded, const Color(0xFFED8936)),
      _GridItem('Slots Vacant', details.spaceVacant.toString(),
          Icons.inbox_rounded, const Color(0xFF48BB78)),
      _GridItem('Fill Rate', '$pct%', Icons.pie_chart_outline_rounded,
          AppColors.primary),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items.map((item) => _StatTile(item: item)).toList(),
    );
  }
}

class _StatTile extends StatelessWidget {
  final _GridItem item;

  const _StatTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: item.color,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridItem {
  final String label, value;
  final IconData icon;
  final Color color;

  _GridItem(this.label, this.value, this.icon, this.color);
}
