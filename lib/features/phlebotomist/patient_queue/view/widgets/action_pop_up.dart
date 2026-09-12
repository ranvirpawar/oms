import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../theme/app_colors.dart';

/// A small, anchor-positioned "are you sure?" confirmation popover.
///
/// Used for lightweight confirmations (currently just Accept) that
/// shouldn't interrupt the flow with a full-screen modal dialog. It shows
/// right next to the button that was tapped, flips above/below depending
/// on available space, and clamps horizontally so it always stays on
/// screen. Dismisses on outside tap or either action button.
class ActionConfirmPopover {
  ActionConfirmPopover._();

  static Future<bool> show(
      BuildContext context, {
        required GlobalKey anchorKey,
        required String message,
        String confirmLabel = 'Yes, accept',
        String cancelLabel = 'Cancel',
      }) async {
    final renderBox =
    anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return false;

    final overlay = Overlay.of(context);
    final screen = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;

    final anchorTopLeft = renderBox.localToGlobal(Offset.zero);
    final anchorSize = renderBox.size;
    final anchorCenterX = anchorTopLeft.dx + anchorSize.width / 2;

    const popoverWidth = 216.0;
    const estimatedHeight = 118.0;
    const gap = 10.0;
    const edgeMargin = 12.0;

    double left = anchorCenterX - popoverWidth / 2;
    left = left.clamp(edgeMargin, screen.width - popoverWidth - edgeMargin);

    // Prefer showing above the button; fall back to below if there isn't
    // enough room (e.g. the card sits near the top of the screen).
    final spaceAbove = anchorTopLeft.dy - topInset;
    final showAbove = spaceAbove > estimatedHeight + gap;
    final top = showAbove
        ? anchorTopLeft.dy - estimatedHeight - gap
        : anchorTopLeft.dy + anchorSize.height + gap;

    // Pointer x-position relative to the popover's left edge, clamped so
    // it stays within the rounded card even after the card was shifted
    // to stay on screen.
    double pointerX = anchorCenterX - left;
    pointerX = pointerX.clamp(24.0, popoverWidth - 24.0);

    final completer = Completer<bool>();
    late OverlayEntry entry;

    void close(bool result) {
      if (!completer.isCompleted) completer.complete(result);
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Invisible scrim: taps outside the card dismiss it without
          // darkening the screen — keeps this feeling lightweight.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => close(false),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: popoverWidth,
            child: _PopoverCard(
              message: message,
              confirmLabel: confirmLabel,
              cancelLabel: cancelLabel,
              pointerX: pointerX,
              pointerOnTop: !showAbove,
              onConfirm: () => close(true),
              onCancel: () => close(false),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
    return completer.future;
  }
}

class _PopoverCard extends StatelessWidget {
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final double pointerX;
  final bool pointerOnTop;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _PopoverCard({
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.pointerX,
    required this.pointerOnTop,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PopoverButton(
                  label: cancelLabel,
                  filled: false,
                  onTap: onCancel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PopoverButton(
                  label: confirmLabel,
                  filled: true,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onConfirm();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final pointer = CustomPaint(
      size: const Size(14, 7),
      painter: _PointerPainter(color: AppColors.bgCard),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        final clamped = t.clamp(0.0, 1.0);
        return Opacity(
          opacity: clamped,
          child: Transform.scale(
            scale: 0.85 + (0.15 * clamped),
            alignment:
            pointerOnTop ? Alignment.topCenter : Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pointerOnTop)
            Padding(
              padding: EdgeInsets.only(left: pointerX - 7),
              child: pointer,
            ),
          Material(color: Colors.transparent, child: card),
          if (!pointerOnTop)
            Padding(
              padding: EdgeInsets.only(left: pointerX - 7),
              child: Transform.rotate(angle: 3.14159, child: pointer),
            ),
        ],
      ),
    );
  }
}

class _PopoverButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _PopoverButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.accent700 : AppColors.grayLight,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    // Apex at top-center, base at bottom — an upward-pointing triangle.
    // Callers rotate it 180° when the popover sits above the anchor.
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) =>
      oldDelegate.color != color;
}