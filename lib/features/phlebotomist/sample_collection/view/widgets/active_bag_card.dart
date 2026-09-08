// active_bag_card.dart
//
// Modern, interactive card shown at the top of the sample collection screen.
// It surfaces the currently-open bag the phlebotomist is collecting into,
// its live capacity, and quick actions to switch/reopen bags (the
// one-open-at-a-time rule lives in BagRegistrationController) or scan a
// brand-new bag.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/routes/route_manager.dart';

import '../../../../../theme/app_colors.dart';
import '../../../patient_registration/bag_status_dashboard/controller/registrarion_bag_controller.dart';
import '../../../patient_registration/bag_status_dashboard/model/qr_bag_session.dart';
import '../../../patient_registration/bag_status_dashboard/view/scan_bag_page.dart';
import '../../controller/sample_collection_controller.dart';
// active_bag_card.dart
//
// Modern, interactive card shown at the top of the sample collection screen.
// It surfaces the currently-open bag the phlebotomist is collecting into,
// its live capacity, and quick actions to switch/reopen bags (the
// one-open-at-a-time rule lives in BagRegistrationController) or scan a
// brand-new bag.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/routes/route_manager.dart';

import '../../../../../theme/app_colors.dart';
import '../../../patient_registration/bag_status_dashboard/controller/registrarion_bag_controller.dart';
import '../../../patient_registration/bag_status_dashboard/model/qr_bag_session.dart';
import '../../../patient_registration/bag_status_dashboard/view/scan_bag_page.dart';
import '../../controller/sample_collection_controller.dart';

/// Card that renders the open-bag state (capacity, status, bag-switch
/// actions) on the sample collection screen. Rebuilds reactively whenever
/// the shared [BagRegistrationController] state changes.
class ActiveBagCard extends StatelessWidget {
  const ActiveBagCard({super.key, required this.controller});

  final SampleCollectionController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // First session fetch still in flight — show a slim placeholder.
      if (controller.bagController.isLoading.value &&
          !controller.bagController.hasBags) {
        return const _BagLoadingCard();
      }

      if (!controller.hasOpenBag) {
        return _NoOpenBagCard(controller: controller);
      }

      return _OpenBagCard(
        controller: controller,
        session: controller.activeBag!,
      );
    });
  }
}

// ─── Open-bag card ───────────────────────────────────────────────────────────
//
// Collapsed by default: shows only the bag identity header and the capacity
// progress bar, so it stays out of the way on a screen the phlebotomist is
// scanning/tapping through repeatedly. Tapping the header expands it in
// place to reveal the used/vacant/capacity stats, any capacity notice, and
// the bag-switch actions. State (expanded/collapsed) is purely visual, so it
// lives in the widget's own State rather than the shared controller.

class _OpenBagCard extends StatefulWidget {
  const _OpenBagCard({required this.controller, required this.session});

  final SampleCollectionController controller;
  final QRBagSession session;

  @override
  State<_OpenBagCard> createState() => _OpenBagCardState();
}

