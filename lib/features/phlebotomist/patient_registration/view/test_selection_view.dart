// Test Selection View Widget

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/constants/app_strings.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/view/sample_collection_form.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import '../../../../theme/app_colors.dart';
import '../models/tests_model.dart';
import '../controller/test_selection_controller.dart';

class TestSelectionView extends StatelessWidget {
  final String bagId;
  final TestSelectionController controller = Get.put(TestSelectionController());

  TestSelectionView({super.key, required this.bagId, });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: AppStrings.selectTest,
        actions: [
          Obx(() => controller.selectedTests.isNotEmpty
              ? TextButton(
            onPressed: controller.clearAllSelections,
            style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimaryDark),
            child: const Text(
              AppStrings.clearAll,
              style:
              TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          )
              : const SizedBox()),
          const SizedBox(width: 8),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // ── HMIS banner (scrolls away) ─────────────────────────────────
            SliverToBoxAdapter(
              child: Obx(() => controller.isHMISPatient.value
                  ? _buildHMISBanner(context)
                  : const SizedBox.shrink()),
            ),

            // ── Search bar (scrolls away) ──────────────────────────────────
            SliverToBoxAdapter(child: _buildSearchBar(context)),

            // ── Tab bar — pinned ───────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.grey[50],
              toolbarHeight: 48, // 40 tab pill + 4*2 padding
              flexibleSpace: FlexibleSpaceBar(
                background: _buildModernTabBar(context),
                collapseMode: CollapseMode.none,
              ),
            ),

