// liquid_glass_snackbar_service.dart
//
// A modern, interactive "Liquid Glass" style snackbar system for Flutter.
//
// Design rationale:
//  - Layer separation: a blurred/tinted GLASS SURFACE sits behind a crisp,
//    never-blurred CONTENT layer (icon + text + action). Content stays legible.
//  - Legibility over ANY backdrop: this widget floats over arbitrary screen
//    content, not just the app's own background — so the glass base is a
//    fixed dark scrim regardless of the app's light/dark theme. Tying the
//    scrim to `Theme.of(context).brightness` (as before) meant light mode
//    produced a pale glass with white text on top of it, which is the
//    "text/contrast doesn't look good" problem. A constant dark base fixes
//    this everywhere and matches how iOS's own notification banners behave.
//  - Hierarchy comes from type weight/size, not opacity. Opacity was
//    previously used both for "secondary text" and "dim it a bit," which
//    silently eats into contrast. Title is bold/full-white; body is a
//    lighter weight at full white — no opacity trick doing double duty.
//  - Restraint: no close button by default. Auto-dismiss + swipe-to-dismiss
//    already cover dismissal; a persistent close icon on every toast is
//    chrome nobody asked for. Tapping the card dismisses it when there's no
//    action button, so there's always an obvious way out without adding a
//    third widget for it. Pass `showCloseButton: true` on `show()` if a
//    specific call site really needs a persistent close affordance.
//  - Color is never the only signal: every variant pairs a hue with a
//    distinct icon shape.
//  - Motion: spring-like slide + fade + slight scale on entry (easeOutBack),
//    matching platform-standard "gentle overshoot" easing; swipe-to-dismiss
//    with a velocity threshold; light haptic on entrance.
//  - Accessibility: WCAG 4.5:1 text contrast, >=44pt touch targets, respects
//    text scaling, Semantics for screen readers, reduced-motion fallback.
//
// No GetX dependency required for rendering — this uses Overlay directly,
// which is what actually exposes BackdropFilter/blur compositing. A tiny
// facade (LiquidSnack) keeps call sites as simple one-liners.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class _SnackTokens {
  // Fixed glass base — intentionally NOT theme-dependent. See rationale above.
  static const glassBase = Color(0xFF0B0B0D); // near-black, always
  static const glassBaseOpacity = 0.72;
  static const borderColor = Colors.white;
  static const borderOpacity = 0.14;
  static const radiusLg = 20.0;
  static const radiusPill = 999.0;
}

enum SnackVariant { success, error, warning, info, neutral }

class _VariantStyle {
  final Color tint; // glass tint color (kept translucent, never opaque)
  final IconData icon;
  final String semanticPrefix;

  const _VariantStyle({
    required this.tint,
    required this.icon,
    required this.semanticPrefix,
  });
}

const Map<SnackVariant, _VariantStyle> _variantStyles = {
  SnackVariant.success: _VariantStyle(
    tint: Color(0xFF34C759), // system green
    icon: Icons.check_circle_rounded,
    semanticPrefix: 'Success',
  ),
  SnackVariant.error: _VariantStyle(
    tint: Color(0xFFFF3B30), // system red
    icon: Icons.error_rounded,
    semanticPrefix: 'Error',
  ),
  SnackVariant.warning: _VariantStyle(
    tint: Color(0xFFFF9F0A), // system orange
    icon: Icons.warning_rounded,
    semanticPrefix: 'Warning',
  ),
  SnackVariant.info: _VariantStyle(
    tint: Color(0xFF0A84FF), // system blue
    icon: Icons.info_rounded,
    semanticPrefix: 'Info',
  ),
  SnackVariant.neutral: _VariantStyle(
    tint: Color(0xFF8E8E93), // system gray
    icon: Icons.notifications_rounded,
    semanticPrefix: 'Notice',
  ),
};

enum SnackPosition { top, bottom }

// ---------------------------------------------------------------------------
// Public facade
// ---------------------------------------------------------------------------

class LiquidSnack {
  LiquidSnack._();

  /// Set once in main() / MaterialApp(navigatorKey: LiquidSnack.navigatorKey)
  /// so the service can show snackbars without a BuildContext at the call site.
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static final List<OverlayEntry> _queue = [];
  static bool _busy = false;