class _OpenBagCardState extends State<_OpenBagCard> {
  bool _expanded = false;

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final session = widget.session;
    final details = controller.activeBagDetails;
    final capacity = details?.capacity ?? 0;
    final used = details?.patientCount ?? 0;
    final vacant = details?.spaceVacant ?? 0;
    final ratio = controller.bagFillRatio;
    final color = _colorFor(ratio);
    final pct = (ratio * 100).round().clamp(0, 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Always-visible header: identity + capacity bar ────────────
          Semantics(
            button: true,
            label: _expanded ? 'Collapse bag details' : 'Expand bag details',
            child: InkWell(
              onTap: _toggleExpanded,
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ACTIVE BAG',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                controller.activeBagcode.isEmpty
                                    ? 'Bag #${session.bagId}'
                                    : controller.activeBagcode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _LiveBadge(),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textMuted,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Capacity row ────────────────────────────────────
                    Row(
                      children: [
                        const Text(
                          'Capacity used',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _CapacityBar(ratio: ratio, color: color),
                  ],
                ),
              ),
            ),
          ),

          // ── Expandable detail: stats, notices, actions ─────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: _expanded
                  ? Padding(
                key: const ValueKey('expanded'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    // ── Stats ──────────────────────────────────────
                    Row(
                      children: [
                        _StatTile(
                          label: 'Used',
                          value: details == null ? '—' : '$used',
                          color: color,
                        ),
                        const _StatDivider(),
                        _StatTile(
                          label: 'Vacant',
                          value: details == null ? '—' : '$vacant',
                          color: AppColors.blueText,
                        ),
                        const _StatDivider(),
                        _StatTile(
                          label: 'Capacity',
                          value: details == null ? '—' : '$capacity',
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),

                    if (capacity > 0 && controller.isBagFull) ...[
                      const SizedBox(height: 12),
                      const _CapacityNotice(
                        icon: Icons.error_outline_rounded,
                        message:
                        'This bag is full. Switch to another bag before adding more samples.',
                        color: AppColors.redText,
                        bg: Color(0xFFFEE2E2),
                        border: Color(0xFFFECACA),
                      ),
                    ] else if (capacity > 0 && ratio >= 0.9) ...[
                      const SizedBox(height: 12),
                      const _CapacityNotice(
                        icon: Icons.warning_amber_rounded,
                        message:
                        'This bag is almost full. Consider switching to a new bag soon.',
                        color: AppColors.amberText,
                        bg: AppColors.amberLight,
                        border: AppColors.amberBorder,
                      ),
                    ],

                    const SizedBox(height: 14),

                    // ── Actions ────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                showBagPicker(context, controller),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary800,
                              side: const BorderSide(
                                  color: AppColors.primary200),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.swap_horiz_rounded,
                                size: 18),
                            label: const Text(
                              'Change Bag',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Get.to(() => const ScanBagPage()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 18),
                            label: const Text(
                              'New Bag',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
                  : const SizedBox.shrink(key: ValueKey('collapsed')),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── No open-bag card ────────────────────────────────────────────────────────

class _NoOpenBagCard extends StatelessWidget {
  const _NoOpenBagCard({required this.controller});

  final SampleCollectionController controller;

  @override
  Widget build(BuildContext context) {
    // Closed assigned bags — the phlebotomist can reopen one of these
    // instead of being forced to scan a brand-new bag.
    final closedSessions = controller.bagController.allSessions
        .where((s) => !s.isOpen)
        .toList();
    final hasClosed = closedSessions.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amberLight.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.amberBorder.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.amberLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.amberText,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No open bag',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasClosed
                          ? closedSessions.length == 1
                          ? 'Reopen "${closedSessions.first.bagcode}" to '
                          'continue tagging samples to it, or scan a '
                          'new one.'
                          : 'Reopen one of your closed bags to continue '
                          'tagging samples, or scan a new one.'
                          : 'Open a bag to tag every collected sample to it.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasClosed)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (closedSessions.length == 1) {
                        confirmOpenBag(context, closedSessions.first);
                      } else {
                        showBagPicker(context, controller);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(Icons.unarchive_rounded, size: 19),
                    label: Text(
                      closedSessions.length == 1 ? 'Reopen Bag' : 'Reopen a Bag',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Get.to(() => const ScanBagPage()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary800,
                      side: const BorderSide(color: AppColors.primary200),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
                    label: const Text(
                      'New Bag',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const ScanBagPage()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
                label: const Text(
                  'Open New Bag',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Loading placeholder ─────────────────────────────────────────────────────

class _BagLoadingCard extends StatelessWidget {
  const _BagLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowSm,
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Checking open bag…',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emerald200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0.35).animate(_controller),
            child: const Icon(
              Icons.circle,
              size: 8,
              color: AppColors.greenText,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'OPEN',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.greenText,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  const _CapacityBar({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 10,
        color: AppColors.grayLight,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: ratio),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.85), color],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.border);
  }
}

class _CapacityNotice extends StatelessWidget {
  const _CapacityNotice({
    required this.icon,
    required this.message,
    required this.color,
    required this.bg,
    required this.border,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bag picker bottom sheet ─────────────────────────────────────────────────

/// Opens the "switch bag" sheet. Lists every session (open + closed) with
/// capacity, plus actions to reopen a closed bag (which auto-closes the
/// current one), close the open one, or scan a brand-new bag.
Future<void> showBagPicker(
    BuildContext context,
    SampleCollectionController controller,
    ) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BagPickerSheet(controller: controller),
  );
}

class _BagPickerSheet extends StatelessWidget {
  const _BagPickerSheet({required this.controller});

  final SampleCollectionController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Bag',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Only one bag stays open at a time.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _SheetCloseButton(),
            ],
          ),
          const SizedBox(height: 6),
          Obx(() {
            final sessions = controller.bagController.allSessions;
            if (sessions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No bags found yet.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
              );
            }
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.42,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sessions.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.border),
                itemBuilder: (_, i) => _BagRow(
                  controller: controller,
                  session: sessions[i],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).maybePop();
                Get.to(() => const ScanBagPage());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
              label: const Text(
                'Scan New Bag',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).maybePop();
                RouteManager.navigateToBagStatusDashboard();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary800,
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 16),
              label: const Text(
                'View all bags',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
    );
  }
}

class _BagRow extends StatelessWidget {
  const _BagRow({required this.controller, required this.session});

  final SampleCollectionController controller;
  final QRBagSession session;

  @override
  Widget build(BuildContext context) {
    final details = controller.bagController.bagDetailsMap[session.bagId];
    final isOpen = session.isOpen;
    final used = details?.patientCount ?? 0;
    final capacity = details?.capacity ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isOpen ? AppColors.primaryGradient : null,
              color: isOpen ? null : AppColors.grayLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 20,
              color: isOpen ? Colors.white : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.bagcode.isEmpty
                            ? 'Bag #${session.bagId}'
                            : session.bagcode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isOpen) ...[
                      const SizedBox(width: 8),
                      const _OpenChip(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  capacity > 0 ? '$used of $capacity used' : 'No capacity info',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isOpen)
            _CloseButton(session: session)
          else
            _ReopenButton(session: session),
        ],
      ),
    );
  }
}

class _OpenChip extends StatelessWidget {
  const _OpenChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Open',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.greenText,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.session});

  final QRBagSession session;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _confirmCloseBag(context, session),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.redText,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: const Size(0, 36),
      ),
      child: const Text(
        'Close',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _ReopenButton extends StatelessWidget {
  const _ReopenButton({required this.session});

  final QRBagSession session;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () => confirmOpenBag(
        context,
        session,
        onConfirmed: () => Navigator.of(context).maybePop(),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary100,
        foregroundColor: AppColors.primary900,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text(
        'Open',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

// ─── Confirmations ───────────────────────────────────────────────────────────

/// Asks for confirmation, then reopens [session] (a closed bag) via the
/// shared [BagRegistrationController].
///
/// [onConfirmed] lets sheet-based callers close their picker before the
/// reopen fires; callers without a sheet underneath (e.g. the
/// order-confirmation banner) omit it so nothing else gets popped.
Future<void> confirmOpenBag(
    BuildContext context,
    QRBagSession session, {
      VoidCallback? onConfirmed,
    }) async {
  final bagController = Get.find<BagRegistrationController>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        session.isOpen ? 'Open this bag?' : 'Reopen this bag?',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: Text(
        bagController.hasOpenBag
            ? 'Opening "${session.bagcode}" will automatically close the bag '
            'that is currently open. Continue?'
            : '${session.isOpen ? 'Open' : 'Reopen'} "${session.bagcode}" and '
            'start collecting into it?',
        style: const TextStyle(fontSize: 13, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary700),
          child: Text(session.isOpen ? 'Open Bag' : 'Reopen Bag'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    onConfirmed?.call();
    await bagController.reopenBag(session);
  }
}

Future<void> _confirmCloseBag(
    BuildContext context,
    QRBagSession session,
    ) async {
  final bagController = Get.find<BagRegistrationController>();
  // Capture the navigator up-front so it is safe to use after the await.
  final navigator = Navigator.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Close this bag?',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: const Text(
        'Once closed, no more samples can be added to this bag.',
        style: TextStyle(fontSize: 13, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.redText,
          ),
          child: const Text('Close Bag'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    navigator.maybePop(); // close the picker
    await bagController.closeBag(session);
  }
}

Color _colorFor(double ratio) {
  if (ratio >= 0.9) return AppColors.redText;
  if (ratio >= 0.6) return AppColors.amberText;
  return AppColors.greenText;
}
// /// Card that renders the open-bag state (capacity, status, bag-switch
// /// actions) on the sample collection screen. Rebuilds reactively whenever
// /// the shared [BagRegistrationController] state changes.
// class ActiveBagCard extends StatelessWidget {
//   const ActiveBagCard({super.key, required this.controller});
//
//   final SampleCollectionController controller;
//
//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       // First session fetch still in flight — show a slim placeholder.
//       if (controller.bagController.isLoading.value &&
//           !controller.bagController.hasBags) {
//         return const _BagLoadingCard();
//       }
//
//       if (!controller.hasOpenBag) {
//         return _NoOpenBagCard(controller: controller);
//       }
//
//       return _OpenBagCard(
//         controller: controller,
//         session: controller.activeBag!,
//       );
//     });
//   }
// }
// // ─── Open-bag card ───────────────────────────────────────────────────────────
//
// class _OpenBagCard extends StatelessWidget {
//   const _OpenBagCard({required this.controller, required this.session});
//
//   final SampleCollectionController controller;
//   final QRBagSession session;
//
//   @override
//   Widget build(BuildContext context) {
//     final details = controller.activeBagDetails;
//     final capacity = details?.capacity ?? 0;
//     final used = details?.patientCount ?? 0;
//     final vacant = details?.spaceVacant ?? 0;
//     final ratio = controller.bagFillRatio;
//     final color = _colorFor(ratio);
//     final pct = (ratio * 100).round().clamp(0, 100).toInt();
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.bgCard,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: AppColors.border),
//         boxShadow: AppColors.shadowSm,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── Header: icon + bag code + live badge ─────────────────────────
//           Row(
//             children: [
//               Container(
//                 width: 46,
//                 height: 46,
//                 decoration: BoxDecoration(
//                   gradient: AppColors.primaryGradient,
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: const Icon(
//                   Icons.inventory_2_rounded,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'ACTIVE BAG',
//                       style: TextStyle(
//                         fontSize: 10.5,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.textMuted,
//                         letterSpacing: 0.8,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       controller.activeBagcode.isEmpty
//                           ? 'Bag #${session.bagId}'
//                           : controller.activeBagcode,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w800,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 8),
//               const _LiveBadge(),
//             ],
//           ),
//           const SizedBox(height: 16),
//
//           // ── Capacity row ─────────────────────────────────────────────────
//           Row(
//             children: [
//               const Text(
//                 'Capacity used',
//                 style: TextStyle(
//                   fontSize: 12.5,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.textTertiary,
//                 ),
//               ),
//               const Spacer(),
//               Text(
//                 '$pct%',
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w800,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           _CapacityBar(ratio: ratio, color: color),
//           const SizedBox(height: 14),
// // ── Stats ────────────────────────────────────────────────────────
//           Row(
//             children: [
//               _StatTile(
//                 label: 'Used',
//                 value: details == null ? '—' : '$used',
//                 color: color,
//               ),
//               const _StatDivider(),
//               _StatTile(
//                 label: 'Vacant',
//                 value: details == null ? '—' : '$vacant',
//                 color: AppColors.blueText,
//               ),
//               const _StatDivider(),
//               _StatTile(
//                 label: 'Capacity',
//                 value: details == null ? '—' : '$capacity',
//                 color: AppColors.textPrimary,
//               ),
//             ],
//           ),
//
//           if (capacity > 0 && controller.isBagFull) ...[
//             const SizedBox(height: 12),
//             const _CapacityNotice(
//               icon: Icons.error_outline_rounded,
//               message:
//                   'This bag is full. Switch to another bag before adding more samples.',
//               color: AppColors.redText,
//               bg: Color(0xFFFEE2E2),
//               border: Color(0xFFFECACA),
//             ),
//           ] else if (capacity > 0 && ratio >= 0.9) ...[
//             const SizedBox(height: 12),
//             const _CapacityNotice(
//               icon: Icons.warning_amber_rounded,
//               message:
//                   'This bag is almost full. Consider switching to a new bag soon.',
//               color: AppColors.amberText,
//               bg: AppColors.amberLight,
//               border: AppColors.amberBorder,
//             ),
//           ],
//
//           const SizedBox(height: 14),
//
//           // ── Actions ──────────────────────────────────────────────────────
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: () => showBagPicker(context, controller),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: AppColors.primary800,
//                     side: const BorderSide(color: AppColors.primary200),
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   icon: const Icon(Icons.swap_horiz_rounded, size: 18),
//                   label: const Text(
//                     'Change Bag',
//                     style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () => Get.to(() => const ScanBagPage()),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary700,
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
//                   label: const Text(
//                     'New Bag',
//                     style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
// // ─── No open-bag card ────────────────────────────────────────────────────────
//
// class _NoOpenBagCard extends StatelessWidget {
//   const _NoOpenBagCard({required this.controller});
//
//   final SampleCollectionController controller;
//
//   @override
//   Widget build(BuildContext context) {
//     // Closed assigned bags — the phlebotomist can reopen one of these
//     // instead of being forced to scan a brand-new bag.
//     final closedSessions = controller.bagController.allSessions
//         .where((s) => !s.isOpen)
//         .toList();
//     final hasClosed = closedSessions.isNotEmpty;
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.amberLight.withOpacity(0.35),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: AppColors.amberBorder.withOpacity(0.7)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 44,
//                 height: 44,
//                 decoration: BoxDecoration(
//                   color: AppColors.amberLight,
//                   borderRadius: BorderRadius.circular(13),
//                 ),
//                 child: const Icon(
//                   Icons.inventory_2_outlined,
//                   color: AppColors.amberText,
//                   size: 22,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'No open bag',
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w800,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       hasClosed
//                           ? closedSessions.length == 1
//                               ? 'Reopen "${closedSessions.first.bagcode}" to '
//                                   'continue tagging samples to it, or scan a '
//                                   'new one.'
//                               : 'Reopen one of your closed bags to continue '
//                                   'tagging samples, or scan a new one.'
//                           : 'Open a bag to tag every collected sample to it.',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: AppColors.textTertiary,
//                         height: 1.35,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),
//           if (hasClosed)
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       if (closedSessions.length == 1) {
//                         confirmOpenBag(context, closedSessions.first);
//                       } else {
//                         showBagPicker(context, controller);
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.primary700,
//                       foregroundColor: Colors.white,
//                       elevation: 0,
//                       padding: const EdgeInsets.symmetric(vertical: 13),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(13),
//                       ),
//                     ),
//                     icon: const Icon(Icons.unarchive_rounded, size: 19),
//                     label: Text(
//                       closedSessions.length == 1 ? 'Reopen Bag' : 'Reopen a Bag',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w700,
//                         fontSize: 13.5,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () => Get.to(() => const ScanBagPage()),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: AppColors.primary800,
//                       side: const BorderSide(color: AppColors.primary200),
//                       padding: const EdgeInsets.symmetric(vertical: 13),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(13),
//                       ),
//                     ),
//                     icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
//                     label: const Text(
//                       'New Bag',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w700,
//                         fontSize: 13.5,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             )
//           else
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: () => Get.to(() => const ScanBagPage()),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary700,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   padding: const EdgeInsets.symmetric(vertical: 13),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(13),
//                   ),
//                 ),
//                 icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
//                 label: const Text(
//                   'Open New Bag',
//                   style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
// // ─── Loading placeholder ─────────────────────────────────────────────────────
//
// class _BagLoadingCard extends StatelessWidget {
//   const _BagLoadingCard();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.bgCard,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: AppColors.border),
//         boxShadow: AppColors.shadowSm,
//       ),
//       child: const Row(
//         children: [
//           SizedBox(
//             width: 18,
//             height: 18,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
//             ),
//           ),
//           SizedBox(width: 12),
//           Text(
//             'Checking open bag…',
//             style: TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: AppColors.textTertiary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─── Sub-widgets ─────────────────────────────────────────────────────────────
//
// class _LiveBadge extends StatefulWidget {
//   const _LiveBadge();
//
//   @override
//   State<_LiveBadge> createState() => _LiveBadgeState();
// }
//
// class _LiveBadgeState extends State<_LiveBadge>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1100),
//     )..repeat(reverse: true);
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       decoration: BoxDecoration(
//         color: AppColors.emerald50,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: AppColors.emerald200),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           FadeTransition(
//             opacity: Tween<double>(begin: 1, end: 0.35).animate(_controller),
//             child: const Icon(
//               Icons.circle,
//               size: 8,
//               color: AppColors.greenText,
//             ),
//           ),
//           const SizedBox(width: 6),
//           const Text(
//             'OPEN',
//             style: TextStyle(
//               fontSize: 10.5,
//               fontWeight: FontWeight.w800,
//               color: AppColors.greenText,
//               letterSpacing: 0.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _CapacityBar extends StatelessWidget {
//   const _CapacityBar({required this.ratio, required this.color});
//
//   final double ratio;
//   final Color color;
//
//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(6),
//       child: Container(
//         height: 10,
//         color: AppColors.grayLight,
//         alignment: Alignment.centerLeft,
//         child: TweenAnimationBuilder<double>(
//           tween: Tween<double>(begin: 0, end: ratio),
//           duration: const Duration(milliseconds: 900),
//           curve: Curves.easeOutCubic,
//           builder: (context, value, _) => FractionallySizedBox(
//             widthFactor: value.clamp(0.0, 1.0),
//             child: DecoratedBox(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [color.withOpacity(0.85), color],
//                 ),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
// class _StatTile extends StatelessWidget {
//   const _StatTile({
//     required this.label,
//     required this.value,
//     required this.color,
//   });
//
//   final String label;
//   final String value;
//   final Color color;
//
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Column(
//         children: [
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w800,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 10.5,
//               fontWeight: FontWeight.w600,
//               color: AppColors.textMuted,
//               letterSpacing: 0.3,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _StatDivider extends StatelessWidget {
//   const _StatDivider();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(width: 1, height: 32, color: AppColors.border);
//   }
// }
//
// class _CapacityNotice extends StatelessWidget {
//   const _CapacityNotice({
//     required this.icon,
//     required this.message,
//     required this.color,
//     required this.bg,
//     required this.border,
//   });
//
//   final IconData icon;
//   final String message;
//   final Color color;
//   final Color bg;
//   final Color border;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: border),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 16, color: color),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               message,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: color,
//                 height: 1.4,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// // ─── Bag picker bottom sheet ─────────────────────────────────────────────────
//
// /// Opens the "switch bag" sheet. Lists every session (open + closed) with
// /// capacity, plus actions to reopen a closed bag (which auto-closes the
// /// current one), close the open one, or scan a brand-new bag.
// Future<void> showBagPicker(
//   BuildContext context,
//   SampleCollectionController controller,
// ) {
//   return showModalBottomSheet<void>(
//     context: context,
//     isScrollControlled: true,
//     useSafeArea: true,
//     backgroundColor: Colors.transparent,
//     builder: (_) => _BagPickerSheet(controller: controller),
//   );
// }
//
// class _BagPickerSheet extends StatelessWidget {
//   const _BagPickerSheet({required this.controller});
//
//   final SampleCollectionController controller;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(top: 48),
//       padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
//       decoration: const BoxDecoration(
//         color: AppColors.bgCard,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: AppColors.borderStrong,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Choose Bag',
//                       style: TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.w800,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                     SizedBox(height: 2),
//                     Text(
//                       'Only one bag stays open at a time.',
//                       style: TextStyle(fontSize: 12, color: AppColors.textMuted),
//                     ),
//                   ],
//                 ),
//               ),
//               _SheetCloseButton(),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Obx(() {
//             final sessions = controller.bagController.allSessions;
//             if (sessions.isEmpty) {
//               return const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 20),
//                 child: Center(
//                   child: Text(
//                     'No bags found yet.',
//                     style: TextStyle(fontSize: 13, color: AppColors.textMuted),
//                   ),
//                 ),
//               );
//             }
//             return ConstrainedBox(
//               constraints: BoxConstraints(
//                 maxHeight: MediaQuery.of(context).size.height * 0.42,
//               ),
//               child: ListView.separated(
//                 shrinkWrap: true,
//                 itemCount: sessions.length,
//                 separatorBuilder: (_, __) =>
//                     const Divider(height: 1, color: AppColors.border),
//                 itemBuilder: (_, i) => _BagRow(
//                   controller: controller,
//                   session: sessions[i],
//                 ),
//               ),
//             );
//           }),
//           const SizedBox(height: 14),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.of(context).maybePop();
//                 Get.to(() => const ScanBagPage());
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary700,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(vertical: 13),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(13),
//                 ),
//               ),
//               icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
//               label: const Text(
//                 'Scan New Bag',
//                 style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
//               ),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Center(
//             child: TextButton.icon(
//               onPressed: () {
//                 Navigator.of(context).maybePop();
//                 RouteManager.navigateToBagStatusDashboard();
//               },
//               style: TextButton.styleFrom(
//                 foregroundColor: AppColors.primary800,
//               ),
//               icon: const Icon(Icons.grid_view_rounded, size: 16),
//               label: const Text(
//                 'View all bags',
//                 style: TextStyle(fontWeight: FontWeight.w600),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _SheetCloseButton extends StatelessWidget {
//   const _SheetCloseButton();
//
//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       onPressed: () => Navigator.of(context).maybePop(),
//       icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
//     );
//   }
// }
// class _BagRow extends StatelessWidget {
//   const _BagRow({required this.controller, required this.session});
//
//   final SampleCollectionController controller;
//   final QRBagSession session;
//
//   @override
//   Widget build(BuildContext context) {
//     final details = controller.bagController.bagDetailsMap[session.bagId];
//     final isOpen = session.isOpen;
//     final used = details?.patientCount ?? 0;
//     final capacity = details?.capacity ?? 0;
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               gradient: isOpen ? AppColors.primaryGradient : null,
//               color: isOpen ? null : AppColors.grayLight,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               Icons.inventory_2_rounded,
//               size: 20,
//               color: isOpen ? Colors.white : AppColors.textMuted,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Flexible(
//                       child: Text(
//                         session.bagcode.isEmpty
//                             ? 'Bag #${session.bagId}'
//                             : session.bagcode,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           fontSize: 13.5,
//                           fontWeight: FontWeight.w700,
//                           color: AppColors.textPrimary,
//                         ),
//                       ),
//                     ),
//                     if (isOpen) ...[
//                       const SizedBox(width: 8),
//                       const _OpenChip(),
//                     ],
//                   ],
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   capacity > 0 ? '$used of $capacity used' : 'No capacity info',
//                   style: const TextStyle(
//                     fontSize: 11.5,
//                     color: AppColors.textTertiary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 8),
//           if (isOpen)
//             _CloseButton(session: session)
//           else
//             _ReopenButton(session: session),
//         ],
//       ),
//     );
//   }
// }
//
// class _OpenChip extends StatelessWidget {
//   const _OpenChip();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
//       decoration: BoxDecoration(
//         color: AppColors.emerald50,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: const Text(
//         'Open',
//         style: TextStyle(
//           fontSize: 10,
//           fontWeight: FontWeight.w800,
//           color: AppColors.greenText,
//         ),
//       ),
//     );
//   }
// }
//
// class _CloseButton extends StatelessWidget {
//   const _CloseButton({required this.session});
//
//   final QRBagSession session;
//
//   @override
//   Widget build(BuildContext context) {
//     return TextButton(
//       onPressed: () => _confirmCloseBag(context, session),
//       style: TextButton.styleFrom(
//         foregroundColor: AppColors.redText,
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//         minimumSize: const Size(0, 36),
//       ),
//       child: const Text(
//         'Close',
//         style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
//       ),
//     );
//   }
// }
//
// class _ReopenButton extends StatelessWidget {
//   const _ReopenButton({required this.session});
//
//   final QRBagSession session;
//
//   @override
//   Widget build(BuildContext context) {
//     return FilledButton.tonal(
//       onPressed: () => confirmOpenBag(
//         context,
//         session,
//         onConfirmed: () => Navigator.of(context).maybePop(),
//       ),
//       style: FilledButton.styleFrom(
//         backgroundColor: AppColors.primary100,
//         foregroundColor: AppColors.primary900,
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//         minimumSize: const Size(0, 36),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//       child: const Text(
//         'Open',
//         style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
//       ),
//     );
//   }
// }
// // ─── Confirmations ───────────────────────────────────────────────────────────
//
// /// Asks for confirmation, then reopens [session] (a closed bag) via the
// /// shared [BagRegistrationController].
// ///
// /// [onConfirmed] lets sheet-based callers close their picker before the
// /// reopen fires; callers without a sheet underneath (e.g. the
// /// order-confirmation banner) omit it so nothing else gets popped.
// Future<void> confirmOpenBag(
//   BuildContext context,
//   QRBagSession session, {
//   VoidCallback? onConfirmed,
// }) async {
//   final bagController = Get.find<BagRegistrationController>();
//   final confirmed = await showDialog<bool>(
//     context: context,
//     builder: (ctx) => AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       title: Text(
//         session.isOpen ? 'Open this bag?' : 'Reopen this bag?',
//         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
//       ),
//       content: Text(
//         bagController.hasOpenBag
//             ? 'Opening "${session.bagcode}" will automatically close the bag '
//                 'that is currently open. Continue?'
//             : '${session.isOpen ? 'Open' : 'Reopen'} "${session.bagcode}" and '
//                 'start collecting into it?',
//         style: const TextStyle(fontSize: 13, height: 1.4),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(ctx).pop(false),
//           child: const Text(
//             'Cancel',
//             style: TextStyle(fontWeight: FontWeight.w600),
//           ),
//         ),
//         FilledButton(
//           onPressed: () => Navigator.of(ctx).pop(true),
//           style: FilledButton.styleFrom(backgroundColor: AppColors.primary700),
//           child: Text(session.isOpen ? 'Open Bag' : 'Reopen Bag'),
//         ),
//       ],
//     ),
//   );
//
//   if (confirmed == true) {
//     onConfirmed?.call();
//     await bagController.reopenBag(session);
//   }
// }
//
// Future<void> _confirmCloseBag(
//   BuildContext context,
//   QRBagSession session,
// ) async {
//   final bagController = Get.find<BagRegistrationController>();
//   // Capture the navigator up-front so it is safe to use after the await.
//   final navigator = Navigator.of(context);
//   final confirmed = await showDialog<bool>(
//     context: context,
//     builder: (ctx) => AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       title: const Text(
//         'Close this bag?',
//         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
//       ),
//       content: const Text(
//         'Once closed, no more samples can be added to this bag.',
//         style: TextStyle(fontSize: 13, height: 1.4),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(ctx).pop(false),
//           child: const Text(
//             'Cancel',
//             style: TextStyle(fontWeight: FontWeight.w600),
//           ),
//         ),
//         FilledButton(
//           onPressed: () => Navigator.of(ctx).pop(true),
//           style: FilledButton.styleFrom(
//             backgroundColor: AppColors.redText,
//           ),
//           child: const Text('Close Bag'),
//         ),
//       ],
//     ),
//   );
//
//   if (confirmed == true) {
//     navigator.maybePop(); // close the picker
//     await bagController.closeBag(session);
//   }
// }
//
// Color _colorFor(double ratio) {
//   if (ratio >= 0.9) return AppColors.redText;
//   if (ratio >= 0.6) return AppColors.amberText;
//   return AppColors.greenText;
// }