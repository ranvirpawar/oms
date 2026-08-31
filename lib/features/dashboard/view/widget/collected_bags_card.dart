import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_assets.dart';
import '../../../../constants/app_strings.dart';
import '../../dashboard_controller/dashboard_controller.dart';
import 'dashboard_tile_card.dart';


/// Wraps [DashboardTileCard] for "Collected Sample Bags" with an animated
/// marquee alert banner on top. The banner is rendered OUTSIDE the card's
/// ClipRect so it never gets clipped, and uses a LayoutBuilder-driven width
/// so it works on every device/screen size.
class CollectedBagsTileWithBanner extends StatelessWidget {
  final VoidCallback onTap;
  final bool isGridMode;

  const CollectedBagsTileWithBanner({
    super.key,
    required this.onTap,
    required this.isGridMode,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Obx(() {
      final count = controller.collectedBagsCount.value;
      final hasBags = count > 0;

      // Banner height — constant so the grid cell always reserves the same
      // space, preventing layout jank when the banner appears/disappears.
      const bannerH = 24.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Banner slot (always occupies bannerH, even when hidden) ──────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            ),
            child: hasBags
                ? _MarqueeBanner(
              key: ValueKey('banner_$count'),
              bagCount: count,
              height: bannerH,
              isGridMode: isGridMode,
            )
                : const SizedBox.shrink(key: ValueKey('banner_empty')),
          ),

          // ── Card ─────────────────────────────────────────────────────────
          Expanded(
            child: DashboardTileCard(
              title: AppStrings.collectedSampleBags,
              icon: AppAssets.bagsCollected,
              onTap: onTap,
              isGridMode: isGridMode,
            ),
          ),
        ],
      );
    });
  }
}

// ─── Marquee Banner ───────────────────────────────────────────────────────────

class _MarqueeBanner extends StatefulWidget {
  final int bagCount;
  final double height;
  final bool isGridMode;

  const _MarqueeBanner({
    super.key,
    required this.bagCount,
    required this.height,
    required this.isGridMode,
  });

  @override
  State<_MarqueeBanner> createState() => _MarqueeBannerState();
}

class _MarqueeBannerState extends State<_MarqueeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  String get _message {
    final n = widget.bagCount;
    final label = n == 1 ? 'bag' : 'bags';
    // Padding at the end creates natural gap between repetitions
    return '🧪  You have $n $label  •  Submit to lab or hand over          ';
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      // Speed: tweak duration to taste — 18s feels natural for ~50 chars
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.isGridMode ? 20.0 : 18.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0D2A4A) : const Color(0xFFE3F2FD);
    final borderColor =
    isDark ? const Color(0xFF1E5A9C) : const Color(0xFF90CAF9);
    final textColor =
    isDark ? const Color(0xFF90CAF9) : const Color(0xFF0D47A1);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use available width from LayoutBuilder — device-safe
        final availableWidth = constraints.maxWidth;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radius),
              topRight: Radius.circular(radius),
            ),
            border: Border(
              top: BorderSide(color: borderColor, width: 1.2),
              left: BorderSide(color: borderColor, width: 1.2),
              right: BorderSide(color: borderColor, width: 1.2),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: _MarqueeContent(
            text: _message,
            textColor: textColor,
            controller: _ctrl,
            availableWidth: availableWidth,
          ),
        );
      },
    );
  }
}

// ─── Marquee Content ─────────────────────────────────────────────────────────
// Measures text once via TextPainter (no GlobalKey / postFrameCallback needed),
// then drives pixel offset from AnimationController.value. Works on any width.

class _MarqueeContent extends StatelessWidget {
  final String text;
  final Color textColor;
  final AnimationController controller;
  final double availableWidth;

  const _MarqueeContent({
    required this.text,
    required this.textColor,
    required this.controller,
    required this.availableWidth,
  });

  static const _style = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1,
  );

  double _measureTextWidth(String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _style.copyWith(color: textColor)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final textWidth = _measureTextWidth(text);

    // If text is shorter than available width, no need to scroll
    if (textWidth <= availableWidth) {
      return Center(
        child: Text(
          text.trim(),
          style: _style.copyWith(color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Pixel offset: 0 → textWidth, then seamlessly resets
        final offset = (controller.value * textWidth) % textWidth;

        return Stack(
          children: [
            // First copy
            Positioned(
              left: -offset,
              top: 0,
              bottom: 0,
              width: textWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  style: _style.copyWith(color: textColor),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
            // Second copy — seamlessly follows the first
            Positioned(
              left: textWidth - offset,
              top: 0,
              bottom: 0,
              width: textWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  style: _style.copyWith(color: textColor),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}/*
class CollectedBagsTileWithBanner extends StatelessWidget {
  final VoidCallback onTap;
  final bool isGridMode;

  const CollectedBagsTileWithBanner({
    super.key,
    required this.onTap,
    required this.isGridMode,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Obx(() {
      final count = controller.collectedBagsCount.value;
      final hasBags = count > 0;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(top: hasBags ? 0 : 0),
            child: DashboardTileCard(
              title: AppStrings.collectedSampleBags,
              icon: AppAssets.bagsCollected,
              onTap: onTap,
              isGridMode: isGridMode,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: hasBags
                ? _CollectedBagsBanner(
              key: ValueKey(count),
              bagCount: count,
              isGridMode: isGridMode,
            )
                : const SizedBox.shrink(),
          ),

        ],
      );
    });
  }
}
*/
// ─── Banner ───────────────────────────────────────────────────────────────────

/*class _CollectedBagsBanner extends StatefulWidget {
  final int bagCount;
  final bool isGridMode;

  const _CollectedBagsBanner({
    super.key,
    required this.bagCount,
    required this.isGridMode,
  });

  @override
  State<_CollectedBagsBanner> createState() => _CollectedBagsBannerState();
}

class _CollectedBagsBannerState extends State<_CollectedBagsBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _marquee;
  final _textKey = GlobalKey();
  double _singleTextWidth = 0;

  String get _text {
    final n = widget.bagCount;
    final bag = n == 1 ? 'bag' : 'bags';
    return '🧪 You have $n $bag with you  •  Please submit to lab or hand over        ';
  }

  @override
  void initState() {
    super.initState();
    _marquee = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Measure text width after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _textKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        setState(() => _singleTextWidth = box.size.width);
      }
    });
  }

  @override
  void dispose() {
    _marquee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.isGridMode ? 20.0 : 24.0;
    final text = _text;

    return Container(
      height: 22,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ),
        border: const Border(
          top: BorderSide(color: Color(0xFF90CAF9), width: 1.2),
          left: BorderSide(color: Color(0xFF90CAF9), width: 1.2),
          right: BorderSide(color: Color(0xFF90CAF9), width: 1.2),
        ),
      ),
      child: AnimatedBuilder(
        animation: _marquee,
        builder: (context, child) {
          // Offset cycles from 0 → singleTextWidth, then resets seamlessly
          final offset = _singleTextWidth > 0
              ? (_marquee.value * _singleTextWidth) % _singleTextWidth
              : 0.0;

          return Stack(
            children: [
              Positioned(
                left: -offset,
                top: 0,
                bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Hidden measurer (only used once for width)
                    if (_singleTextWidth == 0)
                      _buildText(text, key: _textKey)
                    else ...[
                      _buildText(text),
                      _buildText(text), // 2 copies is enough once width is known
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildText(String text, {Key? key}) {
    return Text(
      key: key,
      text,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0D47A1),
        letterSpacing: 0.15,
        height: 1,
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
    );
  }
}*/




