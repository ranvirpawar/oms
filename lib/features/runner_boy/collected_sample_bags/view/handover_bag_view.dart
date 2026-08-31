import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/theme/app_colors.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import '../../../../componenents/animations/success_animation_widget.dart';
import '../controller/collected_bags_controller.dart';

class HandoverView extends StatelessWidget {
  const HandoverView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectedBagsController>();
    return _HandoverViewBody(controller: controller);
  }
}

class _HandoverViewBody extends StatefulWidget {
  final CollectedBagsController controller;

  const _HandoverViewBody({required this.controller});

  @override
  State<_HandoverViewBody> createState() => _HandoverViewBodyState();
}

class _HandoverViewBodyState extends State<_HandoverViewBody> {
  CollectedBagsController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.initHandoverPage();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.resetHandoverPage();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ── Success / Completed state ──────────────────────────────────────
      if (c.submissionState.value == SubmissionState.success) {
        return _buildSuccessScreen();
      }

      // ── Normal state ───────────────────────────────────────────────────
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        appBar: const CustomAppBar(title: 'Handover Bag(s)'),
        body: Column(
          children: [
            _buildTypeSelector(),
            Expanded(
              child: PageView(
                controller: c.handoverPageController,
                onPageChanged: c.updateHandoverIndex,
                children: [
                  _buildHandoverContent('Connector'),
                  _buildHandoverContent('Runner Boy'),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildConfirmButton(),
      );
    });
  }

  // ── Success Screen ───────────────────────────────────────────────────────

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              const SuccessAnimationWidget(),

              const SizedBox(height: 36),

              Text(
                'Handover Complete!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 12),

              Obx(() => Text(
                    '${c.submissionProgress.value} bag(s) successfully handed over to '
                    "${c.selectedConnector.value?.userName ?? 'recipient'}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  )),

              // Partial errors if any
              Obx(() {
                if (c.submissionErrors.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${c.submissionErrors.length} bag(s) failed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...c.submissionErrors.map((e) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('• $e',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700)),
                          )),
                    ],
                  ),
                );
              }),

              const Spacer(),

              // Go Back button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    c.fetchBags();
                    c.clearSelection();
                    c.clearSearch();