  /// Full-featured show. All the shorthand methods below just call this.
  static Future<void> show({
    required String message,
    String? title,
    SnackVariant variant = SnackVariant.neutral,
    SnackPosition position = SnackPosition.bottom,
    // Project rule: snackbars must never stay on screen longer than 2s.
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
    bool showCloseButton = false,
    bool isQuick = false,
  }) async {
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return; // no navigator attached yet

    final completer = Completer<void>();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _GlassSnackbar(
        message: message,
        title: title,
        variant: variant,
        position: position,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        showCloseButton: showCloseButton,
        isQuick: isQuick,
        onDismissed: () {
          onDismiss?.call();
          entry.remove();
          _queue.remove(entry);
          _busy = false;
          completer.complete();
          _drainQueue();
        },
      ),
    );

    if (_busy) {
      // Queue rather than stack glass panels on top of each other —
      // stacked translucent layers destroy contrast.
      _queue.add(entry);
      return completer.future;
    }

    _busy = true;
    overlayState.insert(entry);
    return completer.future;
  }

  static void _drainQueue() {
    if (_queue.isEmpty || _busy) return;
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;
    final next = _queue.removeAt(0);
    _busy = true;
    overlayState.insert(next);
  }

  // ---- Shorthand helpers ----

  /// Minimal, low-chrome toast: no title, no icon row, no action, no close
  /// button — just a short message in a self-sizing pill. Use this for quick
  /// confirmations ("Copied", "Saved", "Link copied") where a full card with
  /// an icon and title would be overkill.
  static Future<void> quick(
      String message, {
        SnackPosition position = SnackPosition.bottom,
        Duration duration = const Duration(seconds: 2),
      }) =>
      show(
        message: message,
        variant: SnackVariant.neutral,
        position: position,
        duration: duration,
        isQuick: true,
      );

  static Future<void> success(String message, {String? title}) => show(
    message: message,
    title: title,
    variant: SnackVariant.success,
  );

  static Future<void> error(String message, {String? title}) => show(
    message: message,
    title: title,
    variant: SnackVariant.error,
    duration: const Duration(seconds: 2),
  );

  static Future<void> warning(String message, {String? title}) => show(
    message: message,
    title: title,
    variant: SnackVariant.warning,
  );

  static Future<void> info(String message, {String? title}) => show(
    message: message,
    title: title,
    variant: SnackVariant.info,
  );

  static Future<void> withAction({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    SnackVariant variant = SnackVariant.neutral,
    Duration duration = const Duration(seconds: 2),
  }) =>
      show(
        message: message,
        variant: variant,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );
}

// ---------------------------------------------------------------------------
// The glass widget itself
// ---------------------------------------------------------------------------

class _GlassSnackbar extends StatefulWidget {
  final String message;
  final String? title;
  final SnackVariant variant;
  final SnackPosition position;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showCloseButton;
  final bool isQuick;
  final VoidCallback onDismissed;

  const _GlassSnackbar({
    required this.message,
    required this.title,
    required this.variant,
    required this.position,
    required this.duration,
    required this.actionLabel,
    required this.onAction,
    required this.showCloseButton,
    required this.isQuick,
    required this.onDismissed,
  });

  @override
  State<_GlassSnackbar> createState() => _GlassSnackbarState();
}

