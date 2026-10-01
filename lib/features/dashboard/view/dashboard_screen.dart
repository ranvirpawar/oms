import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/dashboard/dashboard_controller/dashboard_controller.dart';
import 'package:lifenity_connect/features/dashboard/view/widget/dashboard_tile_card.dart';
import 'package:lifenity_connect/features/dashboard/view/widget/runner_action.dart';
import 'package:lifenity_connect/utils/ui_designs/liquid_snackbar.dart';
import 'package:lifenity_connect/utils/widgets/app_drawer.dart';

import 'package:intl/intl.dart';
import '../../../services/auth_manager.dart';
import '../../phlebotomist/patient_queue/view/widgets/queue_calendar_sheet.dart';
import '../../../theme/app_colors.dart';

import 'package:flutter/services.dart';

import 'widget/dashboard_metrics_strip.dart';
import 'widget/dashboard_stats_shimmer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final DashboardController controller = Get.put(DashboardController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  static const _bg = Color(0xFFF6F7FB);
  static const _ink = Color(0xFF161A2B);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Identity helpers ────────────────────────────────────────────────────
  String get _greetingTitle {
    final name = controller.userName.value;
    final first = name.trim().isNotEmpty ? name.trim().split(' ').first : '';
    return first.isNotEmpty ? 'Hi, $first' : 'Hi there';
  }

  String get _dateLabel {
    final range = controller.selectedRange.value;
    if (DateUtils.isSameDay(range.start, range.end)) {
      return DateFormat('EEE, d MMM yyyy').format(range.start);
    }
    return '${DateFormat('d MMM yy').format(range.start)} – ${DateFormat('d MMM yy').format(range.end)}';
  }

  void _openCalendar() {
    QueueCalendarSheet.show(
      context,
      initialRange: controller.selectedRange.value,
      confirmLabel: 'Show Stats',
      onSelect: controller.selectDateRange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        // adjust to your content height
        child: _buildAppBar(),
      ),
      drawer: CustomDrawer(controller: controller),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Fixed header — never scrolls away.
                // _buildAppBar(),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildAvailabilityPill(),
                ),
                const SizedBox(height: 16),

                // Scrollable content below the fold.
                Expanded(
                  child: RefreshIndicator(
                    color: cs.primary,
                    onRefresh: controller.refreshDashboardStats,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        18, 0, 18,
                        controller.userRole.value == UserRole.runnerBoy ? 100 : 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() {
                            final items = controller.getRoleBasedMetrics();
                            if (items.isEmpty &&
                                !controller.isLoadingStats.value &&
                                controller.statsError.value.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (controller.isLoadingStats.value)
                                  DashboardStatsShimmer(itemCount: items.isEmpty ? 4 : items.length)
                                else if (controller.statsError.value.isNotEmpty)
                                  Text(
                                    controller.statsError.value,
                                    style: TextStyle(color: cs.error),
                                  )
                                else
                                  DashboardMetricsStrip(
                                    items: items,
                                    animationBuilder: (child) =>
                                        _FadeSlideIn(index: 0, child: child),
                                  ),
                                const SizedBox(height: 26),
                              ],
                            );
                          }),
                          _sectionLabel(cs, 'Quick Actions'),
                          const SizedBox(height: 14),
                          Obx(() {
                            if (controller.userRole.value == null) {
                              return const _ShimmerGrid();
                            }
                            final cards = controller.getRoleBasedStatCards();
                            return _DashboardGrid(
                              cards: cards,
                              controller: controller,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Obx(() => controller.userRole.value == UserRole.runnerBoy
                ? RunnerActionFab(actions: controller.getRunnerQuickActions())
                : const SizedBox.shrink()),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _GlassIconButton(
              icon: Icons.menu_rounded,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => Text(
                      _greetingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 2),
                  Obx(
                    () => Semantics(
                      button: true,
                      label: 'Select dashboard date range',
                      child: InkWell(
                        onTap: _openCalendar,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          // color: Colors.red,
                          constraints: const BoxConstraints(minHeight: 24),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _dateLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.expand_more_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _GlassIconButton(
              icon: Icons.notifications_none_rounded,
              showDot: true,
              onTap: () => LiquidSnack.info('coming soon'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Availability pill ──────────────────────────────────────────────────
  Widget _buildAvailabilityPill() {
    return _PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        controller.toggleAvailability();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Obx(() {
          final available = controller.isAvailable.value;
          return Row(
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) {
                  final scale = available ? 1.0 + (_pulse.value * 0.4) : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: available
                        ? const Color(0xFF22C55E) // Green for Punch In
                        : Colors.orange, // Orange for Punch Out
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  available ? 'Punch In' : 'Punch Out',
                  key: ValueKey(available),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: available
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: available
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFBBF7D0),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      available ? Icons.logout_rounded : Icons.login_rounded,
                      size: 13,
                      color: available
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      available ? 'Punch Out' : 'Punch In',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: available
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _sectionLabel(ColorScheme cs, String text) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 18,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ── Grid wrapper around the existing DashboardTileCard ──────────────────
class _DashboardGrid extends StatelessWidget {
  final List<DashboardTileCard> cards;
  final DashboardController controller;

  const _DashboardGrid({required this.cards, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        final tile = DashboardTileCard(
          variant: card.variant,
          title: card.title,
          icon: card.icon,
          onTap: card.onTap,
          borderColor: card.borderColor,
          backgroundImage: card.backgroundImage,
          isNetworkImage: card.isNetworkImage,
          labelBandFraction: card.labelBandFraction,
          bannerText: card.bannerText,
          subtitle: card.subtitle,
          iconRight: card.iconRight,
          iconLeft: card.iconLeft,
          iconBottom: card.iconBottom,
          iconTop: card.iconTop,
        );

        return _FadeSlideIn(index: index + 1, child: tile);
      },
    );
  }
}

// ── Loading skeleton for the grid ────────────────────────────────────────
class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.94,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// ── Small reusable pieces ────────────────────────────────────────────────

/// Generic press-scale wrapper — every tappable surface in this screen
/// reacts physically rather than relying on a bare ripple.
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const _PressableScale({
    required this.child,
    this.onTap,
    this.scaleDown = 0.97,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              HapticFeedback.lightImpact();
              widget.onTap!();
            },
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Cheap staggered entrance (fade + rise) without adding a new dependency —
/// duration is offset per index so items settle one after another.
class _FadeSlideIn extends StatelessWidget {
  final int index;
  final Widget child;

  const _FadeSlideIn({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delayMs = index.clamp(0, 8) * 60;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ── Glass icon button, matching CustomAppBar's frosted-glass surfaces ──
class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.30),
                  width: 1,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 20),
                  if (widget.showDot)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF5B5B),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
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