                    Get.back();
                  },
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  label: const Text(
                    'Go Back',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Done button — pops and refreshes
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () {
                    c.fetchBags();
                    c.clearSelection();
                    c.clearSearch();

                    Get.back();
                  },
                  icon: const Icon(Icons.check_circle_outline,
                      color: AppColors.primary),
                  label: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Type Selector ────────────────────────────────────────────────────────

  Widget _buildTypeSelector() {
    return Obx(() => Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _typeTab('Connector', 0),
              _typeTab('Runner Boy', 1),
            ],
          ),
        ));
  }

  Widget _typeTab(String label, int index) {
    final isSelected = c.currentHandoverTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => c.switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.surface : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Page Content ─────────────────────────────────────────────────────────

  Widget _buildHandoverContent(String typeLabel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 30),
          Text('Select $typeLabel',
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDropdownTrigger(),
          const SizedBox(height: 20),
          _buildDetailsCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primary900, AppColors.primary600]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.inventory_2, color: Colors.white)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => Text(
                    '${c.selectedSessionIds.length} Bags Selected',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  )),
              const Text('Ready for transfer',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Dropdown with loading state ──────────────────────────────────────────

  Widget _buildDropdownTrigger() {
    return Obx(() {
      final isLoading = c.isCurrentTabLoading;

      if (isLoading) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
              SizedBox(width: 12),
              Text('Loading...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }

      return InkWell(
        onTap: () => _showSearchableBottomSheet(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_search, color: AppColors.primary800),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  c.selectedConnector.value?.userName ?? 'Select from list...',
                  style: TextStyle(
                    color: c.selectedConnector.value == null
                        ? Colors.grey
                        : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      );
    });
  }

  void _showSearchableBottomSheet() {
    c.searchQuery.value = '';
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                onChanged: (v) => c.searchQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'Search name or employee code...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final list = c.filteredConnectors;

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No results found',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemBuilder: (context, index) {
                    final person = list[index];
                    return ListTile(
                      leading: CircleAvatar(
                          backgroundColor: AppColors.primary50,
                          child: Text(person.userName[0])),
                      title: Text(person.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          Text('ID: ${person.userId} • ${person.facilityName}'),
                      onTap: () {
                        c.selectConnector(person);
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Obx(() {
      final person = c.selectedConnector.value;
      if (person == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            _row(Icons.location_on_outlined, 'Facility', person.facilityName),
            const Divider(height: 30),
            _row(Icons.layers_outlined, 'Ward', person.ward),
            const Divider(height: 30),
            _row(Icons.badge_outlined, 'Type', person.fType),
          ],
        ),
      );
    });
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── Confirm Button with submission states ────────────────────────────────

  Widget _buildConfirmButton() {
    return Obx(() {
      final state = c.submissionState.value;
      final isProcessing = state == SubmissionState.processing;
      final canSubmit = c.selectedConnector.value != null && !isProcessing;

      String label = 'Complete Handover';
      if (isProcessing) {
        final progress = c.submissionProgress.value;
        final total = c.submissionTotal.value;
        label =
            total > 0 ? 'Submitting $progress / $total...' : 'Submitting...';
      }

      return Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: SafeArea(
          child: ElevatedButton(
            onPressed: canSubmit
                ? () => c.handoverToConnector(c.selectedConnector.value!.userId)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canSubmit ? AppColors.primary900 : Colors.grey.shade300,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: isProcessing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 12),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.white)),
                    ],
                  )
                : Text(label,
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      );
    });
  }
}

/*class HandoverView extends StatelessWidget {
  const HandoverView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectedBagsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: CustomAppBar(
        title: "Handover Bag(s)"

      ),
      body: Column(
        children: [
          _buildTypeSelector(controller),
          Expanded(
            child: PageView(
              controller: controller.handoverPageController,
              onPageChanged: (index) => controller.updateHandoverIndex(index),
              children: [
                _buildHandoverContent(controller, "Connector"),
                _buildHandoverContent(controller, "Runner Boy"),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildConfirmButton(controller),
    );
  }

  Widget _buildTypeSelector(CollectedBagsController controller) {
    return Obx(() => Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _typeTab(controller, "Connector", 0),
          _typeTab(controller, "Runner Boy", 1),
        ],
      ),
    ));
  }

  Widget _typeTab(CollectedBagsController controller, String label, int index) {
    bool isSelected = controller.currentHandoverTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.surface : Colors.grey,
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildHandoverContent(CollectedBagsController controller, String typeLabel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(controller),
          const SizedBox(height: 30),
          Text("Select $typeLabel", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDropdownTrigger(controller),
          const SizedBox(height: 20),
          _buildDetailsCard(controller),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CollectedBagsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary900, AppColors.primary600]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.inventory_2, color: Colors.white)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => Text("${controller.selectedSessionIds.length} Bags Selected",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              const Text("Ready for transfer", style: TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTrigger(CollectedBagsController controller) {
    return Obx(() => InkWell(
      onTap: () => _showSearchableBottomSheet(controller),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.person_search, color: AppColors.primary800),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.selectedConnector.value?.userName ?? "Select from list...",
                style: TextStyle(
                    color: controller.selectedConnector.value == null ? Colors.grey : Colors.black87,
                    fontSize: 15
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    ));
  }

  void _showSearchableBottomSheet(CollectedBagsController controller) {
    controller.searchQuery.value = ''; // Reset search
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                onChanged: (v) => controller.searchQuery.value = v,
                decoration: InputDecoration(
                  hintText: "Search name or employee code...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: controller.filteredConnectors.length,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemBuilder: (context, index) {
                  final person = controller.filteredConnectors[index];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: AppColors.primary50, child: Text(person.userName[0])),
                    title: Text(person.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("ID: ${person.userId} • ${person.facilityName}"),
                    onTap: () {
                      controller.selectConnector(person);
                      Get.back();
                    },
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(CollectedBagsController controller) {
    return Obx(() {
      final c = controller.selectedConnector.value;
      if (c == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            _row(Icons.location_on_outlined, "Facility", c.facilityName),
            const Divider(height: 30),
            _row(Icons.layers_outlined, "Ward", c.ward),
            const Divider(height: 30),
            _row(Icons.badge_outlined, "Type", c.fType),
          ],
        ),
      );
    });
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildConfirmButton(CollectedBagsController controller) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: SafeArea(
        child: ElevatedButton(
          onPressed: controller.selectedConnector.value == null
              ? null
              : () => controller.handoverToConnector(controller.selectedConnector.value!.userId),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary900,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("Complete Handover", style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    ));
  }
}*/
