// dashboard_header.dart
//
// v5 — fixes "SliverGeometry ... layoutExtent exceeds paintExtent" crash
// for good (not just for the dropdown case).
//
// ROOT CAUSE:
//   SliverPersistentHeaderDelegate.maxExtent was a hand-guessed constant
//   (kHeaderExpandedExtra = 268). The actual header content (pill row +
//   stats row + notice ticker) was laid out with mainAxisSize.min and NO
//   hard ceiling on its height, so on real devices/fonts/text-scale it
//   simply needed more room than the constant promised. The sliver ends
//   up with a real layoutExtent bigger than the paintExtent it promised
//   the viewport → hard crash. (v4 additionally fixed a *related* bug
//   where opening the dropdown pill grew the content further — that fix
//   is still included below — but it was never the whole story.)
//
// FIX (two layers, so this class of bug is now structurally impossible):
//   1. MEASURE, DON'T GUESS. `DashboardHeaderSliver` (the new public
//      entry point — use this instead of building SliverPersistentHeader
//      yourself) measures the real natural height of the collapsible
//      content after every frame via a GlobalKey, and feeds that back in
//      as `expandedExtra`. The sliver's maxExtent therefore always
//      matches what the content actually needs, on any device/font
//      scale/data length.
//   2. HARD SAFETY CLAMP. The delegate still forces its returned widget
//      into an exact `SizedBox(height: currentExtent)` + `ClipRect`. If
//      a measurement is ever stale for a single frame (e.g. right after
//      data changes), the worst case is a harmless clipped frame — never
//      a SliverGeometry assertion.
//
// Usage in DashboardScreen — replace the old raw SliverPersistentHeader
// with the self-contained widget below:
//
//   final topPad = MediaQuery.of(context).padding.top;
//   DashboardHeaderSliver(
//     controller: controller,
//     topPadding: topPad,
//   ),
//
// (DashboardHeaderSliver returns a SliverPersistentHeader internally, so
// it drops straight into CustomScrollView's `slivers: [...]` list exactly
// like the old one did.)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../dashboard_controller/dashboard_controller.dart';

// ── Tunable sizes ────────────────────────────────────────────────────────────

const double kHeaderCompactHeight = 56; // sticky bar height (excl. safe area)
const double kHeaderExpandedExtraFallback = 268;

class DashboardHeaderSliver extends StatefulWidget {
  final DashboardController controller;
  final double topPadding;

  const DashboardHeaderSliver({
    super.key,
    required this.controller,
    required this.topPadding,
  });

  @override
  State<DashboardHeaderSliver> createState() => _DashboardHeaderSliverState();
}

class _DashboardHeaderSliverState extends State<DashboardHeaderSliver> {
  double _expandedExtra = kHeaderExpandedExtraFallback;

