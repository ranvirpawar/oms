// tap_position_menu.dart
//
// Reusable "open where tapped, close smoothly" context menu.
// Works like the Apple-style popover: appears anchored near the tap
// point, animates in with a soft scale+fade, and dismisses (animating
// out first) on outside tap or after an item is selected.
//
// Usage:
//   TapPositionMenu.show(
//     context: context,
//     tapPosition: details.globalPosition,
//     items: [
//       TapMenuItem(
//         icon: Icons.remove_circle_outline_rounded,
//         label: 'Sample cannot be collected',
//         isDestructive: true,
//         onTap: () => controller.markAsNotCollected(entry),
//       ),
//     ],
//   );

import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';

class TapMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const TapMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

class TapPositionMenu {
  TapPositionMenu._();

  static _TapPositionMenuOverlayState? _openState;
  static OverlayEntry? _entry;

  /// Shows the menu anchored at [tapPosition] (global coordinates).
  static Future<void> show({
    required BuildContext context,
    required Offset tapPosition,
    required List<TapMenuItem> items,
    double menuWidth = 240,
  }) async {
    // Only one menu open at a time.
    await dismiss();

    final overlay = Overlay.of(context);
    final key = GlobalKey<_TapPositionMenuOverlayState>();

    final entry = OverlayEntry(
      builder: (_) => _TapPositionMenuOverlay(
        key: key,
        tapPosition: tapPosition,
        items: items,
        menuWidth: menuWidth,
        onRequestClose: dismiss,
      ),
    );

    _entry = entry;
    overlay.insert(entry);
    _openState = key.currentState;
  }

  /// Animates the current menu out (if any) and removes it.
  static Future<void> dismiss() async {
    final state = _openState;
    final entry = _entry;
    _openState = null;
    _entry = null;
    if (state != null && entry != null) {
      await state.animateOutAndRemove(entry);
    } else {
      entry?.remove();
    }
  }
}

class _TapPositionMenuOverlay extends StatefulWidget {
  final Offset tapPosition;
  final List<TapMenuItem> items;
  final double menuWidth;
  final Future<void> Function() onRequestClose;

  const _TapPositionMenuOverlay({
    super.key,
    required this.tapPosition,
    required this.items,
    required this.menuWidth,
    required this.onRequestClose,
  });

  @override
  State<_TapPositionMenuOverlay> createState() =>
      _TapPositionMenuOverlayState();
}

class _TapPositionMenuOverlayState extends State<_TapPositionMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _controller.forward();
  }

  Future<void> animateOutAndRemove(OverlayEntry entry) async {
    if (!mounted) {
      entry.remove();
      return;
    }
    await _controller.reverse();
    entry.remove();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final menuHeight = widget.items.length * 46.0 + 16;

    // Anchor so the menu's top-right sits near the tapped button,
    // flipping to stay on-screen.
    double left = widget.tapPosition.dx - widget.menuWidth + 24;
    if (left + widget.menuWidth > screenSize.width - 12) {
      left = screenSize.width - widget.menuWidth - 12;
    }
    if (left < 12) left = 12;

    final openUpward =
        widget.tapPosition.dy + menuHeight > screenSize.height - 24;
    final top = openUpward
        ? widget.tapPosition.dy - menuHeight - 8
        : widget.tapPosition.dy + 8;

    return Stack(
      children: [
        // Invisible barrier — tapping outside closes the menu.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onRequestClose(),
            child: const SizedBox.shrink(),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              alignment:
              openUpward ? Alignment.bottomRight : Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: widget.menuWidth,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.items
                        .map(
                          (item) => _MenuTile(
                        item: item,
                        onSelected: () async {
                          await widget.onRequestClose();
                          item.onTap();
                        },
                      ),
                    )
                        .toList(),
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

class _MenuTile extends StatelessWidget {
  final TapMenuItem item;
  final VoidCallback onSelected;

  const _MenuTile({required this.item, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final color = item.isDestructive ? AppColors.redText : AppColors.textPrimary;
    return InkWell(
      onTap: onSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(item.icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}