            // ── Selected-tests panel — pinned below tab bar ────────────────
            // We use SliverAppBar so Flutter handles the geometry contract.
            // toolbarHeight is driven by the observable state, giving us
            // a panel that is 0 px tall when empty and up to 180 px when
            // expanded — all without touching SliverPersistentHeader.
            Obx(() {
              final isEmpty = controller.selectedTests.isEmpty;
              final isExpanded = controller.showSelectedTests.value;

              // Compute the exact height the panel needs right now.
              // collapsed header = 44, chips area = 120, bottom padding = 6
              final double panelHeight = isEmpty
                  ? 0
                  : isExpanded
                  ? 180  // header(44) + chips(120) + padding(6)
                  : 54;  // header only

              return SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.transparent,
                toolbarHeight: panelHeight,
                flexibleSpace: panelHeight == 0
                    ? const SizedBox.shrink()
                    : FlexibleSpaceBar(
                  background: buildSelectedTestsWidget(context),
                  collapseMode: CollapseMode.none,
                ),
              );
            }),
          ],

          // ── Tab content ────────────────────────────────────────────────────
          body: TabBarView(
            children: [
              _buildTestCategoryView(controller.basicCategorized),
              _buildTestCategoryView(controller.advanceCategorized),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildModernFloatingButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildHMISBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withOpacity(0.08),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: Theme.of(context).primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'HMIS pre-assigned tests are auto-selected  •  You can add or remove any test.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        focusNode: controller.searchFocusNode,
        onChanged: controller.searchTests,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search tests...',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
          prefixIcon:
          Icon(Icons.search_rounded, color: Colors.grey[500], size: 16),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear_rounded,
                color: Colors.grey[500], size: 18),
            onPressed: controller.clearSearch,
          )
              : const SizedBox.shrink()),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildModernTabBar(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: TabBar(
          indicator: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(2),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[600],
          labelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'Basic'), Tab(text: 'Advanced')],
        ),
      ),
    );
  }

  Widget _buildTestCategoryView(
      RxMap<String, List<TestModel>> categorizedTests) {
    return Obx(() {
      if (controller.isLoadingTests.value) {
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(Get.context!).primaryColor,
            strokeWidth: 2,
          ),
        );
      }

      if (categorizedTests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.science_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No tests available',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: categorizedTests.keys.length,
        itemBuilder: (context, index) {
          final labCategory = categorizedTests.keys.elementAt(index);
          final tests = categorizedTests[labCategory]!;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Obx(() {
              final isExpanded =
              controller.isLabCategoryExpanded(labCategory);
              return Column(
                children: [
                  InkWell(
                    onTap: () =>
                        controller.toggleLabCategoryExpansion(labCategory),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  labCategory,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${tests.length} test${tests.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Obx(() {
                            final selectedCount = tests
                                .where((t) => controller.isTestSelected(t))
                                .length;
                            return selectedCount > 0
                                ? Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('$selectedCount',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            )
                                : const SizedBox.shrink();
                          }),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey[600],
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    Container(height: 1, color: Colors.grey[100]),
                    ...tests.map((t) => _buildCompactTestTile(t, context)),
                  ],
                ],
              );
            }),
          );
        },
      );
    });
  }

  Widget _buildCompactTestTile(TestModel test, BuildContext context) {
    return Obx(() {
      final isSelected = controller.isTestSelected(test);
      final isPreAssigned = controller.isHMISPreAssigned(test);

      return InkWell(
        onTap: () => controller.toggleTestSelection(test),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[400]!,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  test.testName ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.black87,
                  ),
                ),
              ),
              if (controller.isHMISPatient.value && isPreAssigned)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border:
                    Border.all(color: Colors.amber.shade300, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 10, color: Colors.amber.shade700),
                      const SizedBox(width: 2),
                      Text(
                        'HMIS',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildSelectedTestsWidget(BuildContext context) {
    // NOTE: Obx is intentionally NOT here — the parent SliverAppBar's Obx
    // already rebuilds the whole sliver when state changes. Adding a second
    // Obx wrapper here causes double-rebuild and can re-trigger the geometry
    // assertion. Reading observables directly is safe inside an Obx ancestor.
    if (controller.selectedTests.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            GestureDetector(
              onTap: controller.toggleSelectedTestsVisibility,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                  borderRadius: !controller.showSelectedTests.value
                      ? const BorderRadius.all(Radius.circular(12))
                      : const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      '${controller.selectedTests.length} test${controller.selectedTests.length > 1 ? 's' : ''} selected',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Theme.of(context).primaryColor),
                    ),
                    const Spacer(),
                    controller.showSelectedTests.value
                        ? Icon(Icons.keyboard_arrow_up_rounded,
                        color: Theme.of(context).primaryColor, size: 20)
                        : Text(
                      'View',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
              ),
            ),

            // Chips (only when expanded)
            if (controller.showSelectedTests.value)
              SizedBox(
                height: 120,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: controller.selectedTests.map((test) {
                        final isPreAssigned =
                        controller.isHMISPreAssigned(test);
                        return GestureDetector(
                          onTap: () => controller.toggleTestSelection(test),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (controller.isHMISPatient.value &&
                                    isPreAssigned) ...[
                                  Icon(Icons.star_rounded,
                                      size: 11,
                                      color: Colors.amber.shade600),
                                  const SizedBox(width: 3),
                                ],
                                Flexible(
                                  child: Text(
                                    test.testName ?? '',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color:
                                        Theme.of(context).primaryColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.close_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 14),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFloatingButton(BuildContext context) {
    return Obx(() => controller.selectedTests.isNotEmpty
        ? Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          controller.searchFocusNode.unfocus();
          // Extract voucher from the first HMIS test
          // Read directly from controller — populated during HMIS fetch
          final hmisVoucher = controller.hmisVoucherNumber.value;
          print('hmisVoucher before nav: $hmisVoucher');

          print('hmisVoucher in test selection view before nav to testbarcode view: $hmisVoucher');
          Get.to(() => TestBarcodeView(
            selectedTests: controller.getSelectedTestsForAPI(),
            patientArray: controller.patientArray.value,
            requisitionDno: controller.requisitionDno.value,
            bagId: bagId,
            hmisVoucherNumber: hmisVoucher, // ← new

          ))?.then((result) {
            if (result != null) {
              final data = result as Map;
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue with ${controller.selectedTests.length} test${controller.selectedTests.length > 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    )
        : const SizedBox.shrink());
  }
}
/*class TestSelectionView extends StatelessWidget {
  final TestSelectionController controller = Get.put(TestSelectionController());
  TestSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        // AppBar title is the same regardless of HMIS; no read-only hint needed
        title: AppStrings.selectTest,
        actions: [
          Obx(() => controller.selectedTests.isNotEmpty
              ? TextButton(
            onPressed: () => controller.clearAllSelections(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimaryDark,
            ),
            child: const Text(
              AppStrings.clearAll,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
              : const SizedBox()),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Optional HMIS banner (subtle, non-blocking)
          Obx(() => controller.isHMISPatient.value
              ? _buildHMISBanner(context)
              : const SizedBox()),

          _buildSearchBar(context),

          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  _buildModernTabBar(context),
                  buildSelectedTestsWidget(context),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTestCategoryView(
                            controller.basicCategorized, 'BASIC TESTS'),
                        _buildTestCategoryView(
                            controller.advanceCategorized, 'ADVANCE TESTS'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildModernFloatingButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Subtle top banner informing the user that HMIS tests are pre-selected.
  Widget _buildHMISBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withOpacity(0.08),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: Theme.of(context).primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'HMIS pre-assigned tests are auto-selected  •  You can add or remove any test.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        focusNode: controller.searchFocusNode,
        onChanged: (value) => controller.searchTests(value),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search tests...',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
          prefixIcon:
          Icon(Icons.search_rounded, color: Colors.grey[500], size: 16),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear_rounded,
                color: Colors.grey[500], size: 18),
            onPressed: () => controller.clearSearch(),
          )
              : const SizedBox()),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildModernTabBar(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(2),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Basic'),
          Tab(text: 'Advanced'),
        ],
      ),
    );
  }

  Widget _buildTestCategoryView(
      RxMap<String, List<TestModel>> categorizedTests, String categoryTitle) {
    return Obx(() {
      if (controller.isLoadingTests.value) {
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(Get.context!).primaryColor,
            strokeWidth: 2,
          ),
        );
      }

      if (categorizedTests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.science_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No tests available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: categorizedTests.keys.length,
        itemBuilder: (context, index) {
          final labCategory = categorizedTests.keys.elementAt(index);
          final tests = categorizedTests[labCategory]!;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Obx(() {
              final isExpanded =
              controller.isLabCategoryExpanded(labCategory);
              return Column(
                children: [
                  InkWell(
                    onTap: () =>
                        controller.toggleLabCategoryExpansion(labCategory),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  labCategory,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${tests.length} test${tests.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Selected count badge
                          Obx(() {
                            final selectedCount = tests
                                .where((test) =>
                                controller.isTestSelected(test))
                                .length;
                            return selectedCount > 0
                                ? Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                Theme.of(context).primaryColor,
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$selectedCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                                : const SizedBox();
                          }),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey[600],
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    Container(height: 1, color: Colors.grey[100]),
                    ...tests.map(
                            (test) => _buildCompactTestTile(test, context)),
                  ],
                ],
              );
            }),
          );
        },
      );
    });
  }

  Widget _buildCompactTestTile(TestModel test, BuildContext context) {
    return Obx(() {
      final isSelected = controller.isTestSelected(test);
      // For HMIS patients, show which tests were pre-assigned
      final isPreAssigned = controller.isHMISPreAssigned(test);

      return InkWell(
        onTap: () => controller.toggleTestSelection(test),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // Checkbox circle (always interactive now)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[400]!,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 12),

              // Test name
              Expanded(
                child: Text(
                  test.testName ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.black87,
                  ),
                ),
              ),

              // HMIS pre-assigned badge (star icon) — only for HMIS patients
              if (controller.isHMISPatient.value && isPreAssigned)
                Tooltip(
                  message: 'Pre-assigned by HMIS',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border:
                      Border.all(color: Colors.amber.shade300, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 10, color: Colors.amber.shade700),
                        const SizedBox(width: 2),
                        Text(
                          'HMIS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildSelectedTestsWidget(BuildContext context) {
    return Obx(() {
      if (controller.selectedTests.isEmpty) return const SizedBox();

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  width: 1,
                ),
                borderRadius: !controller.showSelectedTests.value
                    ? const BorderRadius.all(Radius.circular(12))
                    : const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: GestureDetector(
                onTap: () => controller.toggleSelectedTestsVisibility(),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${controller.selectedTests.length} test${controller.selectedTests.length > 1 ? 's' : ''} selected',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Spacer(),
                    controller.showSelectedTests.value
                        ? Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    )
                        : Text(
                      'View',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded chips
            if (controller.showSelectedTests.value)
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: controller.selectedTests.map((test) {
                        final isPreAssigned =
                        controller.isHMISPreAssigned(test);
                        return GestureDetector(
                          onTap: () => controller.toggleTestSelection(test),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Star for HMIS pre-assigned
                                if (controller.isHMISPatient.value &&
                                    isPreAssigned) ...[
                                  Icon(Icons.star_rounded,
                                      size: 11,
                                      color: Colors.amber.shade600),
                                  const SizedBox(width: 3),
                                ],
                                Flexible(
                                  child: Text(
                                    test.testName ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color:
                                      Theme.of(context).primaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.close_rounded,
                                  color: Theme.of(context).primaryColor,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildModernFloatingButton(BuildContext context) {
    return Obx(() => controller.selectedTests.isNotEmpty
        ? Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final selectedTestsData = controller.getSelectedTestsForAPI();
          final patientArray = controller.patientArray.value;
          controller.searchFocusNode.unfocus();
          Get.to(() => TestBarcodeView(
            selectedTests: selectedTestsData,
            patientArray: patientArray,
            requisitionDno: controller.requisitionDno.value,
          ))?.then((result) {
            if (result != null) {
              final data = result as Map;
              // Handle the processed data
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue with ${controller.selectedTests.length} test${controller.selectedTests.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    )
        : const SizedBox());
  }
}*/


