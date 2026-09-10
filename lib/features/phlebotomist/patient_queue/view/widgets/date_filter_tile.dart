import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../theme/app_colors.dart';
import 'queue_date_filter.dart';

/// Compact "tile" that shows the active date horizon (defaults to Today)
/// and opens a small anchored popover with the three forward-looking
/// options on tap. Deliberately not a full bottom sheet — three options
/// don't need one, and a quick popover keeps triage fast for someone
/// working through a live queue between visits.
class DateFilterTile extends StatefulWidget {
  final QueueDateFilter active;
  final ValueChanged<QueueDateFilter> onChanged;

  const DateFilterTile({
    super.key,
    required this.active,
    required this.onChanged,
  });

  @override
  State<DateFilterTile> createState() => _DateFilterTileState();
}

class _DateFilterTileState extends State<DateFilterTile>
    with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  bool get _isOpen => _entry != null;

  @override
  void dispose() {
    _removeOverlay(animate: false);
    _anim.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    _isOpen ? _removeOverlay() : _showOverlay();
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (_) => _DateFilterMenu(
        link: _link,
        anim: _anim,
        active: widget.active,
        onSelect: (value) {
          HapticFeedback.selectionClick();
          widget.onChanged(value);
          _removeOverlay();
        },
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
      _entry?.remove();
      _entry = null;
      return;
    }
    _anim.reverse().then((_) {
      _entry?.remove();
      _entry = null;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
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
              color: _isOpen ? AppColors.primary.withOpacity(0.4) : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.active.icon,
                size: 15,
                color: _isOpen ? AppColors.blueText : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.active.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isOpen ? AppColors.blueText : AppColors.textPrimary,
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
      ),
    );
  }
}

class _DateFilterMenu extends StatelessWidget {
  final LayerLink link;
  final AnimationController anim;
  final QueueDateFilter active;
  final ValueChanged<QueueDateFilter> onSelect;
  final VoidCallback onDismiss;

  const _DateFilterMenu({
    required this.link,
    required this.anim,
    required this.active,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: anim,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    return Stack(
      children: [
        // Invisible full-screen tap catcher to dismiss on outside tap.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          offset: const Offset(0, 46),
          child: Align(
            alignment: Alignment.topRight,
            child: FractionalTranslation(
              translation: const Offset(-1, 0), // right-align under the tile
              child: FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: curved.drive(Tween(begin: 0.9, end: 1.0)),
                  alignment: Alignment.topRight,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 190,
                      padding: const EdgeInsets.all(6),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: QueueDateFilter.values
                            .map((filter) => _MenuItem(
                                  filter: filter,
                                  selected: filter == active,
                                  onTap: () => onSelect(filter),
                                ))
                            .toList(),
                      ),
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
  final QueueDateFilter filter;
  final bool selected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.filter,
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
            Icon(filter.icon,
                size: 16, color: selected ? AppColors.blueText : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                filter.label,
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
