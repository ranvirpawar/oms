import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Owns *only* the scroll behaviour of the Patient Queue header.
///
/// Behaviour ("quick return" header):
///  • Scrolling down  → app bar + visit-type row slide away with the finger,
///    the status filter chips stay pinned at the top.
///  • Scrolling up    → app bar + visit-type row slide back in immediately,
///    tracking the finger (no need to reach the top of the list).
///  • When scrolling stops with the header half-way, it eases to whichever
///    end is closer (biased by the last scroll direction).
///
/// Register it next to PatientQueueController in the binding:
///   Get.lazyPut(() => PatientQueueScrollController());
class PatientQueueScrollController extends GetxController
    with GetSingleTickerProviderStateMixin {
  /// Height of the part that slides away (toolbar + visit-type row).
  /// -1 until the first layout pass has measured it.
  final RxDouble collapsibleHeight = (-1.0).obs;

  /// Height of the part that stays pinned (status filter chips).
  /// -1 until measured. Can change (e.g. clinic chips appear for Clinic visits).
  final RxDouble pinnedHeight = (-1.0).obs;

  /// How many px the collapsible part is currently pushed up.
  /// 0 = fully visible, collapsibleHeight = fully hidden.
  /// A ValueNotifier (not Rx) so only a tiny AnimatedBuilder rebuilds per frame.
  final ValueNotifier<double> hiddenOffset = ValueNotifier<double>(0);

  /// True once the list has scrolled under the pinned chips (drives the shadow).
  final ValueNotifier<bool> hasScrolled = ValueNotifier<bool>(false);

  late final AnimationController _snap;
  Animatable<double>? _snapTween;
  bool _revealing = false;

  bool get isReady => collapsibleHeight.value >= 0 && pinnedHeight.value >= 0;

  @override
  void onInit() {
    super.onInit();
    _snap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        final tween = _snapTween;
        if (tween != null) hiddenOffset.value = tween.evaluate(_snap);
      });
  }

  // ── Measurements (reported by the header widget) ──────────────────────────

  void setCollapsibleHeight(double h) {
    if ((collapsibleHeight.value - h).abs() < 0.5) return;
    collapsibleHeight.value = h;
    if (hiddenOffset.value > h) hiddenOffset.value = h;
  }

  void setPinnedHeight(double h) {
    if ((pinnedHeight.value - h).abs() < 0.5) return;
    pinnedHeight.value = h;
  }

  // ── Scroll handling ───────────────────────────────────────────────────────

  /// Hook this up to a NotificationListener around the list.
  /// Always returns false so other listeners (RefreshIndicator) still see it.
  bool handleScroll(ScrollNotification n) {
    // Ignore horizontal scrollables nested inside cards.
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;

    final maxHidden = collapsibleHeight.value;
    if (maxHidden <= 0) return false;

    if (n is ScrollStartNotification) {
      _snap.stop(); // user grabbed the list mid-snap
    } else if (n is ScrollUpdateNotification) {
      final delta = n.scrollDelta ?? 0;
      if (delta == 0) return false;

      final pixels = n.metrics.pixels;
      // Ignore rubber-band overscroll at the bottom edge.
      if (pixels > n.metrics.maxScrollExtent) return false;

      _revealing = delta < 0;

      // The header follows the finger 1:1 …
      var next = (hiddenOffset.value + delta).clamp(0.0, maxHidden);
      // … but never hides more than the list has actually scrolled, so near
      // the top it moves exactly like ordinary scrolled content.
      next = math.min(next, math.max(pixels, 0.0));

      hiddenOffset.value = next;
      hasScrolled.value = pixels > 1;
    } else if (n is ScrollEndNotification) {
      _settle(n.metrics.pixels);
    }
    return false;
  }

  void _settle(double pixels) {
    final maxHidden = collapsibleHeight.value;
    // Near the top the header is tied to the list — nothing to snap.
    if (pixels < maxHidden) return;

    final hidden = hiddenOffset.value;
    if (hidden <= 0 || hidden >= maxHidden) return;

    // Scrolling up: finish revealing once ~30% is visible.
    // Scrolling down: finish hiding once ~70% is visible.
    final hiddenFraction = hidden / maxHidden;
    final collapse = hiddenFraction > (_revealing ? 0.7 : 0.3);
    _animateTo(collapse ? maxHidden : 0);
  }

  void _animateTo(double target) {
    final from = hiddenOffset.value;
    if (from == target) return;
    _snapTween = Tween<double>(begin: from, end: target)
        .chain(CurveTween(curve: Curves.easeOutCubic));
    _snap.forward(from: 0);
  }

  /// Slide the header back in (e.g. after a manual refresh).
  void reveal() => _animateTo(0);

  /// Back to the initial state — called whenever the list is rebuilt fresh.
  void reset() {
    _snap.stop();
    hiddenOffset.value = 0;
    hasScrolled.value = false;
  }

  @override
  void onClose() {
    _snap.dispose();
    hiddenOffset.dispose();
    hasScrolled.dispose();
    super.onClose();
  }
}
