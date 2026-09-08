import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifenity_connect/utils/animations/animated_tap_scale.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';
// Unified dashboard tile card.
//
// Supports three explicit visual variants, selected via [DashboardTileVariant]
// rather than inferred from which optional fields are non-null:
//   - grid:    legacy neumorphic icon-in-a-box + label
//   - graphic: legacy full-bleed illustration + bottom label band
//   - modern:  new design — white card, 3D icon graphic bottom-right,
//              title/subtitle top-left, arrow affordance, optional banner
//
// NOTE: `_MarqueeBanner` is still referenced by the grid/graphic banner
// (as it was in the original legacy file) and must remain importable from
// wherever it currently lives in your project. `AnimatedTapScale` from the
// old file has been replaced with an inline press-scale animation so this
// widget is self-contained.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Which visual treatment this tile should render. Always pass this
/// explicitly — it is the single source of truth for layout selection.
enum DashboardTileVariant {
  /// Legacy neumorphic icon-in-a-box + label, used in the classic grid.
  grid,

  /// Legacy full-bleed illustration with a bottom label band.
  graphic,

  /// New design: white card, 3D icon graphic bottom-right, title/subtitle,
  /// arrow affordance, optional banner chip.
  modern,
}

class DashboardTileCard extends StatefulWidget {
  final DashboardTileVariant variant;
  final String title;

  /// modern-only.
  final String? subtitle;

  /// grid: glyph rendered inside a neumorphic box.
  /// modern: the 3D icon graphic seated bottom-right.
  /// Required for both of those variants; unused by graphic.
  final String? icon;

  /// graphic: the full illustration (required for this variant).
  /// modern: optional full-bleed decorative background image.
  final String? backgroundImage;
  final bool isNetworkImage;

  final VoidCallback onTap;

  /// graphic: scrolling marquee banner along the top.
  /// modern: small pill banner along the bottom.
  final String? bannerText;

  /// Meaning depends on [variant]:
  /// - graphic: fraction of height reserved for the bottom label band
  ///   (must stay within 15–20%, matching the original design spec).
  /// - modern: fraction of height reserved for the top title/subtitle band.
  /// - grid: unused.
  ///
  /// If omitted, defaults to 0.18 for grid/graphic and 0.56 for modern.
  final double labelBandFraction;

  /// Optional override. For grid/graphic this tints the neumorphic border
  /// (graphic mode only). For modern this tints the icon glow + banner.
  final Color? borderColor;

  DashboardTileCard({
    super.key,
    required this.variant,
    required this.title,
    this.subtitle,
    this.icon,
    this.backgroundImage,
    this.isNetworkImage = false,
    required this.onTap,
    this.bannerText,
    double? labelBandFraction,
    this.borderColor,
  })  : labelBandFraction = labelBandFraction ??
      (variant == DashboardTileVariant.modern ? 0.56 : 0.18),
        assert(
        variant != DashboardTileVariant.grid || icon != null,
        'DashboardTileVariant.grid requires `icon`.',
        ),
        assert(
        variant != DashboardTileVariant.graphic || backgroundImage != null,
        'DashboardTileVariant.graphic requires `backgroundImage`.',
        ),
        assert(
        variant != DashboardTileVariant.modern || icon != null,
        'DashboardTileVariant.modern requires `icon` (the graphic asset).',
        );
       /* assert(
        variant != DashboardTileVariant.graphic ||
            (this.labelBandFraction >= 0.15 &&
                this.labelBandFraction <= 0.20),
        'graphic variant labelBandFraction must stay within the 15–20% design spec.',
        );*/

  @override
  State<DashboardTileCard> createState() => _DashboardTileCardState();
}

class _DashboardTileCardState extends State<DashboardTileCard> {
  static const _ink = Color(0xFF161A2B);
  bool _pressed = false;

  Color get _accent => widget.borderColor ?? const Color(0xFF3B82F6);

