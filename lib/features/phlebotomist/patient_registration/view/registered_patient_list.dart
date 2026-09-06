import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lifenity_connect/componenents/animations/animated_searchbar.dart';
import 'package:lifenity_connect/componenents/info_row_widget.dart';
import 'package:lifenity_connect/constants/app_assets.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/view/patient_detail_page.dart';
import 'package:lifenity_connect/routes/route_manager.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

// views/patient_registration_list.dart
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../controller/registered_patient_controller.dart';

import '../models/registered_patient_model.dart';
class PatientRegistrationList extends StatelessWidget {
  const PatientRegistrationList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisteredPatientController());

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: controller.facilityName.value,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.surfaceContainer),
            onPressed: controller.refreshData,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Modern Search Bar (never pinned, scrolls away nicely)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child:AnimatedSearchBar(hintValues: const ['barcode', '  name', 'mobile', '    opd'],
                  onChanged: controller.onSearchChanged,
                  onClear: controller.clearSearch),
            ),
          ),

          // 2. Pinned Compact Date Range Header
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: _SliverDateFilterHeader(
              child: _buildCompactDateFilter(context, controller),
              minHeight: 90,
              maxHeight: 90,
            ),
          ),


          // 3. The Patient List
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.groupedPatients.isEmpty) {
              return SliverFillRemaining(
                child: _buildEmptyState(context),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final patient = controller.groupedPatients[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildPatientTile(context, controller, patient, index),
                    );
                  },
                  childCount: controller.groupedPatients.length,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Modern Search Bar
  Widget _buildSearchBar(BuildContext context, RegisteredPatientController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
          onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by barcode, name or mobile, opd...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: controller.clearSearch,
          )
              : const SizedBox()),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  // Compact pinned date filter (slim version)
  Widget _buildCompactDateFilter(BuildContext context, RegisteredPatientController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical:0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildSlimDateField(
                  context,
                  label: 'From',
                  date: controller.fromDate.value,
                  onTap: () => controller.selectFromDate(context),
                  controller: controller,
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildSlimDateField(
                  context,
                  label: 'To',
                  date: controller.toDate.value,
                  onTap: () => controller.selectToDate(context),
                  controller: controller,
                )),
              ),
            ],
          ),
          Obx(() {
            final total = controller.groupedPatients.length;
            final isSearching = controller.searchQuery.value.trim().isNotEmpty;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isSearching
                        ? 'Showing $total result${total != 1 ? 's' : ''}'
                        : 'Total Patients: $total',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (isSearching)
                    Text(
                      'for "${controller.searchQuery.value}"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSlimDateField(
      BuildContext context, {
        required String label,
        required DateTime date,
        required VoidCallback onTap,
        required RegisteredPatientController controller,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min, // 🔥 IMPORTANT
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // 🔥 FIX
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    controller.formatDate(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // 🔥 FIX
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientTile(
      BuildContext context,
      RegisteredPatientController controller,
      Map<String, dynamic> patient,
      int index,
      ) {
    final barcode = patient['barcode'] as String;
    final fullName = patient['fullname'] as String;
    final age = patient['age'] as String;
    // final addDate = patient['adddate'] as DateTime?;
    final addDate = patient['adddate'] != null
        ? DateTime.tryParse(patient['adddate'].toString())
        : null;
    final tests = patient['tests'] as List<RegisteredPatient>;
    final importStatus = tests.first.importStatus;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: ()=>RouteManager.navigateToPatientDetailPage(patient, controller),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar circle with index
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + barcode
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      HelperMethods.capitalizeFirstLetter(fullName),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      barcode,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.formatDate(addDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right side: test count + import badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${tests.length} test${tests.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: importStatus == 1
                          ? Colors.green.withOpacity(0.12)
                          : Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      importStatus == 1 ? 'Authenticated' : 'Pending',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: importStatus == 1
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

// Keep _buildDateFilter, _buildDateField, _buildEmptyState exactly as before
  Widget _buildDateFilter(
      BuildContext context, RegisteredPatientController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      /*decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),*/
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Date Range',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildDateField(
                  context,
                  label: 'From Date',
                  date: controller.fromDate.value,
                  onTap: () => controller.selectFromDate(context),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildDateField(
                  context,
                  label: 'To Date',
                  date: controller.toDate.value,
                  onTap: () => controller.selectToDate(context),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildDateField(
      BuildContext context, {
        required String label,
        required DateTime date,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(1),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(AppAssets.calendarIcon,
                width: 20,
                height: 20,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Get.find<RegisteredPatientController>().formatDate(date),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No patients Registration found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your date range',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
class _SliverDateFilterHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _SliverDateFilterHeader({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

/*
class PatientRegistrationList extends StatelessWidget {
  const PatientRegistrationList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisteredPatientController());

    return Scaffold(
      appBar: CustomAppBar(title: controller.facilityName.value, actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.surfaceContainer),
          onPressed: controller.refreshData,
        )
      ]),
      body: Column(
        children: [
          _buildDateFilter(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.groupedPatients.isEmpty) {
                return _buildEmptyState(context);
              }

              return RefreshIndicator(
                onRefresh: controller.fetchPatients,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.groupedPatients.length,
                  itemBuilder: (context, index) {
                    final patient = controller.groupedPatients[index];
                    return _buildPatientCard(context, controller, patient, index);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(
      BuildContext context, RegisteredPatientController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      */
/*decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),*//*

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Date Range',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildDateField(
                      context,
                      label: 'From Date',
                      date: controller.fromDate.value,
                      onTap: () => controller.selectFromDate(context),
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildDateField(
                      context,
                      label: 'To Date',
                      date: controller.toDate.value,
                      onTap: () => controller.selectToDate(context),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(1),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(AppAssets.calendarIcon,
                width: 20,
                height: 20,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Get.find<RegisteredPatientController>().formatDate(date),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context,
      RegisteredPatientController controller, Map<String, dynamic> patient, int index) {
    final barcode = patient['barcode'] as String;
    final fullName = patient['fullname'] as String;
    final age = patient['age'] as String;
    final addDate = patient['adddate'] as DateTime?;
    final tests = patient['tests'] as List<RegisteredPatient>;

    return Obx(() {
      final isExpanded = controller.isExpanded(barcode);

      return Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.toggleExpanded(barcode),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(8),
                                */
/*decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),*//*

                                child: SvgPicture.asset(AppAssets.barcodeIcon,
                                    color: Theme.of(context).primaryColor),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      HelperMethods.capitalizeFirstLetter(fullName),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      barcode,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${tests.length} test${tests.length > 1 ? 's' : ''}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  AnimatedRotation(
                                    duration: const Duration(milliseconds: 200),
                                    turns: isExpanded ? 0.5 : 0,
                                    child: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isExpanded) ...[
                          Divider(
                            height: 1,
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withOpacity(0.5),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                        child: InfoRow(
                                            icon: AppAssets.calendarIcon,
                                            title: 'Date',
                                            value: controller.formatDate(addDate))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InfoRow(
                                        icon: AppAssets.userIcon,
                                        title: 'Age',
                                        value: age,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tests',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                ...tests.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final test = entry.value;
                                  return _buildTestItem(context, test, index);
                                }),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 4,
            top: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: FittedBox(
                  child: Text(
                    (index+1).toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }



  Widget _buildTestItem(
      BuildContext context, RegisteredPatient test, int index) {
    final isImported = test.importStatus == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(

        children: [
          // circular
          Container(
            width: 14,
            height: 14,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              (index + 1).toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              test.serviceName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No patients Registration found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your date range',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
          ),
        ],
      ),
    );
  }
}
*/
