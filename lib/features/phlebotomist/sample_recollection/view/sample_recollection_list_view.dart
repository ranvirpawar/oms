import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_recollection/view/recollection_test_selection_view.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_recollection/view/widget/recollection_accepted_card.dart';
import 'package:lifenity_connect/routes/route_manager.dart';

import '../../../../componenents/cdateformpicker_field.dart';
import '../../../../constants/app_assets.dart';
import '../../../../constants/app_strings.dart';
import '../../../../utils/animated_shimmer/patient_report_shimmer.dart';
import '../../../../utils/widgets/custom_appbar.dart';
import '../../../../utils/widgets/modern_dropdown.dart';

import '../controller/recollection_tests_controller.dart';
import '../controller/sample_recollection_controller.dart';
import '../model/test_recollection_model.dart';

class SampleRecollectionView extends StatelessWidget {
  final bool? isRefresh;

  SampleRecollectionView({super.key, this.isRefresh = false});

  final SampleRecollectionController controller =
      Get.put(SampleRecollectionController());

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        RouteManager.redirectToHomeDashboard();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: AppStrings.sampleRecollection,
          onBackPressed: () {
            RouteManager.redirectToHomeDashboard();
          },
        ),
        body: Obx(() {
          if (controller.initialLoading.value) {
            return const PatientReportShimmer();
          }
          return Column(
            children: [
              // Animated Search Section
              _buildCollapsedSearchSection(context),

              // Tab Bar
              _buildTabBar(context),
              const SizedBox(height: 12),

              // Search Box for filtering reports
              Obx(() => controller.getCurrentList().isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                        ),
                        child: TextField(
                          onChanged: (value) => controller.filterReports(value),
                          decoration: InputDecoration(
                            hintText: 'Search by name, or barcode...',
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey[600], size: 16),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            hintStyle: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),

              const SizedBox(height: 16),

              // Content based on selected tab
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return controller.selectedTab.value == 0
                      ? _buildPendingList(context)
                      : controller.selectedTab.value == 1
                          ? _buildAcceptedList(context)
                          : _buildDeniedList(context);
                }),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildTabItem(
                context: context,
                title: 'Requested',
                count: controller.recollectionPendingList.length,
                index: 0,
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              _buildTabItem(
                context: context,
                title: 'Accepted',
                count: controller.recollectionAcceptedList.length,
                index: 1,
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _buildTabItem(
                context: context,
                title: 'Denied',
                count: controller.recollectionDeniedList.length,
                index: 2,
                icon: Icons.cancel,
                color: Colors.red,
              ),
            ],
          ),
        ));
  }

  Widget _buildTabItem({
    required BuildContext context,
    required String title,
    required int count,
    required int index,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isSelected = controller.selectedTab.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /* Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(height: 4),*/
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingList(BuildContext context) {
    if (controller.filteredGroupedPendingList.isEmpty &&
        controller.groupedPendingList.isNotEmpty) {
      return _buildEmptyState('No reports found matching your search');
    }

    if (controller.groupedPendingList.isEmpty) {
      return _buildEmptyState('No Pending Tests for Recollection');
    }

    return Scrollbar(
      radius: const Radius.circular(16),
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.filteredGroupedPendingList.length,
        itemBuilder: (context, index) {
          final orderId =
              controller.filteredGroupedPendingList.keys.elementAt(index);
          final tests = controller.filteredGroupedPendingList[orderId]!;
          return _buildGroupedPendingCard(context, orderId, tests, index + 1);
        },
      ),
    );
  }

  Widget _buildAcceptedList(BuildContext context) {
    if (controller.filteredGroupedAcceptedList.isEmpty &&
        controller.groupedAcceptedList.isNotEmpty) {
      return _buildEmptyState('No reports found matching your search');
    }

    if (controller.groupedAcceptedList.isEmpty) {
      return _buildEmptyState('No Accepted Tests');
    }

    return Scrollbar(
      radius: const Radius.circular(16),
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.filteredGroupedAcceptedList.length,
        itemBuilder: (context, index) {
          final orderId =
              controller.filteredGroupedAcceptedList.keys.elementAt(index);
          final tests = controller.filteredGroupedAcceptedList[orderId]!;
          return  AcceptedCard(orderId: orderId, tests: tests, controller: controller, srNo: index+1);/*_buildGroupedAcceptedCard(context, orderId, tests, index + 1);*/

        },
      ),
    );
  }

  Widget _buildDeniedList(BuildContext context) {
    if (controller.filteredGroupedDeniedList.isEmpty &&
        controller.groupedDeniedList.isNotEmpty) {
      return _buildEmptyState('No reports found matching your search');
    }

    if (controller.groupedDeniedList.isEmpty) {
      return _buildEmptyState('No Denied Tests');
    }

    return Scrollbar(
      radius: const Radius.circular(16),
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.filteredGroupedDeniedList.length,
        itemBuilder: (context, index) {
          final orderId =
              controller.filteredGroupedDeniedList.keys.elementAt(index);
          final tests = controller.filteredGroupedDeniedList[orderId]!;
          return _buildGroupedDeniedCard(context, orderId, tests, index + 1);
        },
      ),
    );
  }

  Widget _buildGroupedPendingCard(
      BuildContext context, String orderId, List<RecollectionTestListUpdated> tests, int srNo) {
    final theme = Theme.of(context);
    final firstTest = tests.first;

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            // Navigate to recollection test selection with all tests for this orderId
            if (Get.isRegistered<RecollectTestsController>()) {
              Get.delete<RecollectTestsController>();
            }
            Get.to(() => RecollectionTestSelectionView(),
                arguments: firstTest, // Pass first test or modify to pass all tests
                transition: Transition.rightToLeft,
                duration: const Duration(milliseconds: 250));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, top: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Info Row
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AppAssets.patient,
                              width: 16,
                              height: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                firstTest.patientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Order ID and Gender
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AppAssets.barcodeIcon,
                              width: 16,
                              height: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                orderId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          firstTest.gender,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tests - Collapsible
                  Obx(() {
                    final expanded = controller.expandedCards.contains(orderId);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Clickable header row
                        GestureDetector(
                          onTap: () => controller.toggleCardExpansion(orderId),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                AppAssets.testTube,
                                width: 16,
                                height: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tests.length > 1
                                      ? '${tests.length} Tests'
                                      : firstTest.testName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (tests.length > 1)
                                Icon(
                                  expanded ? Icons.expand_less : Icons.expand_more,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                        // Expanded test list
                        if (expanded && tests.length > 1) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: tests.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final test = entry.value;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: idx < tests.length - 1 ? 8 : 0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${idx + 1}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          test.testName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 4,
          top: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
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
              child: Text(
                srNo.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

 /* Widget _buildGroupedAcceptedCard(
      BuildContext context, String orderId, List<RecollectionTestListUpdated> tests, int srNo) {
    final theme = Theme.of(context);
    final firstTest = tests.first;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12, top: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Info Row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppAssets.patient,
                            width: 16,
                            height: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              firstTest.patientName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Recollected',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Order IDs Row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppAssets.barcodeIcon,
                            width: 16,
                            height: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              orderId,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        firstTest.gender,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // New Barcode
                if (firstTest.recollectedBarcode != null)
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppAssets.barcodeIcon,
                        width: 16,
                        height: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "New: ${firstTest.recollectedBarcode}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),

                // Recollected Date
                if (firstTest.recollectedDate != null)
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppAssets.calendarIcon,
                        width: 16,
                        height: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Recollection Date: ${firstTest.recollectedDate}",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                const SizedBox(height: 8),

                // Tests - Collapsible
                Obx(() {
                  final expanded = controller.expandedCards.contains(orderId);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clickable header row
                      GestureDetector(
                        onTap: () => controller.toggleCardExpansion(orderId),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AppAssets.testTube,
                              width: 16,
                              height: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tests.length > 1
                                    ? '${tests.length} Tests'
                                    : firstTest.testName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (tests.length > 1)
                              Icon(
                                expanded ? Icons.expand_less : Icons.expand_more,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                      // Expanded test list
                      if (expanded && tests.length > 1) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: tests.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final test = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: idx < tests.length - 1 ? 8 : 0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${idx + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        test.testName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  );
                }),


              ],
            ),
          ),
        ),
        Positioned(
          left: 4,
          top: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
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
              child: Text(
                srNo.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }*/

  Widget _buildGroupedDeniedCard(
      BuildContext context, String orderId, List<RecollectionTestListUpdated> tests, int srNo) {
    final theme = Theme.of(context);
    final firstTest = tests.first;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12, top: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Info Row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppAssets.patient,
                            width: 16,
                            height: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              firstTest.patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Denied',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Order ID and Gender
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppAssets.barcodeIcon,
                            width: 16,
                            height: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              orderId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        firstTest.gender,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tests - Collapsible
                Obx(() {
                  final expanded = controller.expandedCards.contains(orderId);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clickable header row
                      GestureDetector(
                        onTap: () => controller.toggleCardExpansion(orderId),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AppAssets.testTube,
                              width: 16,
                              height: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tests.length > 1
                                    ? '${tests.length} Tests'
                                    : firstTest.testName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (tests.length > 1)
                              Icon(
                                expanded ? Icons.expand_less : Icons.expand_more,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                      // Expanded test list
                      if (expanded && tests.length > 1) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: tests.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final test = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: idx < tests.length - 1 ? 8 : 0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${idx + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        test.testName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  );
                }),

                const SizedBox(height: 8),

                // Denial Reason
                if (firstTest.reasonOfRejection.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Denial Reason: ${firstTest.reasonOfRejection}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 4,
          top: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
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
              child: Text(
                srNo.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildTestsList(
      List<RecollectionTestListUpdated> tests, ThemeData theme) {
    if (tests.length == 1) {
      return Row(
        children: [
          SvgPicture.asset(
            AppAssets.testTube,
            width: 16,
            height: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tests.first.testName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              AppAssets.testTube,
              width: 16,
              height: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '${tests.length} Tests:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...tests.asMap().entries.map((entry) {
          final idx = entry.key;
          final test = entry.value;
          return Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text(
              '${idx + 1}. ${test.testName}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          );
        }),
      ],
    );
  }

/*  Widget _buildPendingList(BuildContext context) {
    if (controller.filteredPendingList.isEmpty &&
        controller.recollectionPendingList.isNotEmpty) {
      return _buildEmptyState('No reports found matching your search');
    }

    if (controller.recollectionPendingList.isEmpty) {
      return _buildEmptyState('No Pending Tests for Recollection');
    }

    return Scrollbar(
      radius: const Radius.circular(16),
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.filteredPendingList.length,
        itemBuilder: (context, index) {
          final test = controller.filteredPendingList[index];
          return _buildPendingCard(context, test, index + 1);
        },
      ),
    );
  }

  Widget _buildAcceptedList(BuildContext context) {
    if (controller.filteredAcceptedList.isEmpty &&
        controller.recollectionAcceptedList.isNotEmpty) {
      return _buildEmptyState('No reports found matching your search');
    }

    if (controller.recollectionAcceptedList.isEmpty) {
      return _buildEmptyState('No Accepted Tests');
    }

    return Scrollbar(
      radius: const Radius.circular(16),
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.filteredAcceptedList.length,
        itemBuilder: (context, index) {
          final test = controller.filteredAcceptedList[index];
          return _buildAcceptedCard(context, test, index + 1);
        },
      ),
    );
  }

  Widget _buildDeniedList(BuildContext context) {
    if (controller.filteredDeniedList.isEmpty &&
        controller.recollectionDeniedList.isNotEmpty) {
      return _buildEmptyState('No reports found matching your search');
    }

    if (controller.recollectionDeniedList.isEmpty) {
      return _buildEmptyState('No Denied Tests');
    }

    return Scrollbar(
      radius: const Radius.circular(16),
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.filteredDeniedList.length,
        itemBuilder: (context, index) {
          final test = controller.filteredDeniedList[index];
          return _buildDeniedCard(context, test, index + 1);
        },
      ),
    );
  }*/

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(
      BuildContext context, RecollectionTestListUpdated test, int srNo) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            // Navigate to recollection test selection
            if (Get.isRegistered<RecollectTestsController>()) {
              Get.delete<RecollectTestsController>();
            }
            // Convert to SampleRecollectionList format if needed for navigation
            Get.to(() => RecollectionTestSelectionView(),
                arguments: test,
                transition: Transition.rightToLeft,
                duration: const Duration(milliseconds: 250));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, top: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            /*decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),*/
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Info Row
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AppAssets.patient,
                              width: 16,
                              height: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                test.patientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Order ID and Gender
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AppAssets.barcodeIcon,
                              width: 16,
                              height: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                test.orderId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          test.gender,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Test Name i want list of tests with same barcode
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppAssets.testTube,
                        width: 16,
                        height: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          test.testName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 4,
          top: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
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
              child: Text(
                srNo.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptedCard(
      BuildContext context, RecollectionTestListUpdated test, int srNo) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12, top: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Info Row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppAssets.patient,
                            width: 16,
                            height: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              test.patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Recollected',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Order IDs Row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppAssets.barcodeIcon,
                            width: 16,
                            height: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              test.orderId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        test.gender,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // New Barcode
                if (test.recollectedBarcode != null)
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppAssets.barcodeIcon,
                        width: 16,
                        height: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'New: ${test.recollectedBarcode}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),

                // Test Name
                Row(
                  children: [
                    SvgPicture.asset(
                      AppAssets.testTube,
                      width: 16,
                      height: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        test.testName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Recollected Date
                if (test.recollectedDate != null)
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppAssets.calendarIcon,
                        width: 16,
                        height: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recollection Date: ${test.recollectedDate}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 4,
          top: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
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
              child: Text(
                srNo.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildCollapsedSearchSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              FocusScope.of(context).unfocus();
              controller.toggleSearchExpansion();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Obx(() => AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: controller.isSearchExpanded.value
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: _buildCollapsedContent(context),
                    secondChild: _buildExpandedContent(context),
                  )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            AppAssets.fileNoteIcon,
            color: Theme.of(context).primaryColor,
            height: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.selectedFacilityName.value?.facilityName ??
                    AppStrings.selectFacility,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _getDateRangeText(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${controller.getTotalCount()} tests',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedRotation(
          turns: controller.isSearchExpanded.value ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.expand_more,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Column(
      children: [
        // Header with close button
        Row(
          children: [
            Text(
              AppStrings.search,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => controller.toggleSearchExpansion(),
              icon: const Icon(Icons.close),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Facility name dropdown
        Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernDropdown(
                  label: AppStrings.facilityName,
                  value:
                      controller.selectedFacilityName.value?.facilityName ?? '',
                  items: controller.facilityNames
                      .map((e) => e.facilityName)
                      .toList(),
                  onChanged: (value) {
                    if (value != null && value.isNotEmpty) {
                      final selectedFacility =
                          controller.facilityNames.firstWhere(
                        (facility) => facility.facilityName == value,
                      );
                      controller.selectedFacilityName.value = selectedFacility;
                      debugPrint(
                        'Selected Facility: ${selectedFacility.facilityName}, code: ${selectedFacility.facilityId}',
                      );
                    }
                  },
                  iconPath: AppAssets.facility,
                  isRequired: true,
                ),
                if (controller.selectedFacilityName.value == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Text(
                      AppStrings.facilityNameError,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            )),
        const SizedBox(height: 16),
        // Date Pickers Row
        Row(
          children: [
            Expanded(
              child: Obx(() => CFormDateField(
                    label: 'From Date',
                    value: controller.fromDate.value != null
                        ? '${controller.fromDate.value!.day}/${controller.fromDate.value!.month}/${controller.fromDate.value!.year}'
                        : '',
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: Get.context!,
                        initialDate:
                            controller.fromDate.value ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                      );
                      if (picked != null) {
                        controller.fromDate.value = picked;
                        if (controller.toDate.value != null &&
                            (controller.toDate.value!.isBefore(picked) ||
                                controller.toDate.value!
                                        .difference(picked)
                                        .inDays >
                                    30)) {
                          controller.toDate.value =
                              picked.add(const Duration(days: 30));
                        }
                        if (controller.toDate.value == null) {
                          final defaultToDate =
                              picked.add(const Duration(days: 30));
                          controller.toDate.value =
                              defaultToDate.isAfter(DateTime.now())
                                  ? DateTime.now()
                                  : defaultToDate;
                        }
                      }
                    },
                    iconPath: AppAssets.calendarIcon,
                    isRequired: true,
                  )),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Obx(() => CFormDateField(
                    label: 'To Date',
                    value: controller.toDate.value != null
                        ? '${controller.toDate.value!.day}/${controller.toDate.value!.month}/${controller.toDate.value!.year}'
                        : '',
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: Get.context!,
                        initialDate: controller.toDate.value ??
                            (controller.fromDate.value != null
                                ? controller.fromDate.value!
                                    .add(const Duration(days: 30))
                                : DateTime.now()),
                        firstDate: controller.fromDate.value ?? DateTime(2000),
                        lastDate: controller.fromDate.value != null
                            ? (controller.fromDate.value!
                                    .add(const Duration(days: 30))
                                    .isAfter(DateTime.now())
                                ? DateTime.now()
                                : controller.fromDate.value!
                                    .add(const Duration(days: 30)))
                            : DateTime.now(),
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                      );
                      if (picked != null) {
                        controller.toDate.value = picked;
                      }
                    },
                    iconPath: AppAssets.calendarIcon,
                    isRequired: true,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Action buttons
        Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  controller.clearFilters();
                  controller.toggleSearchExpansion();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[400]!),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(AppStrings.clear),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.selectedFacilityName.value == null ||
                      controller
                          .selectedFacilityName.value!.facilityName.isEmpty) {
                    controller.facilityInfoError.value =
                        'Please select a facility';
                    return;
                  }
                  controller.fetchAllRecollectionLists();
                  controller.toggleSearchExpansion();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(AppStrings.applyFilter),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getDateRangeText() {
    final from = controller.fromDate.value;
    final to = controller.toDate.value;

    if (from != null && to != null) {
      return '${DateFormat('dd/MM').format(from)} - ${DateFormat('dd/MM').format(to)}';
    } else if (from != null) {
      return 'From ${DateFormat('dd/MM/yy').format(from)}';
    } else if (to != null) {
      return 'Until ${DateFormat('dd/MM/yy').format(to)}';
    }
    return 'Select date range';
  }
}