  void _handleTapDown() => setState(() => _pressed = true);
  void _handleTapCancel() => setState(() => _pressed = false);
  void _handleTapUp() {
    setState(() => _pressed = false);
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case DashboardTileVariant.grid:
        return _buildLegacy(context, isGraphic: false);
      case DashboardTileVariant.graphic:
        return _buildLegacy(context, isGraphic: true);
      case DashboardTileVariant.modern:
        return _buildModern(context);
    }
  }

  // ── Legacy (grid / graphic) ──────────────────────────────────────────
  Widget _buildLegacy(BuildContext context, {required bool isGraphic}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = 20.0;
    final hasBanner =
        widget.bannerText != null && widget.bannerText!.isNotEmpty;

    // ── Neumorphic palette ─────────────────────────────────────────────
    final neuBase = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFECEFF4);
    final neuLight = isDark ? const Color(0xFF2C2C40) : Colors.white;
    final neuDark = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFC8CBD6);

    final resolvedBorderColor = widget.borderColor ??
        (isDark ? neuLight.withOpacity(0.16) : neuDark.withOpacity(0.9));

    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapCancel: _handleTapCancel,
      onTapUp: (_) => _handleTapUp(),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: neuBase,
            borderRadius: BorderRadius.circular(radius),
            border: isGraphic
                ? Border.all(color: resolvedBorderColor, width: 1.4)
                : null,
            boxShadow: [
              BoxShadow(
                color: neuLight.withOpacity(isDark ? 0.12 : 1.0),
                offset: const Offset(-5, -5),
                blurRadius: 10,
              ),
              BoxShadow(
                color: neuDark.withOpacity(isDark ? 0.75 : 0.55),
                offset: const Offset(5, 5),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => SizeTransition(
                    sizeFactor: anim,
                    axisAlignment: -1,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: hasBanner
                      ? _MarqueeBanner(
                    key: ValueKey(widget.bannerText),
                    text: widget.bannerText!,
                    isDark: isDark,
                    neuBase: neuBase,
                    neuDark: neuDark,
                  )
                      : const SizedBox.shrink(key: ValueKey('__empty__')),
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: isGraphic
                      ? _GraphicBody(
                    title: widget.title,
                    imagePath: widget.backgroundImage!,
                    isNetworkImage: widget.isNetworkImage,
                    labelBandFraction: widget.labelBandFraction,
                    isDark: isDark,
                  )
                      : _GridBody(
                    title: widget.title,
                    icon: widget.icon!,
                    cs: cs,
                    isDark: isDark,
                    neuBase: neuBase,
                    neuLight: neuLight,
                    neuDark: neuDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Modern ──────────────────────────────────────────────────────────
  Widget _buildModern(BuildContext context) {
    const cardRadius = 20.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _handleTapDown(),
      onTapCancel: _handleTapCancel,
      onTapUp: (_) => _handleTapUp(),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_pressed ? 0.03 : 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // ── Background icon, bottom-right, behind everything ──
              if (widget.icon != null)
                Positioned(
                  right: -18,
                  bottom: -12,
                  child: Opacity(
                    opacity: 0.9,
                    child: Image.asset(
                      widget.icon!,
                      width: 92,
                      height: 92,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

              // ── Foreground content, full width, sits on top ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: _ink,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: Colors.black.withOpacity(0.45),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F3F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildModern2(BuildContext context) {
    const cardRadius = 20.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _handleTapDown(),
      onTapCancel: _handleTapCancel,
      onTapUp: (_) => _handleTapUp(),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
          decoration: BoxDecoration(
            color:_accent.withOpacity(0.10),
            // color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_pressed ? 0.03 : 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Text column (left) ──────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      // overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: _ink,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        maxLines: 2,
                        // overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: Colors.black.withOpacity(0.45),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F3F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Icon column (right) — always beside the text ────
              if (widget.icon != null)
                SizedBox(
                  width: 30,
                  height: 96, // matches the card's inner height roughly
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: -14,
                        bottom: -6,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accent.withOpacity(0.10),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -6,
                        bottom: 4,
                        child: Image.asset(
                          widget.icon!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
 /* Widget _buildModern(BuildContext context) {
    const cardRadius = 24.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _handleTapDown(),
      onTapCancel: _handleTapCancel,
      onTapUp: (_) => _handleTapUp(),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_pressed ? 0.03 : 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final iconZone = h * (1 - widget.labelBandFraction);
              final iconSize = (iconZone * 0.92).clamp(48.0, 96.0);

              return Stack(
                children: [
                  // Optional full-bleed decorative background.
                  if (widget.backgroundImage != null)
                    Positioned.fill(
                      child: widget.isNetworkImage
                          ? Image.network(widget.backgroundImage!,
                          fit: BoxFit.cover)
                          : Image.asset(widget.backgroundImage!,
                          fit: BoxFit.cover),
                    ),

                  // Soft tinted glow behind the icon graphic.
                  Positioned(
                    right: -iconSize * 0.28,
                    bottom: widget.bannerText != null
                        ? iconSize * 0.34
                        : -iconSize * 0.22,
                    child: Container(
                      width: iconSize * 1.5,
                      height: iconSize * 1.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accent.withOpacity(0.10),
                      ),
                    ),
                  ),

                  // The 3D icon graphic, seated bottom-right.
                  Positioned(
                    right: 10,
                    bottom: widget.bannerText != null ? iconZone * 0.30 : 8,
                    child: Image.asset(
                      widget.icon!,
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Title / subtitle / arrow affordance.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
                            color: _ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                              color: Colors.black.withOpacity(0.45),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F3F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Optional bottom banner (e.g. "X bags with you").
                  if (widget.bannerText != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(cardRadius),
                            bottomRight: Radius.circular(cardRadius),
                          ),
                        ),
                        child: Text(
                          widget.bannerText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _accent.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }*/
}

// ── Legacy sub-widgets, unchanged from the original grid/graphic file ──

class _GraphicBody extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isNetworkImage;
  final double labelBandFraction;
  final bool isDark;

  const _GraphicBody({
    required this.title,
    required this.imagePath,
    required this.isNetworkImage,
    required this.labelBandFraction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Bounded height is guaranteed here — the parent GridView always
        // gives this tile a fixed size via childAspectRatio.
        final bandHeight =
        (constraints.maxHeight * labelBandFraction).clamp(28.0, 44.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            isNetworkImage
                ? Image.network(imagePath, fit: BoxFit.cover)
                : Image.asset(imagePath, fit: BoxFit.fill),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bandHeight,
              child: Container(
                decoration: const BoxDecoration(),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GridBody extends StatelessWidget {
  final String title;
  final String icon;
  final ColorScheme cs;
  final bool isDark;
  final Color neuBase;
  final Color neuLight;
  final Color neuDark;

  const _GridBody({
    required this.title,
    required this.icon,
    required this.cs,
    required this.isDark,
    required this.neuBase,
    required this.neuLight,
    required this.neuDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NeuIconBox(
              icon: icon,
              size: 54,
              isDark: isDark,
              neuBase: neuBase,
              neuLight: neuLight,
              neuDark: neuDark,
            ),
            const SizedBox(height: 11),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withOpacity(0.85)
                    : const Color(0xFF2D3142),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeuIconBox extends StatelessWidget {
  final String icon;
  final double size;
  final bool isDark;
  final Color neuBase;
  final Color neuLight;
  final Color neuDark;

  const _NeuIconBox({
    required this.icon,
    required this.size,
    required this.isDark,
    required this.neuBase,
    required this.neuLight,
    required this.neuDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.035),
      decoration: BoxDecoration(
        color: neuBase,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: neuLight.withOpacity(isDark ? 0.12 : 0.9),
            offset: const Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: neuDark.withOpacity(isDark ? 0.65 : 0.45),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.23),
        child: Image.asset(
          icon,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
/*class DashboardTileCard extends StatelessWidget {
  final String title;

  /// Legacy path — glyph/asset icon rendered inside a neumorphic box.
  final String? icon;

  /// New path — full illustration/graphic card. Takes precedence over [icon].
  final String? backgroundImage;

  final bool isNetworkImage;
  final VoidCallback onTap;
  final String? bannerText;

  /// Fraction of card height reserved for the bottom label band. 15–20%.
  final double labelBandFraction;

  /// Optional override. Defaults to a border tone derived from the
  /// existing neu palette so graphic + legacy cards stay visually unified.
  final Color? borderColor;

  const DashboardTileCard({
    super.key,
    required this.title,
    this.icon,
    this.backgroundImage,
    this.isNetworkImage = false,
    required this.onTap,
    this.bannerText,
    this.labelBandFraction = 0.18,
    this.borderColor,
  })  : assert(icon != null || backgroundImage != null,
  'Provide either icon (legacy) or backgroundImage (graphic card).'),
        assert(labelBandFraction >= 0.15 && labelBandFraction <= 0.20,
        'labelBandFraction must stay within the 15–20% design spec.');

  bool get _isGraphicMode => backgroundImage != null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = 20.0; // grid-mode radius, now the only mode
    final hasBanner = bannerText != null && bannerText!.isNotEmpty;

    // ── Neumorphic palette ──────────────────────────────────────────────
    final neuBase  = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFECEFF4);
    final neuLight = isDark ? const Color(0xFF2C2C40) : Colors.white;
    final neuDark  = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFC8CBD6);

    // ── Manual border tone ───────────────────────────────────────────────
    // Derived from the same palette as the neumorphic shadow so both card
    // types read as one system, but bumped to its own dedicated opacity —
    // the shadow's opacity is tuned for a soft blur, not a crisp edge, so
    // reusing it as-is renders almost invisibly against an illustration.
    final resolvedBorderColor = borderColor ??
        (isDark ? neuLight.withOpacity(0.16) : neuDark.withOpacity(0.9));

    return AnimatedTapScale(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: neuBase,
            borderRadius: BorderRadius.circular(radius),
            border: _isGraphicMode
                ? Border.all(color: resolvedBorderColor, width: 1.4)
                : null,
            boxShadow: [
              BoxShadow(
                color: neuLight.withOpacity(isDark ? 0.12 : 1.0),
                offset: const Offset(-5, -5),
                blurRadius: 10,
              ),
              BoxShadow(
                color: neuDark.withOpacity(isDark ? 0.75 : 0.55),
                offset: const Offset(5, 5),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => SizeTransition(
                    sizeFactor: anim,
                    axisAlignment: -1,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: hasBanner
                      ? _MarqueeBanner(
                    key: ValueKey(bannerText),
                    text: bannerText!,
                    isDark: isDark,
                    neuBase: neuBase,
                    neuDark: neuDark,
                  )
                      : const SizedBox.shrink(key: ValueKey('__empty__')),
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: _isGraphicMode
                      ? _GraphicBody(
                    title: title,
                    imagePath: backgroundImage!,
                    isNetworkImage: isNetworkImage,
                    labelBandFraction: labelBandFraction,
                    isDark: isDark,
                  )
                      : _GridBody(
                    title: title,
                    icon: icon!,
                    cs: cs,
                    isDark: isDark,
                    neuBase: neuBase,
                    neuLight: neuLight,
                    neuDark: neuDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GraphicBody extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isNetworkImage;
  final double labelBandFraction;
  final bool isDark;

  const _GraphicBody({
    required this.title,
    required this.imagePath,
    required this.isNetworkImage,
    required this.labelBandFraction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Bounded height is guaranteed here — the parent GridView always
        // gives this tile a fixed size via childAspectRatio.
        final bandHeight =
        (constraints.maxHeight * labelBandFraction).clamp(28.0, 44.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            isNetworkImage
                ? Image.network(imagePath, fit: BoxFit.cover)
                : Image.asset(imagePath, fit: BoxFit.fill),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bandHeight,
              child: Container(

                decoration: const BoxDecoration(
                  *//*gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(isDark ? 0.55 : 0.45),
                    ],
                  ),*//*
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    // color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


class _GridBody extends StatelessWidget {
  final String title;
  final String icon;
  final ColorScheme cs;
  final bool isDark;
  final Color neuBase;
  final Color neuLight;
  final Color neuDark;

  const _GridBody({
    required this.title,
    required this.icon,
    required this.cs,
    required this.isDark,
    required this.neuBase,
    required this.neuLight,
    required this.neuDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NeuIconBox(
              icon: icon,
              size: 54,
              // iconSize: 28,
              isDark: isDark,
              neuBase: neuBase,
              neuLight: neuLight,
              neuDark: neuDark,
            ),
            const SizedBox(height: 11),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withOpacity(0.85)
                    : const Color(0xFF2D3142),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeuIconBox extends StatelessWidget {
  final String icon;
  final double size;
  final bool isDark;
  final Color neuBase;
  final Color neuLight;
  final Color neuDark;

  const _NeuIconBox({
    required this.icon,
    required this.size,
    required this.isDark,
    required this.neuBase,
    required this.neuLight,
    required this.neuDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.035), // very small breathing room
      decoration: BoxDecoration(
        color: neuBase,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          // Top-left highlight
          BoxShadow(
            color: neuLight.withOpacity(isDark ? 0.12 : 0.9),
            offset: const Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 0,
          ),

          // Bottom-right depth
          BoxShadow(
            color: neuDark.withOpacity(isDark ? 0.65 : 0.45),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.23),
        child: Image.asset(
          icon,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}*/

// class _NeuIconBox extends StatelessWidget {
//   final String icon;
//   final double size;
//   final double iconSize;
//   final bool isDark;
//   final Color neuBase;
//   final Color neuLight;
//   final Color neuDark;
//
//   const _NeuIconBox({
//     required this.icon,
//     required this.size,
//     required this.iconSize,
//     required this.isDark,
//     required this.neuBase,
//     required this.neuLight,
//     required this.neuDark,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         color: neuBase,
//         borderRadius: BorderRadius.circular(size * 0.28),
//         boxShadow: [
//           // Highlight — top-left
//           BoxShadow(
//             color: neuLight.withOpacity(isDark ? 0.12 : 1.0),
//             offset: const Offset(-3, -3),
//             blurRadius: 6,
//           ),
//           // Shadow — bottom-right
//           BoxShadow(
//             color: neuDark.withOpacity(isDark ? 0.7 : 0.5),
//             offset: const Offset(3, 3),
//             blurRadius: 6,
//           ),
//         ],
//       ),
//       child: Center(
//         child: Image.asset(
//           icon,
//           width: iconSize,
//           height: iconSize,
//           fit: BoxFit.contain,
//         ),
//       ),
//     );
//   }
// }


class _MarqueeBanner extends StatefulWidget {
  final String text;
  final bool isDark;
  final Color neuBase;
  final Color neuDark;

  const _MarqueeBanner({
    super.key,
    required this.text,
    required this.isDark,
    required this.neuBase,
    required this.neuDark,
  });

  @override
  State<_MarqueeBanner> createState() => _MarqueeBannerState();
}

class _MarqueeBannerState extends State<_MarqueeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _style = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _textWidth(Color color) {
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: _style.copyWith(color: color)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    kPrint('🍫🍫🍫🍫Rendering marquue');
    final isDark = widget.isDark;
    // Inset: slightly darker than neuBase to look pressed in
    final bg    = isDark ? const Color(0xFF16161F) : const Color(0xFFDDE1EA);
    final color = isDark ? const Color(0xFF7EC8F0) : const Color(0xFF1565C0);
    final divider = isDark
        ? Colors.white.withOpacity(0.06)
        : widget.neuDark.withOpacity(0.25);
    final tw = _textWidth(color);

    return LayoutBuilder(
      builder: (_, constraints) {
        final avail = constraints.maxWidth;
        return Container(
          height: 22,
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: BorderSide(color: divider, width: 1),
            ),
            // Inset shadow: dark on top, light on bottom
            boxShadow: [
              BoxShadow(
                color: widget.neuDark.withOpacity(isDark ? 0.6 : 0.3),
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: tw <= avail
              ? Center(
            child: Text(
              widget.text.trim(),
              style: _style.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
              : AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final offset = (_ctrl.value * tw) % tw;
              return Stack(children: [
                _span(-offset, tw, color),
                _span(tw - offset, tw, color),
              ]);
            },
          ),
        );
      },
    );
  }

  Widget _span(double left, double width, Color color) => Positioned(
    left: left,
    top: 0,
    bottom: 0,
    width: width,
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        widget.text,
        style: _style.copyWith(color: color),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    ),
  );
}