  void _handleContentMeasured(double measuredHeight) {
    // Clamp to a sane range so a transient bad measurement (e.g. during
    // a hot-reload frame) can't produce a huge or negative extent.
    final target = measuredHeight.clamp(40.0, 700.0);
    if ((target - _expandedExtra).abs() > 0.5) {
      // Never call setState mid-layout/mid-build — defer to next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _expandedExtra = target);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: DashboardHeaderDelegate(
        controller: widget.controller,
        topPadding: widget.topPadding,
        expandedExtra: _expandedExtra,
        onContentMeasured: _handleContentMeasured,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Persistent header delegate — drives the collapse from scroll offset
// ─────────────────────────────────────────────────────────────────────────────

class DashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DashboardController controller;
  final double topPadding;
  final double expandedExtra;
  final ValueChanged<double> onContentMeasured;

  DashboardHeaderDelegate({
    required this.controller,
    required this.topPadding,
    required this.expandedExtra,
    required this.onContentMeasured,
  });

  @override
  double get minExtent => kHeaderCompactHeight + topPadding;

  @override
  double get maxExtent => minExtent + expandedExtra;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final progress = range > 0 ? (shrinkOffset / range).clamp(0.0, 1.0) : 1.0;
    final currentExtent = (maxExtent - shrinkOffset).clamp(
      minExtent,
      maxExtent,
    );

    // Hard safety net: force the returned box to EXACTLY the height the
    // sliver promised the viewport, no matter what the content inside
    // wants. Combined with the measurement feedback above, this makes
    // the SliverGeometry crash structurally impossible — worst case is
    // one harmless clipped frame instead of an assertion failure.
    return SizedBox(
      height: currentExtent,
      child: ClipRect(
        child: _DashboardHeaderContent(
          controller: controller,
          progress: progress,
          topPadding: topPadding,
          onContentMeasured: onContentMeasured,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant DashboardHeaderDelegate oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.expandedExtra != expandedExtra;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header content — same State persists across scroll-driven rebuilds
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHeaderContent extends StatefulWidget {
  final DashboardController controller;
  final double progress; // 0 = fully expanded, 1 = fully collapsed
  final double topPadding;
  final ValueChanged<double> onContentMeasured;

  const _DashboardHeaderContent({
    required this.controller,
    required this.progress,
    required this.topPadding,
    required this.onContentMeasured,
  });

  @override
  State<_DashboardHeaderContent> createState() =>
      _DashboardHeaderContentState();
}

class _DashboardHeaderContentState extends State<_DashboardHeaderContent>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;

  // ── Popover plumbing (dropdown lives OUTSIDE the sliver layout) ─────────
  final LayerLink _pillLink = LayerLink();
  OverlayEntry? _dropdownEntry;
  bool _pillExpanded = false;
  bool _isDarkCached = false;

  // Wraps the collapsible content (pill + stats + ticker) purely so we can
  // read its real, natural height after layout and report it upward —
  // this is what lets the sliver's maxExtent match reality instead of a
  // guessed constant.
  final GlobalKey _contentKey = GlobalKey();

  void _measureContent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox =
          _contentKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        widget.onContentMeasured(renderBox.size.height);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _removeDropdown();
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double start, double end) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(start, end, curve: Curves.easeOutCubic),
  );

  // ── Popover open/close ───────────────────────────────────────────────────

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
      builder: (ctx) {
        return Stack(
          children: [
            // Invisible barrier — tapping anywhere outside closes the popover.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeDropdown,
              ),
            ),
            CompositedTransformFollower(
              link: _pillLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 8),
              child: _PopoverEntrance(
                child: Material(
                  color: Colors.transparent,
                  child: _buildPillDropdown(_isDarkCached),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_dropdownEntry!);
    setState(() => _pillExpanded = true);
  }

  void _removeDropdown() {
    _dropdownEntry?.remove();
    _dropdownEntry = null;
    if (mounted) {
      setState(() => _pillExpanded = false);
    } else {
      _pillExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    _isDarkCached = isDark;
    final progress = widget.progress;

    // Collapsing the header while the popover is open would leave it
    // pointing at nothing — close it defensively.
    if (progress > 0.05 && _pillExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _removeDropdown());
    }

    // Re-measure every build. _measureContent() itself is cheap (it just
    // schedules a post-frame callback), and the parent only actually
    // setState()s if the measured height meaningfully changed, so this
    // settles after 1-2 frames and then goes quiet.
    _measureContent();

    final bg = isDark ? const Color(0xFF15151F) : const Color(0xFFF5F6FA);

    return Container(
      color: bg,
      // Hairline shadow appears only once content is tucked under the bar —
      // mirrors iOS nav bar picking up a divider on scroll.
      foregroundDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.06 * progress),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Sticky compact bar (always visible) ─────────────────────────
          SizedBox(
            height: kHeaderCompactHeight + widget.topPadding,
            child: Padding(
              padding: EdgeInsets.only(top: widget.topPadding),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Builder(
                    builder: (ctx) => _CircleIconButton(
                      icon: Icons.menu_rounded,
                      isDark: isDark,
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  // Always-visible name + "Your day at a glance" line —
                  // stays put through both expanded and collapsed states.
                  Expanded(
                    child: Center(
                      child: _CompactGreeting(controller: widget.controller),
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.notifications_none_rounded,
                    isDark: isDark,
                    onTap: () {},
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),

          // ── Collapsible content (fades + shrinks under the bar) ─────────
          // NOTE: this subtree's height is now fully deterministic (no
          // dropdown growth inside it), so it will never exceed maxExtent.
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: (1 - progress).clamp(0.0, 1.0),
              child: Opacity(
                opacity: (1 - progress * 1.4).clamp(0.0, 1.0),
                child: Padding(
                  key: _contentKey,
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Anchor for the floating popover — this widget's box
                      // never changes size when the dropdown opens.
                      CompositedTransformTarget(
                        link: _pillLink,
                        child: _buildAvailabilityPill(isDark),
                      ),
                      const SizedBox(height: 16),
                      _buildStatsRow(isDark),
                      /* const SizedBox(height: 14),
                      _NoticeTicker(controller: widget.controller),*/
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityPill(bool isDark) {
    final anim = _stagger(0.1, 0.55);
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: anim.drive(
          Tween(begin: const Offset(0, 0.2), end: Offset.zero),
        ),
        child: GestureDetector(
          onTap: _togglePillDropdown,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Obx(() {
              final available = widget.controller.isAvailable.value;
              return Align(alignment: Alignment.center,

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, child) {
                        final scale = available
                            ? 1.0 + (_pulse.value * 0.35)
                            : 1.0;
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
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1D2333),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 1,
                      height: 16,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.12,
                      ),
                    ),
                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF3B82F6),
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Obx(
                        () => Text(
                          widget.controller.currentLocation.value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withOpacity(0.85)
                                : const Color(0xFF1D2333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _pillExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPillDropdown(bool isDark) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
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
                icon: widget.controller.isAvailable.value
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                label: widget.controller.isAvailable.value
                    ? 'Go offline'
                    : 'Go online',
                isDark: isDark,
                onTap: () {
                  widget.controller.toggleAvailability();
                  _removeDropdown();
                },
              ),
            ),
            Divider(
              height: 1,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
            ),
            _DropdownAction(
              icon: Icons.my_location_rounded,
              label: 'Refresh location',
              isDark: isDark,
              onTap: () {
                widget.controller.refreshLocation();
                _removeDropdown();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final stats = <_StatItem>[
      _StatItem(
        icon: Icons.people_alt_rounded,
        label: 'Assigned\n(Patients)',
        valueGetter: () => widget.controller.assignedPatientsCount.value,
        color: const Color(0xFF3B82F6),
      ),
      _StatItem(
        icon: Icons.science_rounded,
        label: 'Sample\nCollected',
        valueGetter: () => widget.controller.testCollectedCount.value,
        color: const Color(0xFF14B8A6),
      ),
      _StatItem(
        icon: Icons.swap_horiz_rounded,
        label: 'Handover',
        valueGetter: () => widget.controller.handoverCount.value,
        color: const Color(0xFF8B5CF6),
      ),
      _StatItem(
        icon: Icons.hourglass_bottom_rounded,
        label: 'Pending\nHandover',
        valueGetter: () => widget.controller.pendingHandoverCount.value,
        color: const Color(0xFFF59E0B),
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(stats.length * 2 - 1, (i) {
          if (i.isOdd) return const SizedBox(width: 8);
          final idx = i ~/ 2;
          final start = 0.25 + (idx * 0.08);
          final end = (start + 0.5).clamp(0.0, 1.0);
          final anim = _stagger(start, end);
          return Expanded(
            child: FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: anim.drive(
                  Tween(begin: const Offset(0, 0.3), end: Offset.zero),
                ),
                child: _StatCard(item: stats[idx], isDark: isDark),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Popover entrance animation (fade + scale from top-left, like a native menu)
// ─────────────────────────────────────────────────────────────────────────────

class _PopoverEntrance extends StatefulWidget {
  final Widget child;

  const _PopoverEntrance({required this.child});

  @override
  State<_PopoverEntrance> createState() => _PopoverEntranceState();
}

class _PopoverEntranceState extends State<_PopoverEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    return FadeTransition(
      opacity: _ctrl,
      child: ScaleTransition(
        scale: Tween(begin: 0.9, end: 1.0).animate(curved),
        alignment: Alignment.topLeft,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact bar greeting (shown always — expanded AND collapsed)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactGreeting extends StatelessWidget {
  final DashboardController controller;

  const _CompactGreeting({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1D2333);

    return Obx(() {
      final name = controller.userName.value;
      final first = name.trim().isNotEmpty ? name.trim().split(' ').first : '';

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            first.isNotEmpty ? 'Hi, $first' : 'Welcome back',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            'Your day at a glance',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    });
  }
}

class _DropdownAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _DropdownAction({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1D2333),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat cards — compact style: small icon chip + value on one row, label below
// ─────────────────────────────────────────────────────────────────────────────

class _StatItem {
  final IconData icon;
  final String label; // may contain \n for a 2-line label
  final int Function() valueGetter;
  final Color color;

  _StatItem({
    required this.icon,
    required this.label,
    required this.valueGetter,
    required this.color,
  });
}

class _StatCard extends StatefulWidget {
  final _StatItem item;
  final bool isDark;

  const _StatCard({required this.item, required this.isDark});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;

    return Obx(() {
      final value = item.valueGetter();
      return GestureDetector(
        onTapDown: (_) => _tapCtrl.forward(),
        onTapUp: (_) => _tapCtrl.reverse(),
        onTapCancel: () => _tapCtrl.reverse(),
        child: AnimatedBuilder(
          animation: _tapCtrl,
          builder: (_, child) =>
              Transform.scale(scale: 1 - _tapCtrl.value, child: child),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1B27) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.color.withOpacity(0.5),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon chip + value share one compact row.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 12),
                    ),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: value),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) => Text(
                        val.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: item.color,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF3A3F4B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notice ticker — auto-rotating "new patient assigned" style banner
// ─────────────────────────────────────────────────────────────────────────────



// ─────────────────────────────────────────────────────────────────────────────
// Small shared bits
// ─────────────────────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? Colors.white.withOpacity(0.08) : AppColors.primary.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            icon,
            color: isDark ? Colors.white : AppColors.primary,
            size: 19,
          ),
        ),
      ),
    );
  }
}