class _GlassSnackbarState extends State<_GlassSnackbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  Timer? _autoDismissTimer;
  double _dragOffset = 0;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    final beginOffset = widget.position == SnackPosition.bottom
        ? const Offset(0, 0.4)
        : const Offset(0, -0.4);

    // Gentle overshoot curve reads as "springy" without a physics sim —
    // matches platform-standard entry motion (250-400ms, easeOutBack).
    _slide = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _scheduleAutoDismiss();

    // Discrete state-change haptic, not tied to a continuous gesture.
    final isError = widget.variant == SnackVariant.error;
    isError ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
  }

  void _scheduleAutoDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _autoDismissTimer?.cancel();
    if (mounted) {
      await _controller.reverse();
    }
    widget.onDismissed();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final reduceMotion = mq.disableAnimations;
    final style = _variantStyles[widget.variant]!;

    Widget content =
    widget.isQuick ? _buildQuickPill(style) : _buildFullCard(style);

    content = Semantics(
      liveRegion: true,
      label: '${style.semanticPrefix}: '
          '${widget.title != null ? '${widget.title}. ' : ''}${widget.message}',
      child: content,
    );

    // Tap-anywhere-to-dismiss when there's no action button competing for
    // the tap target — this is what replaces the old always-on close icon.
    if (widget.actionLabel == null && !widget.showCloseButton) {
      content = GestureDetector(onTap: _dismiss, child: content);
    }

    // Swipe-to-dismiss with a velocity threshold — matches native gesture
    // conventions. Only fires on discrete threshold-crossing, not per pixel.
    content = GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() => _dragOffset += details.delta.dx);
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond.dx;
        if (_dragOffset.abs() > 80 || velocity.abs() > 600) {
          HapticFeedback.selectionClick();
          _dismiss();
        } else {
          setState(() => _dragOffset = 0);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(_dragOffset, 0, 0),
        child: Opacity(
          opacity: (1 - (_dragOffset.abs() / 300)).clamp(0.0, 1.0),
          child: content,
        ),
      ),
    );

    final animated = reduceMotion
        ? content
        : FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: content),
      ),
    );

    if (widget.isQuick) {
      // Self-sizing pill, centered — not stretched edge-to-edge like a card.
      return Positioned(
        left: 24,
        right: 24,
        top: widget.position == SnackPosition.top
            ? mq.padding.top + 12
            : null,
        bottom: widget.position == SnackPosition.bottom
            ? mq.padding.bottom + 24
            : null,
        child: Center(
          child: Material(color: Colors.transparent, child: animated),
        ),
      );
    }

    return Positioned(
      left: 16,
      right: 16,
      top: widget.position == SnackPosition.top ? mq.padding.top + 12 : null,
      bottom:
      widget.position == SnackPosition.bottom ? mq.padding.bottom + 24 : null,
      child: Material(color: Colors.transparent, child: animated),
    );
  }

  // -- Full card: icon chip + optional title + message + optional action --
  Widget _buildFullCard(_VariantStyle style) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_SnackTokens.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: _glassDecoration(style),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.tint,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.title != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          widget.title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            height: 1.25,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    Text(
                      widget.message,
                      // Full white, weight-led hierarchy instead of opacity —
                      // keeps contrast high regardless of variant tint.
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.actionLabel != null) ...[
                const SizedBox(width: 8),
                _GlassActionButton(
                  label: widget.actionLabel!,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onAction?.call();
                    _dismiss();
                  },
                ),
              ],
              if (widget.showCloseButton) ...[
                const SizedBox(width: 4),
                _GlassCloseButton(onTap: _dismiss),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // -- Quick pill: message only, no icon/title/action/close chrome --
  Widget _buildQuickPill(_VariantStyle style) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_SnackTokens.radiusPill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _SnackTokens.glassBase
                .withOpacity(_SnackTokens.glassBaseOpacity),
            borderRadius: BorderRadius.circular(_SnackTokens.radiusPill),
            border: Border.all(
              color: _SnackTokens.borderColor
                  .withOpacity(_SnackTokens.borderOpacity),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  // Fixed dark glass base tinted per variant — always legible regardless of
  // the app's theme or whatever's behind the snackbar. See top-of-file note.
  BoxDecoration _glassDecoration(_VariantStyle style) {
    final tinted = Color.alphaBlend(
      style.tint.withOpacity(0.28),
      _SnackTokens.glassBase.withOpacity(_SnackTokens.glassBaseOpacity),
    );
    return BoxDecoration(
      color: tinted,
      borderRadius: BorderRadius.circular(_SnackTokens.radiusLg),
      border: Border.all(
        color:
        _SnackTokens.borderColor.withOpacity(_SnackTokens.borderOpacity),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Action / close buttons — real, non-blurred content (>=44pt touch target)
// ---------------------------------------------------------------------------

class _GlassActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _GlassActionButton({required this.label, required this.onTap});

  @override
  State<_GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<_GlassActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(_pressed ? 0.28 : 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassCloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Dismiss notification',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.close_rounded, size: 18, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}