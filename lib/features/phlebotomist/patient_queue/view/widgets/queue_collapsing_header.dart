import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../controller/patient_queue_scroll_controller.dart';

/// Stacks [collapsible] (slides away) above [pinned] (sticks to the top).
///
/// Place it as the LAST child of a Stack whose first child is the scrolling
/// list, and pad the list's top by (topInset + collapsible + pinned heights).
class QueueCollapsingHeader extends StatefulWidget {
  const QueueCollapsingHeader({
    super.key,
    required this.scroll,
    required this.collapsible,
    required this.pinned,
    required this.topInset,
    required this.backgroundColor,
  });

  final PatientQueueScrollController scroll;

  /// App bar (including its status-bar padding) + visit-type row.
  final Widget collapsible;

  /// Status filter chips.
  final Widget pinned;

  /// MediaQuery top padding (status bar height).
  final double topInset;

  /// Page background (opaque, so the list never shows through the header).
  final Color backgroundColor;

  @override
  State<QueueCollapsingHeader> createState() => _QueueCollapsingHeaderState();
}

class _QueueCollapsingHeaderState extends State<QueueCollapsingHeader> {
  @override
  void initState() {
    super.initState();
    // Fresh list => header fully visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.scroll.reset();
    });
  }

  static final _darkIcons = SystemUiOverlayStyle.dark.copyWith(
    statusBarColor: Colors.transparent,
  );

  @override
  Widget build(BuildContext context) {
    final scroll = widget.scroll;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: scroll.hiddenOffset,
              // Built once — only the Transform changes per scroll frame.
              child: _buildContent(),
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -scroll.hiddenOffset.value),
                child: child,
              ),
            ),
          ),
        ),
        // Status-bar strip: invisible while the gradient app bar is showing
        // (the app bar paints its own gradient behind the status bar), and
        // fades to the page background as the chips pin to the top.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: widget.topInset,
          child: IgnorePointer(
            child: ValueListenableBuilder<double>(
              valueListenable: scroll.hiddenOffset,
              builder: (context, hidden, _) {
                final max = scroll.collapsibleHeight.value;
                final progress = max <= 0 ? 0.0 : (hidden / max).clamp(0.0, 1.0);
                // Fully opaque before the visit row reaches the status bar.
                final opacity = (progress * 2).clamp(0.0, 1.0);
                Widget strip = ColoredBox(
                  color: widget.backgroundColor
                      .withAlpha((opacity * 255).round()),
                );
                // Dark status-bar icons once the strip is light.
                if (progress >= 0.5) {
                  strip = AnnotatedRegion<SystemUiOverlayStyle>(
                    value: _darkIcons,
                    child: strip,
                  );
                }
                return SizedBox.expand(child: strip);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final scroll = widget.scroll;

    // Material (not ColoredBox) so InkWell splashes on chips/tabs stay visible.
    return Material(
      color: widget.backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MeasureSize(
            // Excludes the status-bar inset: that part never scrolls away.
            onChange: (s) =>
                scroll.setCollapsibleHeight(s.height - widget.topInset),
            child: widget.collapsible,
          ),
          MeasureSize(
            onChange: (s) => scroll.setPinnedHeight(s.height),
            child: ValueListenableBuilder<bool>(
              valueListenable: scroll.hasScrolled,
              child: widget.pinned,
              builder: (context, scrolled, child) => Material(
                color: widget.backgroundColor,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.black54,
                // Soft shadow only once content is actually under the chips.
                elevation: scrolled ? 2 : 0,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reports its child's size after layout (post-frame, so it's safe to update
/// reactive state from the callback).
class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, required Widget child})
      : super(child: child);

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
      BuildContext context,
      covariant _RenderMeasureSize renderObject,
      ) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (_last == size) return;
    final measured = size;
    _last = measured;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(measured));
  }
}