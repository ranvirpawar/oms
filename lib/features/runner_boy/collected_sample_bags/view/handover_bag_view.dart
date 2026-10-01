import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final TextEditingController _searchCtrl = TextEditingController();

  static const _bg = Color(0xFFF8F9FD);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.initHandoverPage();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.resetHandoverPage();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.submissionState.value == SubmissionState.success) {
        return _buildSuccessScreen();
      }

      return Scaffold(
        backgroundColor: _bg,
        appBar: const CustomAppBar(title: 'Handover Bag(s)'),
        body: _buildBody(),
        bottomNavigationBar: _buildConfirmButton(),
      );
    });
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              _buildSummaryBanner(),
              const SizedBox(height: 12),
              _buildSearchField(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildListArea()),
      ],
    );
  }

  Widget _buildSummaryBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary900, AppColors.primary600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
                  () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${c.selectedSessionIds.length} bag(s) selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Choose who receives them',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) {
        c.searchQuery.value = v;
        setState(() {}); // refresh clear icon
      },
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search name, ID or clinic',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
          icon: const Icon(Icons.close_rounded, size: 18),
          onPressed: () {
            _searchCtrl.clear();
            c.searchQuery.value = '';
            setState(() {});
          },
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }

  /// Switches between loading / error / empty / no-results / list.
  Widget _buildListArea() {
    return Obx(() {
      final loading = c.isFetchingRunnerBoys.value || !c.hasLoadedRunnerBoys.value;
      final error = c.runnerBoyError.value;
      final all = c.runnerBoyList;
      final list = c.filteredConnectors;

      Widget child;
      if (loading) {
        child = _buildLoading();
      } else if (error != null) {
        child = _buildMessageState(
          key: const ValueKey('error'),
          icon: Icons.cloud_off_rounded,
          title: 'Couldn\'t load the list',
          message: error,
          actionLabel: 'Try again',
          onAction: c.fetchRunnerBoys,
        );
      } else if (all.isEmpty) {
        child = _buildMessageState(
          key: const ValueKey('empty'),
          icon: Icons.people_outline_rounded,
          title: 'No runner boys available',
          message: 'There is nobody to hand over to right now.',
          actionLabel: 'Refresh',
          onAction: c.fetchRunnerBoys,
        );
      } else if (list.isEmpty) {
        child = _buildMessageState(
          key: const ValueKey('no-results'),
          icon: Icons.search_off_rounded,
          title: 'No matches',
          message: 'Try a different name, ID or clinic.',
        );
      } else {
        child = _buildRunnerList(list);
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        child: child,
      );
    });
  }

  Widget _buildRunnerList(List<dynamic> list) {
    return RefreshIndicator(
      key: const ValueKey('list'),
      color: AppColors.primary,
      onRefresh: c.fetchRunnerBoys,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final person = list[index];
          return Obx(() {
            final selected =
                c.selectedConnector.value?.userId == person.userId;
            return _RunnerTile(
              name: person.userName,
              clinic: person.facilityName,
              selected: selected,
              onTap: () {
                HapticFeedback.selectionClick();
                FocusScope.of(context).unfocus();
                c.selectConnector(person);
              },
            );
          });
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      key: const ValueKey('loading'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const _SkeletonTile(),
    );
  }

  Widget _buildMessageState({
    required Key key,
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: AppColors.primary800),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(140, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Confirm button ───────────────────────────────────────────────────────

  Widget _buildConfirmButton() {
    return Obx(() {
      final state = c.submissionState.value;
      final isProcessing = state == SubmissionState.processing;
      final selected = c.selectedConnector.value;
      final canSubmit = selected != null && !isProcessing;

      String label = selected == null
          ? 'Select a runner boy'
          : 'Handover to ${selected.userName}';
      if (isProcessing) {
        final progress = c.submissionProgress.value;
        final total = c.submissionTotal.value;
        label = total > 0 ? 'Submitting $progress / $total...' : 'Submitting...';
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SafeArea(
          top: false,
          child: ElevatedButton(
            onPressed: canSubmit
                ? () {
              HapticFeedback.mediumImpact();
              c.handoverToConnector(selected.userId);
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary900,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isProcessing
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(width: 12),
                Text(label,
                    style: const TextStyle(
                        fontSize: 15, color: Colors.white)),
              ],
            )
                : Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: canSubmit ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── Success screen ───────────────────────────────────────────────────────

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: _bg,
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
              Obx(
                    () => Text(
                  '${c.submissionProgress.value} bag(s) processed for '
                      "${c.selectedConnector.value?.userName ?? 'recipient'}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ),
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
                      ...c.submissionErrors.map(
                            (e) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '• $e',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Spacer(),
              // "Go Back" and "Done" did the exact same thing — one is enough.
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    c.fetchBags();
                    c.clearSelection();
                    c.clearSearch();
                    Get.back();
                  },
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  label: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary900,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Runner tile
// ═════════════════════════════════════════════════════════════════════════════

class _RunnerTile extends StatelessWidget {
  final String name;
  final String clinic;
  final bool selected;
  final VoidCallback onTap;

  const _RunnerTile({
    required this.name,
    required this.clinic,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Semantics(
      button: true,
      selected: selected,
      label: '$name, $clinic',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.primary
                          : AppColors.primary50,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.primary800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                clinic,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: selected
                        ? const Icon(Icons.check_circle_rounded,
                        key: ValueKey('on'),
                        color: AppColors.primary,
                        size: 24)
                        : Icon(Icons.radio_button_unchecked_rounded,
                        key: const ValueKey('off'),
                        color: Colors.grey.shade400,
                        size: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Skeleton loading tile (pulsing, no extra packages)
// ═════════════════════════════════════════════════════════════════════════════

class _SkeletonTile extends StatefulWidget {
  const _SkeletonTile();

  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _bar(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(6),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(130, 12),
                const SizedBox(height: 8),
                _bar(90, 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
