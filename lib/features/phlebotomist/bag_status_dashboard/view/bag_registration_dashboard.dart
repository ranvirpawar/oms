// views/bag_registration_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/view/scan_bag_page.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/view/widget/bag_detail_view.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/view/widget/loading_skeleton.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/view/widget/spacing_and_radius.dart';
import 'package:lifenity_connect/routes/route_manager.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../../constants/app_strings.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../utils/widgets/liw.dart';
import '../../../../utils/widgets/metrics_data.dart';
import '../../../../utils/widgets/metrics_strip.dart';
import '../controller/registrarion_bag_controller.dart';
import '../model/qr_bag_details.dart';
import '../model/qr_bag_session.dart';

// views/bag_registration_dashboard.dart
import 'dart:math' as math;

import 'package:flutter/services.dart';

// ─── Local design tokens (spacing / radius) ───────────────────────────────────
// Kept local to this file since the project theme folder only exposes colors;
// these follow a 4pt scale so nothing here is an arbitrary magic number.

class BagRegistrationDashboard extends StatelessWidget {
  const BagRegistrationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BagRegistrationController());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: const CustomAppBar(
        title: AppStrings.bagStatusDashboard,
        /* actions: [
          Semantics(
            label: 'View collected orders',
            button: true,
            child: IconButton(
              tooltip: 'Collected orders',
              icon: const Icon(Icons.list_alt, color: AppColors.surfaceContainer),
              onPressed: () {
                HapticFeedback.selectionClick();
                Get.to(
                      () => const CollectedOrdersList(),
                  transition: Transition.rightToLeftWithFade,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
          ),
        ],*/
      ),
      floatingActionButton: Obx(
        () => controller.isLoading.value
            ? const SizedBox.shrink()
            : _EntranceFab(
                child: FloatingActionButton.extended(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Get.to(
                      () => const ScanBagPage(),
                      transition: Transition.downToUp,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text(
                    'Open New Bag',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingSkeleton();
        }

        return RefreshIndicator(
          onRefresh: () {
            HapticFeedback.lightImpact();
            return controller.refreshDashboard();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              BagDashboardSpacing.lg,
              BagDashboardSpacing.xl,
              BagDashboardSpacing.lg,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StaggerIn(
                  index: 0,
                  child: _SummaryStrip(controller: controller),
                ),
                const SizedBox(height: BagDashboardSpacing.xxl),
                if (controller.hasBags) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 14),
                    child: Text(
                      'Your Bags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A202C),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  ...controller.allSessions.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _StaggerIn(
                        index: entry.key + 1,
                        child: _BagCard(
                          session: entry.value,
                          controller: controller,
                        ),
                      ),
                    ),
                  ),
                ] else
                  _StaggerIn(
                    index: 1,
                    child: _EmptyState(controller: controller),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Entrance helpers ──────────────────────────────────────────────────────────

/// Fades + slides content in, with a delay that scales with [index] so a list
/// reads as considerately "designed" rather than popping in all at once.
class _StaggerIn extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggerIn({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final cappedIndex = math.min(index, 8);
    final delayMs = cappedIndex * 55;
    final totalMs = 300 + delayMs;
    final delayFraction = delayMs / totalMs;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(delayFraction, 1.0, curve: Curves.easeOutCubic),
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// One-shot spring-ish scale-in for the FAB so it feels like it "arrives"
/// rather than just appearing.
class _EntranceFab extends StatefulWidget {
  final Widget child;

  const _EntranceFab({required this.child});

  @override
  State<_EntranceFab> createState() => _EntranceFabState();
}

class _EntranceFabState extends State<_EntranceFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  )..forward();
  late final Animation<double> _scale = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutBack,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Generic press-feedback wrapper: scales down slightly on touch and fires a
/// light haptic on release, per the interaction pattern for tappable surfaces.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final HapticFeedbackType haptic;

  const Pressable({
    required this.child,
    required this.onTap,
    this.haptic = HapticFeedbackType.light,
    super.key,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

enum HapticFeedbackType { light, selection, none }

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _fireHaptic() {
    switch (widget.haptic) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _fireHaptic();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─── Summary Strip ────────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final BagRegistrationController controller;

  const _SummaryStrip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final open = controller.allSessions.where((s) => s.isOpen).length;
      final closed = controller.allSessions.where((s) => !s.isOpen).length;

      final items = <MetricData>[
        MetricData(
          value: controller.allSessions.length.toString().padLeft(2, '0'),
          label: 'Total Bags',
          icon: Icons.inventory_2_outlined,
          dot: AppColors.primary,
        ),
        MetricData(
          value: open.toString().padLeft(2, '0'),
          label: 'Open',
          icon: Icons.lock_open_outlined,
          dot: const Color(0xFF48BB78),
        ),
        MetricData(
          value: closed.toString().padLeft(2, '0'),
          label: 'Closed',
          icon: Icons.lock_outline,
          dot: const Color(0xFFED8936),
        ),
      ];

      return MetricsStrip(items: items);
    });
  }
}

// ─── Design tokens used below (add to your AppColors/AppRadii/AppSpacing) ────
//
// class AppColors {
//   static const openAccent    = Color(0xFF0F8F82); // muted teal, calmer than green
//   static const closedAccent  = Color(0xFF64748B); // slate, neutral rather than alarm-orange
//   static const fullAccent    = Color(0xFFD97757); // warm terracotta, softer than red
//   static const surface       = Color(0xFFFCFCFD); // barely-off-white, not flat #FFF
//   static const hairline      = Color(0xFFECEEF1);
//   static const textPrimary   = Color(0xFF15181D);
//   static const textSecondary = Color(0xFF80868F);
// }
//
// Radii: card 14 (AppRadii.md), pill 999. Spacing: 4/8/12/16/24 scale.

// ─── Individual Bag Card ──────────────────────────────────────────────────────

class _BagCard extends StatefulWidget {
  final QRBagSession session;
  final BagRegistrationController controller;

  const _BagCard({required this.session, required this.controller});

  @override
  State<_BagCard> createState() => _BagCardState();
}

class _BagCardState extends State<_BagCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnim;
  late Animation<double> _rotateAnim;

  static const _openAccent = Color(0xFF0F8F82);
  static const _closedAccent = Color(0xFF64748B);
  static const _fullAccent = Color(0xFFD97757);
  static const _surface = Color(0xFFFCFCFD);
  static const _hairline = Color(0xFFECEEF1);
  static const _textPrimary = Color(0xFF15181D);
  static const _textSecondary = Color(0xFF80868F);

  @override
  void initState() {
    super.initState();
    _expanded = widget.session.isOpen;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: _expanded ? 1.0 : 0.0,
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
    _rotateAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
    _expanded ? _animController.forward() : _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final ctrl = widget.controller;
    final isOpen = session.isOpen;
    final Color accent = isOpen ? _openAccent : _closedAccent;

    return Obx(() {
      final details = ctrl.bagDetailsMap[session.bagId];
      final isFull = isOpen && ctrl.isBagFull(session.bagId);
      final stripeColor = isFull ? _fullAccent : accent;

      return RepaintBoundary(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hairline, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Status accent stripe (replaces heavy border ring) ──────
                  Container(width: 3, color: stripeColor),
                  Expanded(
                    child: Column(
                      children: [
                        Pressable(
                          onTap: _toggle,
                          haptic: HapticFeedbackType.none,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(
                                    isOpen
                                        ? Icons.inventory_2
                                        : Icons.inventory_2_outlined,
                                    color: accent,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          session.bagcode,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _textPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        details != null
                                            ? '${details.patientCount}/${details.capacity}'
                                            : (isOpen ? 'Open' : 'Closed'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _textSecondary,
                                        ),
                                      ),
                                      if (isFull) ...[
                                        const SizedBox(width: 6),
                                        const _FullChip(),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                RotationTransition(
                                  turns: Tween<double>(
                                    begin: 0,
                                    end: 0.5,
                                  ).animate(_rotateAnim),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: _textSecondary.withOpacity(0.7),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizeTransition(
                          sizeFactor: _expandAnim,
                          child: Column(
                            children: [
                              Container(height: 1, color: _hairline),
                              if (details != null)
                                _DetailsBody(details: details, accent: accent),
                              _ActionRow(
                                session: session,
                                controller: ctrl,
                                isOpen: isOpen,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Full chip (small warning tag, shown inline next to the counts) ─────────

class _FullChip extends StatelessWidget {
  const _FullChip();

  static const _fullAccent = Color(0xFFD97757);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bag is full',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _fullAccent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Full',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _fullAccent,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ─── Bag Details Body (inside expanded card) ──────────────────────────────────

class _DetailsBody extends StatelessWidget {
  final QRBagDetails details;
  final Color accent;

  const _DetailsBody({required this.details, required this.accent});

  static const _textSecondary = Color(0xFF80868F);
  static const _fullAccent = Color(0xFFD97757);

  @override
  Widget build(BuildContext context) {
    final pct = details.capacity > 0
        ? (details.patientCount / details.capacity).clamp(0.0, 1.0)
        : 0.0;
    final Color fillColor = pct >= 0.9 ? _fullAccent : accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniStat(
                label: 'Capacity',
                value: details.capacity.toString(),
                icon: Icons.all_inbox_rounded,
                color: const Color(0xFF5B6472),
              ),
              _MiniStat(
                label: 'Tubes',
                value: details.patientCount.toString(),
                icon: Icons.colorize_rounded,
                color: accent,
              ),
              _MiniStat(
                label: 'Vacant',
                value: details.spaceVacant.toString(),
                icon: Icons.inbox_rounded,
                color: const Color(0xFF5B6472),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Space Utilization',
                style: TextStyle(fontSize: 11, color: _textSecondary),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fillColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: const Color(0xFFF0F1F3),
                valueColor: AlwaysStoppedAnimation<Color>(fillColor),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 8),

          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF15181D),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),

              Text(
                label,
                style: const TextStyle(fontSize: 9.5, color: Color(0xFF80868F)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Individual Bag Card ──────────────────────────────────────────────────────

/*class _BagCard extends StatefulWidget {
  final QRBagSession session;
  final BagRegistrationController controller;

  const _BagCard({required this.session, required this.controller});

  @override
  State<_BagCard> createState() => _BagCardState();
}*/

/*class _BagCardState extends State<_BagCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    // Auto-expand the open bag
    _expanded = widget.session.isOpen;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: _expanded ? 1.0 : 0.0,
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
    _rotateAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
    _expanded ? _animController.forward() : _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final ctrl = widget.controller;
    final isOpen = session.isOpen;

    final Color accent = isOpen
        ? const Color(0xFF48BB78)
        : const Color(0xFFED8936);

    return Obx(() {
      final details = ctrl.bagDetailsMap[session.bagId];
      final isFull = isOpen && ctrl.isBagFull(session.bagId);

      return RepaintBoundary(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(BagDashboardRadius.lg),
            border: Border.all(
              color: isOpen
                  ? (isFull
                  ? const Color(0xFFFC8181).withOpacity(0.5)
                  : const Color(0xFF48BB78).withOpacity(0.4))
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header row ────────────────────────────────────────────────
              Pressable(
                onTap: _toggle,
                haptic: HapticFeedbackType.none, // handled inside _toggle
                child: Padding(
                  padding: const EdgeInsets.all(BagDashboardSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          isOpen
                              ? Icons.inventory_2
                              : Icons.inventory_2_outlined,
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    session.bagcode,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A202C),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _StatusBadge(isOpen: isOpen),
                                if (isFull) ...[
                                  const SizedBox(width: 6),
                                  const _FullChip(),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            if (details != null)
                              Text(
                                '${details.patientCount} / ${details.capacity} tubes',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF718096),
                                ),
                              )
                            else
                              const Text(
                                'Tap to view details',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB0BAC9),
                                ),
                              ),
                          ],
                        ),
                      ),
                      RotationTransition(
                        turns: Tween<double>(begin: 0, end: 0.5)
                            .animate(_rotateAnim),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFFB0BAC9),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Expandable section ────────────────────────────────────────
              SizeTransition(
                sizeFactor: _expandAnim,
                child: Column(
                  children: [
                    const Divider(height: 1, color: Color(0xFFF0F4F8)),
                    if (details != null) _DetailsBody(details: details),
                    _ActionRow(
                      session: session,
                      controller: ctrl,
                      isOpen: isOpen,
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
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isOpen;

  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? const Color(0xFF48BB78) : const Color(0xFFED8936);
    return Semantics(
      label: isOpen ? 'Bag status: open' : 'Bag status: closed',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(BagDashboardRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              isOpen ? 'Open' : 'Closed',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isOpen
                    ? const Color(0xFF276749)
                    : const Color(0xFF7B341E),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullChip extends StatelessWidget {
  const _FullChip();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bag is full',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE53E3E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(BagDashboardRadius.pill),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 9, color: Color(0xFFE53E3E)),
            SizedBox(width: 3),
            Text(
              'Full',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE53E3E),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bag Details Body (inside expanded card) ──────────────────────────────────

class _DetailsBody extends StatelessWidget {
  final QRBagDetails details;

  const _DetailsBody({required this.details});

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(BagDashboardSpacing.lg, BagDashboardSpacing.lg, BagDashboardSpacing.lg, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniStat(
                label: 'Capacity',
                value: details.capacity.toString(),
                icon: Icons.all_inbox_rounded,
                color: const Color(0xFF4299E1),
              ),
              _MiniStat(
                label: 'Tubes',
                value: details.patientCount.toString(),
                icon: Icons.colorize_rounded,
                color: const Color(0xFFED8936),
              ),
              _MiniStat(
                label: 'Vacant',
                value: details.spaceVacant.toString(),
                icon: Icons.inbox_rounded,
                color: const Color(0xFF48BB78),
              ),
            ],
          ),
          const SizedBox(height: BagDashboardSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Space Utilization',
                style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fillColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: BagDashboardSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: const Color(0xFFEDF2F7),
                valueColor: AlwaysStoppedAnimation<Color>(fillColor),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
          ),
        ],
      ),
    );
  }
}*/

// ─── Action Row per card ──────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final QRBagSession session;
  final BagRegistrationController controller;
  final bool isOpen;

  const _ActionRow({
    required this.session,
    required this.controller,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BagDashboardSpacing.lg,
        0,
        BagDashboardSpacing.lg,
        BagDashboardSpacing.lg,
      ),
      child: Row(
        children: [
          // View Details — always visible
          Expanded(
            child: _SmallButton(
              label: 'View',
              icon: Icons.remove_red_eye_outlined,
              color: AppColors.primary,
              outlined: true,
              onTap: () => Get.to(
                () => const BagDetailView(),
                transition: Transition.rightToLeftWithFade,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                arguments: {
                  'sessionId': session.sessionID,
                  'bagId': session.bagId,
                  'bagcode': session.bagcode,
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (isOpen) ...[
            Expanded(
              child: _SmallButton(
                label: 'Close',
                icon: Icons.lock_outline,
                color: AppColors.secondary,
                outlined: true,
                onTap: () => _confirmClose(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallButton(
                label: 'Collect',
                icon: Icons.person_add_alt_1,
                color: controller.isBagFull(session.bagId)
                    ? const Color(0xFFCBD5E0) // greyed out when full
                    : AppColors.primary,
                haptic: controller.isBagFull(session.bagId)
                    ? HapticFeedbackType.selection
                    : HapticFeedbackType.light,
                onTap: () {
                  if (controller.isBagFull(session.bagId)) {
                    _showBagFullSheet(context);
                  } else {
                    RouteManager.navigateToPatientQueue(isCollectionTrue: true);
                  }
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: _SmallButton(
                label: 'Reopen',
                icon: Icons.lock_open_rounded,
                color: const Color(0xFFED8936),
                onTap: () => _confirmReopen(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showBagFullSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    final details = controller.bagDetailsMap[session.bagId];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BagFullSheet(bagcode: session.bagcode, details: details),
    );
  }

  void _confirmClose(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ActionDialog(
        title: 'Close Bag?',
        message:
            'Are you sure you want to close bag ${session.bagcode}? '
            'You can reopen it later if needed.',
        confirmLabel: 'Close Bag',
        confirmColor: AppColors.secondary,
        confirmIcon: Icons.lock_outline,
        onConfirm: () => controller.closeBag(session),
      ),
    );
  }

  void _confirmReopen(BuildContext context) {
    final currentlyOpen = controller.activeBag;
    final willAutoClose =
        currentlyOpen != null && currentlyOpen.bagId != session.bagId;

    showDialog(
      context: context,
      builder: (_) => _ActionDialog(
        title: 'Reopen Bag?',
        message: 'Do you want to reopen ${session.bagcode}?',
        confirmLabel: 'Reopen',
        confirmColor: const Color(0xFFED8936),
        confirmIcon: Icons.lock_open_rounded,
        onConfirm: () => controller.reopenBag(session),
        warning: willAutoClose
            ? 'Bag ${currentlyOpen.bagcode} will be automatically closed.'
            : null,
      ),
    );
  }
}


class _ActionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final IconData confirmIcon;
  final VoidCallback onConfirm;
  final String? warning;

  const _ActionDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.confirmIcon,
    required this.onConfirm,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(BagDashboardRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF718096),
              ),
            ),
            if (warning != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(BagDashboardRadius.sm),
                  border: Border.all(color: const Color(0xFFED8936), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFED8936),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7B341E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Cancel',
                    variant: _DialogButtonVariant.ghost,
                    onTap: () => Get.back(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    label: confirmLabel,
                    icon: confirmIcon,
                    variant: _DialogButtonVariant.filled,
                    color: confirmColor,
                    onTap: () {
                      Get.back();
                      onConfirm();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _DialogButtonVariant { filled, ghost }


class _DialogButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final _DialogButtonVariant variant;
  final Color? color;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.variant,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isFilled = widget.variant == _DialogButtonVariant.filled;
    final accent = widget.color ?? AppColors.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFilled
                ? accent.withOpacity(_pressed ? 0.88 : 1.0)
                : const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(BagDashboardRadius.sm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: isFilled ? Colors.white : const Color(0xFF4A5568),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isFilled ? Colors.white : const Color(0xFF4A5568),
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

// ─── Bag Full Bottom Sheet ────────────────────────────────────────────────────

class _BagFullSheet extends StatelessWidget {
  final String bagcode;
  final QRBagDetails? details;

  const _BagFullSheet({required this.bagcode, this.details});

  @override
  Widget build(BuildContext context) {
    final capacity = details?.capacity ?? 0;
    final filled = details?.patientCount ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(
        BagDashboardSpacing.xxl,
        12,
        BagDashboardSpacing.xxl,
        40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: BagDashboardSpacing.xxl + 4),

          // Icon with pulsing red ring
          const _FullBagIcon(),

          const SizedBox(height: BagDashboardSpacing.xl),

          // Title
          const Text(
            'Bag Is Full',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A202C),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: BagDashboardSpacing.sm),
          Text(
            'Bag $bagcode has reached its maximum capacity.\nPlease open a new bag to continue registering.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
              height: 1.6,
            ),
          ),

          const SizedBox(height: BagDashboardSpacing.xxl + 4),

          // Capacity visual
          if (details != null) ...[
            _CapacityBar(filled: filled, capacity: capacity),
            const SizedBox(height: BagDashboardSpacing.xxl + 4),
          ],

          // CTA row
          Row(
            children: [
              Expanded(
                child: Pressable(
                  haptic: HapticFeedbackType.selection,
                  onTap: () => Get.back(),
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: const Color(0xFF718096),
                      foregroundColor: const Color(0xFF718096),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          BagDashboardRadius.md,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: BagDashboardSpacing.md),
              Expanded(
                flex: 2,
                child: Pressable(
                  haptic: HapticFeedbackType.light,
                  onTap: () {
                    Get.back();
                    Get.to(
                      () => const ScanBagPage(),
                      transition: Transition.downToUp,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: ElevatedButton.icon(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: AppColors.primary,
                      disabledForegroundColor: Colors.white,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          BagDashboardRadius.md,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text(
                      'Open New Bag',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing icon ─────────────────────────────────────────────────────────────

class _FullBagIcon extends StatefulWidget {
  const _FullBagIcon();

  @override
  State<_FullBagIcon> createState() => _FullBagIconState();
}

class _FullBagIconState extends State<_FullBagIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) =>
            Transform.scale(scale: _pulse.value, child: child),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFC8181).withOpacity(0.12),
            border: Border.all(
              color: const Color(0xFFFC8181).withOpacity(0.35),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.inventory_2,
            color: Color(0xFFE53E3E),
            size: 36,
          ),
        ),
      ),
    );
  }
}

// ─── Capacity bar ─────────────────────────────────────────────────────────────

class _CapacityBar extends StatelessWidget {
  final int filled;
  final int capacity;

  const _CapacityBar({required this.filled, required this.capacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BagDashboardSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(BagDashboardRadius.lg),
        border: Border.all(color: const Color(0xFFFED7D7)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.colorize_rounded,
                    size: 14,
                    color: Color(0xFFE53E3E),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tubes registered',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF718096),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$filled',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                    TextSpan(
                      text: ' / $capacity',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: BagDashboardSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: capacity > 0 ? (filled / capacity).clamp(0.0, 1.0) : 1.0,
              backgroundColor: const Color(0xFFFED7D7),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFE53E3E),
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: BagDashboardSpacing.sm + 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE53E3E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded, size: 12, color: Color(0xFFE53E3E)),
                SizedBox(width: 5),
                Text(
                  'No space available — bag is at full capacity',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE53E3E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small button ─────────────────────────────────────────────────────────────

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final HapticFeedbackType haptic;
  final VoidCallback onTap;

  const _SmallButton({
    required this.label,
    required this.icon,
    required this.color,
    this.outlined = false,
    this.haptic = HapticFeedbackType.light,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = outlined
        ? OutlinedButton.icon(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              disabledForegroundColor: color,
              foregroundColor: color,
              side: BorderSide(color: color.withOpacity(0.6)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BagDashboardRadius.sm),
              ),
            ),
            icon: Icon(icon, size: 15),
            label: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          )
        : ElevatedButton.icon(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: color,
              disabledForegroundColor: Colors.white,
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BagDashboardRadius.sm),
              ),
            ),
            icon: Icon(icon, size: 15),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );

    return SizedBox(
      height: 44, // ≥44 logical px tap target
      child: Pressable(haptic: haptic, onTap: onTap, child: content),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final BagRegistrationController controller;

  const _EmptyState({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 1.0),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 52,
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: BagDashboardSpacing.xxl),
            const Text(
              'No Bags Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: BagDashboardSpacing.sm),
            const Text(
              'Tap "Open New Bag" below to scan\na bag and start collecting samples.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loading skeleton ──────────────────────────────────────────────────────────

/// Shimmering placeholder shaped like the real content, shown while the
/// dashboard's initial data is loading — replaces the bare spinner.
