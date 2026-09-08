import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/dashboard/dashboard_controller/dashboard_controller.dart';
import 'package:lifenity_connect/features/dashboard/view/widget/dashboard_header.dart';
import 'package:lifenity_connect/features/dashboard/view/widget/dashboard_tile_card.dart';
import 'package:lifenity_connect/utils/ui_designs/liquid_snackbar.dart';
import 'package:lifenity_connect/utils/widgets/app_drawer.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../constants/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/widgets/liw.dart';

// dashboard_screen.dart
//
// Revamped dashboard: fixed (non-scrolling) app bar + availability pill,
// a compact elevated metrics card, and a separate grid widget wrapping the
// existing DashboardTileCard. No bottom nav bar here — that lives in the
// outer navigation shell.
//
// Assumes these already exist in your project (unchanged):
//   DashboardController, DashboardTileCard, CustomDrawer,
//   AppStrings, AppAssets, RouteManager

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final DashboardController controller = Get.put(DashboardController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final LayerLink _pillLink = LayerLink();

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  OverlayEntry? _dropdownEntry;
  bool _pillExpanded = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onDashboardBuild();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _removeDropdown();
    super.dispose();
  }

  // ── Dropdown plumbing ──────────────────────────────────────────────────
  void _togglePillDropdown() {
    if (_pillExpanded) {
      _removeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    final overlay = Overlay.of(context);
    _dropdownEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeDropdown,
            ),
          ),
          CompositedTransformFollower(
            link: _pillLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 58),
            child: Align(
              alignment: Alignment.topLeft,
              child: _buildPillDropdown(),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_dropdownEntry!);
    setState(() => _pillExpanded = true);
  }

  void _removeDropdown() {
    _dropdownEntry?.remove();
    _dropdownEntry = null;
    if (mounted) setState(() => _pillExpanded = false);
  }

  // ── Identity helpers ────────────────────────────────────────────────────
  String get _greetingTitle {
    final name = controller.userName.value;
    final first = name.trim().isNotEmpty ? name.trim().split(' ').first : '';
    return first.isNotEmpty ? 'Hi, $first' : 'Hi there';
  }

  String get _todayLabel {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // adjust to your content height
        child: _buildAppBar(),
      ),
      drawer: CustomDrawer(controller: controller),
      body: SafeArea(
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
                onRefresh: () async {
                  controller.refreshBagCount();
                  controller.refreshDashboardStats();
                  await Future.delayed(const Duration(milliseconds: 400));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => _buildStatsCard()),
                      const SizedBox(height: 26),
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
                  const SizedBox(height: 2),
                  Text(
                    _todayLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _GlassIconButton(
              icon: Icons.notifications_none_rounded,
              showDot: true,
              onTap: () => LiquidSnack.info('comming soon'),
            ),
          ],
        ),
      ),
    );
  }
 /* Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
      child: Row(
        children: [
          _IconSquareButton(
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
                      color: _ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _todayLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _IconSquareButton(
            icon: Icons.notifications_none_rounded,
            showDot: true,
            onTap: () {
              LiquidSnack.info('comming soon');
            },
          ),
        ],
      ),
    );
  }*/

  // ── Availability pill (existing behaviour, fixed position) ────────────
  Widget _buildAvailabilityPill() {
    return CompositedTransformTarget(
      link: _pillLink,
      child: _PressableScale(
        onTap: _togglePillDropdown,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    available ? 'Online' : 'Offline',
                    key: ValueKey(available),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 1,
                  height: 16,
                  color: Colors.black.withOpacity(0.1),
                ),
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF3B82F6),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    controller.currentLocation.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.65),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _pillExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPillDropdown() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => _DropdownAction(
                icon: controller.isAvailable.value
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                label: controller.isAvailable.value
                    ? 'Go offline'
                    : 'Go online',
                onTap: () {
                  controller.toggleAvailability();
                  _removeDropdown();
                },
              ),
            ),
            Divider(height: 1, color: Colors.black.withOpacity(0.06)),
            _DropdownAction(
              icon: Icons.my_location_rounded,
              label: 'Refresh location',
              onTap: () {
                controller.refreshLocation();
                _removeDropdown();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Compact elevated metrics card ──────────────────────────────────────
  Widget _buildStatsCard() {
    final items = <_MetricData>[
      _MetricData(
        value: controller.assignedPatientsCount.value.toString().padLeft(
          2,
          '0',
        ),
        label: 'Assigned\nPatients',
        icon: Icons.people_alt_rounded,
        dot: const Color(0xFF3B82F6),
      ),
      _MetricData(
        value: controller.testCollectedCount.value.toString().padLeft(2, '0'),
        label: 'Clinic Collections',
        icon: Icons.science_rounded,
        dot: const Color(0xFF22C55E),
      ),
      _MetricData(
        value: controller.handoverCount.value.toString().padLeft(2, '0'),
        label: 'Home Requests',
        icon: Icons.swap_horiz_rounded,
        dot: const Color(0xFF8B5CF6),
      ),
      _MetricData(
        value: controller.pendingHandoverCount.value.toString().padLeft(2, '0'),
        label: 'Pending\nHandover',
        icon: Icons.hourglass_bottom_rounded,
        dot: const Color(0xFFF59E0B),
      ),
    ];

    return _FadeSlideIn(
      index: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Container(
                width: 1,
                height: 40,
                color: Colors.black.withOpacity(0.07),
              );
            }
            return Expanded(child: _MetricCell(data: items[i ~/ 2]));
          }),
        ),
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
        final isBagCard =
            card.title == AppStrings.collectedSampleBags ||
            card.title == 'Collected Bags';

        final tile = isBagCard
            ? Obx(() {
                final count = controller.collectedBagsCount.value;
                final banner = count > 0
                    ? '🧪  $count ${count == 1 ? 'bag' : 'bags'} with you  •  Submit to lab or hand over'
                    : null;
                return DashboardTileCard(
                  variant: DashboardTileVariant.grid,
                  title: card.title,
                  icon: card.icon,
                  onTap: card.onTap,
                  borderColor: card.borderColor,
                  backgroundImage: card.backgroundImage,
                  isNetworkImage: card.isNetworkImage,
                  labelBandFraction: card.labelBandFraction,
                  bannerText: banner,
                );
              })
            : DashboardTileCard(
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
class _MetricData {
  final String value;
  final String label;
  final IconData icon;
  final Color dot;

  _MetricData({
    required this.value,
    required this.label,
    required this.icon,
    required this.dot,
  });
}

class _MetricCell extends StatelessWidget {
  final _MetricData data;

  const _MetricCell({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.dot,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                data.value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF161A2B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /*Icon(data.icon, size: 14, color: Colors.black.withOpacity(0.4)),
              const SizedBox(width: 4),*/
              Expanded(
                child: Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: Colors.black.withOpacity(0.5),
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

class _DropdownAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DropdownAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      scaleDown: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black.withOpacity(0.65)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF161A2B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _IconSquareButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      scaleDown: 0.93,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF161A2B)),
            if (showDot)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEF4444),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
/*class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F1A)
          : const Color(0xFFF5F6FA),

      drawer: CustomDrawer(controller: controller),

      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshBagCount();
          controller.refreshDashboardStats();
        },
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            DashboardHeaderSliver(controller: controller, topPadding: topPad),

            // ── Section Label ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 14),
                child: Row(
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
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withOpacity(0.85)
                            : cs.onSurface,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Cards ──────────────────────────────────────────────────────
            Obx(() {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.onDashboardBuild();
              });

              if (controller.userRole.value == null) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverToBoxAdapter(
                    child: _ShimmerGrid(isDark: isDark, cs: cs),
                  ),
                );
              }

              final cards = controller.getRoleBasedStatCards();

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: _GridSliver(cards: cards, controller: controller),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 500)),

          ],
        ),
      ),
    );
  }
}

class _GridSliver extends StatelessWidget {
  final List<DashboardTileCard> cards;
  final DashboardController controller;

  const _GridSliver({required this.cards, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        final card = cards[index];
        final isBagCard =
            card.title == AppStrings.collectedSampleBags ||
            card.title == 'Collected Bags';
        /// it for only runnerboy so our phlebo car
        if (isBagCard) {
          return Obx(() {
            final count = controller.collectedBagsCount.value;
            final banner = count > 0
                ? '🧪  $count ${count == 1 ? 'bag' : 'bags'} with you  •  Submit to lab or hand over          '
                : null;

            return DashboardTileCard(
              title: card.title,
              icon: card.icon,
              onTap: card.onTap,
              borderColor: card.borderColor,
              backgroundImage: card.backgroundImage,
              isNetworkImage: card.isNetworkImage,
              labelBandFraction: card.labelBandFraction,
              bannerText: banner,
            );
          });
        }

        return DashboardTileCard(
          title: card.title,
          icon: card.icon,
          onTap: card.onTap,
          borderColor: card.borderColor,
          backgroundImage: card.backgroundImage,
          isNetworkImage: card.isNetworkImage,
          labelBandFraction: card.labelBandFraction,
          bannerText: card.bannerText,
        );
      }, childCount: cards.length),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
    );
  }
}*/

class _WelcomeCard extends StatelessWidget {
  final DashboardController controller;
  final bool isDark;
  final ColorScheme cs;

  const _WelcomeCard({
    required this.controller,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    // ── Neumorphic palette (same as tile cards for consistency) ──────────────
    final neuBase = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFECEFF4);
    final neuLight = isDark ? const Color(0xFF2C2C40) : Colors.white;
    final neuDark = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFC8CBD6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: neuBase,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          // Top-left highlight
          BoxShadow(
            color: neuLight.withOpacity(isDark ? 0.12 : 1.0),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
          // Bottom-right shadow
          BoxShadow(
            color: neuDark.withOpacity(isDark ? 0.75 : 0.55),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Neumorphic avatar ──────────────────────────────────────────────
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary.withOpacity(0.85), cs.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.35),
                  offset: const Offset(3, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Obx(() {
                final name = controller.userName.value;
                final initials = name.trim().isNotEmpty
                    ? name
                          .trim()
                          .split(' ')
                          .where((p) => p.isNotEmpty)
                          .take(2)
                          .map((p) => p[0].toUpperCase())
                          .join()
                    : '?';
                return Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 14),

          // ── Text ──────────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final name = controller.userName.value;
              final first = name.isNotEmpty ? name.trim().split(' ').first : '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    first.isNotEmpty
                        ? 'Hello, $first!'
                        : AppStrings.welcomeToLifenity,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white.withOpacity(0.9)
                          : const Color(0xFF2D3142),
                      height: 1.2,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.welcomeToLifenity,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Colors.white.withOpacity(0.38)
                          : const Color(0xFF2D3142).withOpacity(0.45),
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }),
          ),

          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/*class _ShimmerGrid extends StatefulWidget {
  final bool isDark;
  final ColorScheme cs;

  const _ShimmerGrid({required this.isDark, required this.cs});

  @override
  State<_ShimmerGrid> createState() => _ShimmerGridState();
}

class _ShimmerGridState extends State<_ShimmerGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark
        ? Colors.white.withOpacity(0.05)
        : widget.cs.surfaceContainerHighest.withOpacity(0.4);
    final shine = widget.isDark
        ? Colors.white.withOpacity(0.1)
        : widget.cs.surfaceContainerHighest.withOpacity(0.75);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.0,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value, 0),
              colors: [base, shine, base],
            ),
          ),
        ),
      ),
    );
  }
}*/

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
// ── App bar ───────────────────