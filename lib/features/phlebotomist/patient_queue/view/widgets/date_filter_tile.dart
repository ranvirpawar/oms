import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../theme/app_colors.dart';
import 'queue_calendar_sheet.dart';
import 'queue_date_filter.dart';

// Shared layout constants for the popover.
const double _kMenuWidth = 200;
const double _kMenuGap = 6; // space between tile and menu
const double _kScreenMargin = 12; // minimum distance from any screen edge

class DateFilterTile extends StatefulWidget {
  final QueueDateFilter active;
  final DateTimeRange? customRange;

  final ValueChanged<QueueDateFilter> onChanged;
  final ValueChanged<DateTimeRange> onCustomRangeSelected;

  const DateFilterTile({
    super.key,
    required this.active,
    required this.customRange,
    required this.onChanged,
    required this.onCustomRangeSelected,
  });

  @override
  State<DateFilterTile> createState() => _DateFilterTileState();
}

class _DateFilterTileState extends State<DateFilterTile>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  OverlayEntry? _entry;
  late final AnimationController _anim;

  bool get _isOpen => _entry != null;

  // padding (6*2) + items (~38 each, presets + "Pick Date") + divider (9).
  // Only used to decide whether to open downward or flip upward; the layout
  // delegate still clamps to the real measured size.
  double get _estimatedMenuHeight =>
      12 + (QueueDateFilterX.presets.length + 1) * 38.0 + 9;

  String get _displayLabel {
    if (widget.active == QueueDateFilter.custom && widget.customRange != null) {
      final range = widget.customRange!;
      final start = range.start;
      final end = range.end;
      final sameDay = start.year == end.year &&
          start.month == end.month &&
          start.day == end.day;
      if (sameDay) return DateFormat('MMM d').format(start);
      final startLabel = DateFormat('MMM d').format(start);
      final endLabel = DateFormat('MMM d').format(end);
      return '$startLabel – $endLabel';
    }
    return widget.active.label;
  }

  IconData get _displayIcon => widget.active == QueueDateFilter.custom
      ? Icons.calendar_month_rounded
      : widget.active.icon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // No setState here — the widget is going away.
    _entry?.remove();
    _entry = null;
    _anim.dispose();
    super.dispose();
  }

  // The menu position is computed once when it opens, so if the screen
  // changes under it (rotation, keyboard, split-screen) just close it.
  @override
  void didChangeMetrics() {
    if (_isOpen) _removeOverlay(animate: false);
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    _isOpen ? _removeOverlay() : _showOverlay();
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final tileBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null || tileBox == null || !tileBox.attached) return;

    // Tile rect in the overlay's coordinate space.
    final anchor = tileBox.localToGlobal(Offset.zero, ancestor: overlayBox) &
    tileBox.size;

    // Decide whether the menu fits below the tile, otherwise flip above.
    final media = MediaQuery.of(context);
    final bottomInset =
    math.max(media.padding.bottom, media.viewInsets.bottom);
    final spaceBelow =
        overlayBox.size.height - bottomInset - _kScreenMargin - anchor.bottom;
    final spaceAbove = anchor.top - media.padding.top - _kScreenMargin;
    final needed = _estimatedMenuHeight + _kMenuGap;
    final openUp = spaceBelow < needed && spaceAbove > spaceBelow;

    _entry = OverlayEntry(
      builder: (_) => _DateFilterMenu(
        anchor: anchor,
        openUp: openUp,
        anim: _anim,
        active: widget.active,
        onSelect: (value) {
          HapticFeedback.selectionClick();
          widget.onChanged(value);
          _removeOverlay();
        },
        onPickDate: _openCalendar,
        onDismiss: _removeOverlay,
      ),
    );
    overlay.insert(_entry!);
    _anim.forward(from: 0);
    setState(() {});
  }

  void _removeOverlay({bool animate = true}) {
    if (_entry == null) return;
    if (!animate) {
      _entry!.remove();
      _entry = null;
      // Rebuild so the tile drops its "open" styling immediately.
      if (mounted) setState(() {});
      return;
    }
    _anim.reverse().then((_) {
      _entry?.remove();
      _entry = null;
      if (mounted) setState(() {});
    });
  }

  void _openCalendar() {
    // Close the popover without waiting for its exit animation — sliding
    // straight into the sheet reads as one continuous motion rather than
    // two separate overlays stacking on top of each other.
    _removeOverlay(animate: false);
    QueueCalendarSheet.show(
      context,
      initialRange: widget.customRange,
      onSelect: widget.onCustomRangeSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _isOpen ? AppColors.blueLight : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isOpen
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _displayIcon,
              size: 15,
              color: _isOpen ? AppColors.blueText : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            // Flexible + ellipsis so a long custom range or a large text
            // scale can't push the tile past its parent's bounds.
            Flexible(
              child: Text(
                _displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isOpen ? AppColors.blueText : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 2),
            AnimatedRotation(
              turns: _isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: _isOpen ? AppColors.blueText : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Places the menu right-aligned to the tile, below it (or above when
/// [openUp]), then clamps the result so it never leaves the safe area.
class _MenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Rect anchor;
  final EdgeInsets safe;
  final bool openUp;

  const _MenuLayoutDelegate({
    required this.anchor,
    required this.safe,
    required this.openUp,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can never be wider/taller than the usable screen area.
    return BoxConstraints(
      maxWidth: math.max(
        0,
        constraints.maxWidth - safe.horizontal - _kScreenMargin * 2,
      ),
      maxHeight: math.max(
        0,
        constraints.maxHeight - safe.vertical - _kScreenMargin * 2,
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Horizontal: right edge of the menu lines up with the tile's right edge.
    final minX = safe.left + _kScreenMargin;
    final maxX = math.max(
      minX,
      size.width - safe.right - _kScreenMargin - childSize.width,
    );
    final x = (anchor.right - childSize.width).clamp(minX, maxX).toDouble();

    // Vertical: below the tile, or above when there isn't room.
    final minY = safe.top + _kScreenMargin;
    final maxY = math.max(
      minY,
      size.height - safe.bottom - _kScreenMargin - childSize.height,
    );
    final preferredY = openUp
        ? anchor.top - _kMenuGap - childSize.height
        : anchor.bottom + _kMenuGap;
    final y = preferredY.clamp(minY, maxY).toDouble();

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayoutDelegate old) =>
      anchor != old.anchor || safe != old.safe || openUp != old.openUp;
}

class _DateFilterMenu extends StatelessWidget {
  final Rect anchor;
  final bool openUp;
  final AnimationController anim;
  final QueueDateFilter active;
  final ValueChanged<QueueDateFilter> onSelect;
  final VoidCallback onPickDate;
  final VoidCallback onDismiss;

  const _DateFilterMenu({
    required this.anchor,
    required this.openUp,
    required this.anim,
    required this.active,
    required this.onSelect,
    required this.onPickDate,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: anim,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    final media = MediaQuery.of(context);
    final safe = media.padding.copyWith(
      bottom: math.max(media.padding.bottom, media.viewInsets.bottom),
    );

    // Scale from the corner nearest the tile so the popover appears to grow
    // out of it (also correct when flipped above or clamped to the left).
    final clampedLeft = anchor.right - _kMenuWidth < safe.left + _kScreenMargin;
    final scaleOrigin = Alignment(
      clampedLeft ? -1 : 1,
      openUp ? 1 : -1,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        CustomSingleChildLayout(
          delegate: _MenuLayoutDelegate(
            anchor: anchor,
            safe: safe,
            openUp: openUp,
          ),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: curved.drive(Tween(begin: 0.9, end: 1.0)),
              alignment: scaleOrigin,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: _kMenuWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  // Scrolls only if the menu is taller than the screen
                  // (landscape, small devices, large text scale).
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...QueueDateFilterX.presets.map(
                              (filter) => _MenuItem(
                            icon: filter.icon,
                            label: filter.label,
                            selected: filter == active,
                            onTap: () => onSelect(filter),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Divider(height: 1, color: AppColors.border),
                        ),
                        _MenuItem(
                          icon: Icons.calendar_month_rounded,
                          label: 'Pick Date',
                          selected: active == QueueDateFilter.custom,
                          onTap: onPickDate,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueLight : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.blueText : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.blueText : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 16, color: AppColors.blueText),
          ],
        ),
      ),
    );
  }
}