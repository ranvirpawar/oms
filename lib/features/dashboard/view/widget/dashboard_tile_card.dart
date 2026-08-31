import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifenity_connect/utils/animations/animated_tap_scale.dart';



class DashboardTileCard extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback onTap;
  final bool isGridMode;
  final String? bannerText;

  const DashboardTileCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.isGridMode = false,
    this.bannerText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = isGridMode ? 20.0 : 18.0;
    final hasBanner = bannerText != null && bannerText!.isNotEmpty;

    // ── Neumorphic palette ──────────────────────────────────────────────────
    final neuBase  = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFECEFF4);
    final neuLight = isDark ? const Color(0xFF2C2C40) : Colors.white;
    final neuDark  = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFC8CBD6);

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
            boxShadow: [
              // Top-left highlight
              BoxShadow(
                color: neuLight.withOpacity(isDark ? 0.12 : 1.0),
                offset: const Offset(-5, -5),
                blurRadius: 10,
              ),
              // Bottom-right shadow
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
              mainAxisSize: isGridMode ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Banner ────────────────────────────────────────────
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

                // ── Body ──────────────────────────────────────────────
                Flexible(
                  fit: isGridMode ? FlexFit.tight : FlexFit.loose,
                  child: isGridMode
                      ? _GridBody(
                    title: title,
                    icon: icon,
                    cs: cs,
                    isDark: isDark,
                    neuBase: neuBase,
                    neuLight: neuLight,
                    neuDark: neuDark,
                  )
                      : _ListBody(
                    title: title,
                    icon: icon,
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

// ─────────────────────────────────────────────────────────────────────────────
// List Body
// ─────────────────────────────────────────────────────────────────────────────

class _ListBody extends StatelessWidget {
  final String title;
  final String icon;
  final ColorScheme cs;
  final bool isDark;
  final Color neuBase;
  final Color neuLight;
  final Color neuDark;

  const _ListBody({
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _NeuIconBox(
            icon: icon,
            size: 52,
            iconSize: 28,
            isDark: isDark,
            neuBase: neuBase,
            neuLight: neuLight,
            neuDark: neuDark,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withOpacity(0.88)
                    : const Color(0xFF2D3142),
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          _NeuArrow(
            cs: cs,
            isDark: isDark,
            neuBase: neuBase,
            neuLight: neuLight,
            neuDark: neuDark,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid Body — content always centered in available space
// ─────────────────────────────────────────────────────────────────────────────

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
              iconSize: 28,
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

// ─────────────────────────────────────────────────────────────────────────────
// Neumorphic Icon Box — raised extrusion
// ─────────────────────────────────────────────────────────────────────────────

class _NeuIconBox extends StatelessWidget {
  final String icon;
  final double size;
  final double iconSize;
  final bool isDark;
  final Color neuBase;
  final Color neuLight;
  final Color neuDark;

  const _NeuIconBox({
    required this.icon,
    required this.size,
    required this.iconSize,
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
      decoration: BoxDecoration(
        color: neuBase,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          // Highlight — top-left
          BoxShadow(
            color: neuLight.withOpacity(isDark ? 0.12 : 1.0),
            offset: const Offset(-3, -3),
            blurRadius: 6,
          ),
          // Shadow — bottom-right
          BoxShadow(
            color: neuDark.withOpacity(isDark ? 0.7 : 0.5),
            offset: const Offset(3, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          icon,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Neumorphic Arrow
// ─────────────────────────────────────────────────────────────────────────────

class _NeuArrow extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  final Color neuBase;
  final Color neuLight;
  final Color neuDark;

  const _NeuArrow({
    required this.cs,
    required this.isDark,
    required this.neuBase,
    required this.neuLight,
    required this.neuDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: neuBase,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: neuLight.withOpacity(isDark ? 0.12 : 1.0),
            offset: const Offset(-2, -2),
            blurRadius: 5,
          ),
          BoxShadow(
            color: neuDark.withOpacity(isDark ? 0.7 : 0.5),
            offset: const Offset(2, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 15,
        color: cs.primary.withOpacity(0.85),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Marquee Banner — inset neumorphic (pressed into the card surface)
// ─────────────────────────────────────────────────────────────────────────────

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
// class DashboardTileCard extends StatelessWidget {
//   final String title;
//   final String icon;
//   final VoidCallback onTap;
//   final bool isGridMode;
//
//   /// Optional marquee alert. When non-null and non-empty the banner is shown.
//   final String? bannerText;
//
//   const DashboardTileCard({
//     super.key,
//     required this.title,
//     required this.icon,
//     required this.onTap,
//     this.isGridMode = false,
//     this.bannerText,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final cs = theme.colorScheme;
//     final isDark = theme.brightness == Brightness.dark;
//     final radius = isGridMode ? 18.0 : 16.0;
//     final hasBanner = bannerText != null && bannerText!.isNotEmpty;
//
//     return AnimatedTapScale(
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(radius),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(radius),
//           onTap: () {
//             HapticFeedback.lightImpact();
//             onTap();
//           },
//           splashColor: cs.primary.withOpacity(0.07),
//           highlightColor: cs.primary.withOpacity(0.03),
//           child: Ink(
//             decoration: BoxDecoration(
//               color: isDark ? const Color(0xFF1C1C2E) : cs.surface,
//               borderRadius: BorderRadius.circular(radius),
//               boxShadow: [
//                 BoxShadow(
//                   color: isDark
//                       ? Colors.black.withOpacity(0.32)
//                       : cs.shadow.withOpacity(0.06),
//                   blurRadius: 18,
//                   offset: const Offset(0, 6),
//                 ),
//               ],
//               border: Border.all(
//                 color: isDark
//                     ? Colors.white.withOpacity(0.07)
//                     : cs.outline.withOpacity(0.08),
//                 width: 1,
//               ),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(radius),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // ── Banner slot ──────────────────────────────────────
//                   AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 380),
//                     switchInCurve: Curves.easeOutCubic,
//                     switchOutCurve: Curves.easeInCubic,
//                     transitionBuilder: (child, anim) => SizeTransition(
//                       sizeFactor: anim,
//                       axisAlignment: -1,
//                       child: FadeTransition(opacity: anim, child: child),
//                     ),
//                     child: hasBanner
//                         ? _MarqueeBanner(
//                       key: ValueKey(bannerText),
//                       text: bannerText!,
//                       isDark: isDark,
//                     )
//                         : const SizedBox.shrink(key: ValueKey('__empty__')),
//                   ),
//
//                   // ── Body ────────────────────────────────────────────
//                   isGridMode
//                       ? _GridBody(title: title, icon: icon, cs: cs, isDark: isDark)
//                       : _ListBody(title: title, icon: icon, cs: cs, isDark: isDark),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // List Body
// // ─────────────────────────────────────────────────────────────────────────────
//
// class _ListBody extends StatelessWidget {
//   final String title;
//   final String icon;
//   final ColorScheme cs;
//   final bool isDark;
//
//   const _ListBody({
//     required this.title,
//     required this.icon,
//     required this.cs,
//     required this.isDark,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           _IconPill(icon: icon, cs: cs, isDark: isDark, containerSize: 48, imageSize: 26),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Text(
//               title,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: isDark ? Colors.white.withOpacity(0.9) : cs.onSurface,
//                 height: 1.35,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           const SizedBox(width: 10),
//           _ArrowChip(cs: cs, isDark: isDark),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Grid Body
// // ─────────────────────────────────────────────────────────────────────────────
//
// class _GridBody extends StatelessWidget {
//   final String title;
//   final String icon;
//   final ColorScheme cs;
//   final bool isDark;
//
//   const _GridBody({
//     required this.title,
//     required this.icon,
//     required this.cs,
//     required this.isDark,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           _IconPill(icon: icon, cs: cs, isDark: isDark, containerSize: 48, imageSize: 26),
//           const SizedBox(height: 10),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 12.5,
//               fontWeight: FontWeight.w600,
//               color: isDark ? Colors.white.withOpacity(0.88) : cs.onSurface,
//               height: 1.35,
//             ),
//             textAlign: TextAlign.center,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Shared sub-widgets
// // ─────────────────────────────────────────────────────────────────────────────
//
// class _IconPill extends StatelessWidget {
//   final String icon;
//   final ColorScheme cs;
//   final bool isDark;
//   final double containerSize;
//   final double imageSize;
//
//   const _IconPill({
//     required this.icon,
//     required this.cs,
//     required this.isDark,
//     required this.containerSize,
//     required this.imageSize,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: containerSize,
//       height: containerSize,
//       padding: EdgeInsets.all((containerSize - imageSize) / 2),
//      /* decoration: BoxDecoration(
//         color: cs.primary.withOpacity(isDark ? 0.18 : 0.08),
//         borderRadius: BorderRadius.circular(13),
//         border: Border.all(
//           color: cs.primary.withOpacity(isDark ? 0.22 : 0.12),
//           width: 1,
//         ),
//       ),*/
//       child: Image.asset(icon, width: imageSize, height: imageSize, fit: BoxFit.contain),
//     );
//   }
// }
//
// class _ArrowChip extends StatelessWidget {
//   final ColorScheme cs;
//   final bool isDark;
//
//   const _ArrowChip({required this.cs, required this.isDark});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 30,
//       height: 30,
//       decoration: BoxDecoration(
//         color: cs.primary.withOpacity(isDark ? 0.18 : 0.08),
//         borderRadius: BorderRadius.circular(9),
//       ),
//       child: Icon(Icons.arrow_forward_rounded, size: 15, color: cs.primary),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Marquee Banner
// // Uses TextPainter for sync width — no GlobalKey, no postFrameCallback,
// // no first-frame flash. LayoutBuilder feeds real available width.
// // ─────────────────────────────────────────────────────────────────────────────
//
// class _MarqueeBanner extends StatefulWidget {
//   final String text;
//   final bool isDark;
//
//   const _MarqueeBanner({super.key, required this.text, required this.isDark});
//
//   @override
//   State<_MarqueeBanner> createState() => _MarqueeBannerState();
// }
//
// class _MarqueeBannerState extends State<_MarqueeBanner>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//
//   static const _style = TextStyle(
//     fontSize: 10.5,
//     fontWeight: FontWeight.w600,
//     letterSpacing: 0.2,
//     height: 1,
//   );
//
//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 16),
//     )..repeat();
//   }
//
//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }
//
//   double _textWidth(Color color) {
//     final tp = TextPainter(
//       text: TextSpan(text: widget.text, style: _style.copyWith(color: color)),
//       maxLines: 1,
//       textDirection: TextDirection.ltr,
//     )..layout(maxWidth: double.infinity);
//     return tp.width;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = widget.isDark;
//     final bg    = isDark ? const Color(0xFF0A1F3A) : const Color(0xFFE8F4FD);
//     final border= isDark ? const Color(0xFF1A4A8A) : const Color(0xFFBADAF5);
//     final color = isDark ? const Color(0xFF7EC8F0) : const Color(0xFF1565C0);
//     final tw    = _textWidth(color);
//
//     return LayoutBuilder(
//       builder: (_, constraints) {
//         final avail = constraints.maxWidth;
//         return Container(
//           height: 22,
//           decoration: BoxDecoration(
//             color: bg,
//             border: Border(bottom: BorderSide(color: border, width: 1)),
//           ),
//           clipBehavior: Clip.hardEdge,
//           child: tw <= avail
//               ? Center(
//             child: Text(
//               widget.text.trim(),
//               style: _style.copyWith(color: color),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           )
//               : AnimatedBuilder(
//             animation: _ctrl,
//             builder: (_, __) {
//               final offset = (_ctrl.value * tw) % tw;
//               return Stack(children: [
//                 _span(-offset, tw, color),
//                 _span(tw - offset, tw, color),
//               ]);
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _span(double left, double width, Color color) => Positioned(
//     left: left,
//     top: 0,
//     bottom: 0,
//     width: width,
//     child: Align(
//       alignment: Alignment.centerLeft,
//       child: Text(
//         widget.text,
//         style: _style.copyWith(color: color),
//         maxLines: 1,
//         softWrap: false,
//         overflow: TextOverflow.visible,
//       ),
//     ),
//   );
// }
/*class DashboardTileCard extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback onTap;
  final bool isGridMode;

  const DashboardTileCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.isGridMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedTapScale(
      child: Material(
        color: Colors.transparent,
        elevation: 1,
        borderRadius: BorderRadius.circular(isGridMode ? 20 : 24),
        child: InkWell(
          borderRadius: BorderRadius.circular(isGridMode ? 20 : 24),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(isGridMode ? 20 : 24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(isGridMode ? 4 : 12),
              child: isGridMode
                  ? _buildGridLayout(theme, colorScheme)
                  : _buildListLayout(theme, colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListLayout(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Icon container
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Image.asset(
            icon,
            height: 50,
            width: 50,
          ),
        ),

        const SizedBox(width: 10),

        // Title text
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(width: 8),

        // Arrow indicator
        const ArrowForwardContainer(),
      ],
    );
  }

  Widget _buildGridLayout(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Icon container - optimized for grid
        Container(
          // padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Image.asset(
            icon,
            fit: BoxFit.fitWidth,
            height: 40,
            // width: 34,
          ),
        ),

        // Title text - centered and compact for grid
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // Small arrow indicator for grid
        *//*Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: colorScheme.primary,
          ),
        ),*//*
      ],
    );
  }
}*/
