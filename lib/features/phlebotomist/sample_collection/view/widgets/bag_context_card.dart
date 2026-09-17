import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../theme/app_colors.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/view/scan_bag_page.dart';
import '../../controller/bag_context_mixin.dart';

import 'active_bag_card.dart';

import 'package:flutter/services.dart';

class BagContextBanner extends StatelessWidget {
  final HasBagContext bagContext;

  /// Whether this instance lives on the order confirmation page.
  /// When true, displays full bag status details, capacity/progress, tube requirements,
  /// and actions (reopen / start new bag).
  /// When false (e.g. sample collection page), displays only the compact "Collecting into `bagcode`" card.
  final bool isOrderConfirmationPage;

  const BagContextBanner({
    required this.bagContext,
    this.isOrderConfirmationPage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bag = bagContext.bagController;

      // Hide while the very first session fetch is still in flight.
      if (bag.isLoading.value && !bag.hasBags) return const SizedBox.shrink();

      // Defensive guard: don't trust `hasOpenBag` alone. If it reports open
      // but the active bag id/code hasn't actually resolved yet (e.g. the
      // flag is stale/non-reactive right after a reopen or a new-bag scan),
      // fall back to the "no open bag" state instead of rendering
      // "Collecting into Bag #0" with no way to fix it.
      final looksOpen =
          bagContext.hasOpenBag &&
          (bagContext.activeBagId > 0 || bagContext.activeBagcode.isNotEmpty);

      return _PremiumCard(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isOrderConfirmationPage ? 16 : 12,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: looksOpen
              ? _OpenBagContent(
                  key: const ValueKey('open'),
                  controller: bagContext,
                  bag: bag,
                  showActions: isOrderConfirmationPage,
                )
              : _NoOpenBagContent(
                  key: const ValueKey('closed'),
                  controller: bagContext,
                  bag: bag,
                  showActions: isOrderConfirmationPage,
                ),
        ),
      );
    });
  }
}

/// Shared white "premium" card shell — soft border + layered shadow instead
/// of a flat Material box, so every state (open / closed / warning) lives on
/// one consistent surface.
class _PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _PremiumCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// --- No open bag ------------------------------------------------------

class _NoOpenBagContent extends StatelessWidget {
  final HasBagContext controller;
  final dynamic
  bag; // BagController (typed dynamic to avoid an import cycle here)
  final bool showActions;

  const _NoOpenBagContent({
    super.key,
    required this.controller,
    required this.bag,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    final closedSessions = (bag.allSessions as List)
        .where((s) => !s.isOpen)
        .toList();

    final String message;
    if (closedSessions.isEmpty) {
      message =
          'You need to open a bag before you can collect samples for '
          'this order.';
    } else if (closedSessions.length == 1) {
      message =
          'Bag ${closedSessions.first.bagcode} is closed. Reopen it to '
          'keep collecting into it, or start a new one.';
    } else {
      message =
          'Your bag is closed. Reopen one of your bags to keep '
          'collecting, or start a new one.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.amberLight.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: AppColors.amberText,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bag not open',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showActions) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (closedSessions.isNotEmpty) ...[
                _TextAction(
                  label: 'Reopen bag',
                  onTap: () => showBagPicker(context, controller),
                ),
                const SizedBox(width: 20),
                _TextAction(
                  label: 'New bag',
                  onTap: () => Get.to(() => const ScanBagPage()),
                ),
              ] else
                _TextAction(
                  label: 'Open new bag',
                  onTap: () => Get.to(() => const ScanBagPage()),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// --- Open bag ------------------------------------------------------

class _OpenBagContent extends StatelessWidget {
  final HasBagContext controller;
  final dynamic bag; // BagController
  final bool showActions;
  const _OpenBagContent({
    super.key,
    required this.controller,
    required this.bag,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = controller.bagFillRatio.clamp(0.0, 1.0);
    final isFull = controller.isBagFull;
    final color = isFull
        ? AppColors.error
        : (ratio >= 0.9
              ? AppColors.amberText
              : (ratio >= 0.6 ? AppColors.amberText : AppColors.greenText));
    final pct = (ratio * 100).round().clamp(0, 100);
    final insufficient = controller.bagCapacityInsufficient;
    // clamp to 0 — never show negative vacancy in UI
    final vacantDisplay = controller.bagVacant.clamp(0, 9999);
    final requiredTubes = controller.requiredTubeCount;

    if (!showActions) {
      return Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient:/* isFull
                  ? const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    )
                  :*/ AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isFull ? Icons.inventory_2_outlined : Icons.inventory_2_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Collecting into ${controller.activeBagcode.isEmpty ? 'Bag #${controller.activeBagId}' : controller.activeBagcode}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: /*isFull
                    ? const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      )
                    : */AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isFull ? Icons.inventory_2_outlined : Icons.inventory_2_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collecting into Bag ${controller.activeBagcode}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    controller.bagCapacity > 0
                        ? isFull
                              ? 'Bag is full (${controller.bagUsed}/${controller.bagCapacity})'
                              : '${controller.bagUsed} of ${controller.bagCapacity} slots used · $vacantDisplay left'
                        : 'Open session',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (controller.bagCapacity > 0) ...[
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ],
        ),
        if (controller.bagCapacity > 0) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: const Color(0xFFF0F0F2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],

        // ── Tube count pill ─────────────────────────────────────────────
        if (requiredTubes > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (insufficient || isFull)
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 12,
                      color: (insufficient || isFull)
                          ? AppColors.amberText
                          : AppColors.blueText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Order requires $requiredTubes tube${requiredTubes == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (insufficient || isFull)
                            ? AppColors.amberText
                            : AppColors.blueText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        // ── Bag full banner ─────────────────────────────────────────────
        if (isFull && showActions) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFECECEF)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.block_rounded,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'This bag is full. Reopen another bag or start a new one.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final closedSessions = (bag.allSessions as List)
                  .where((s) => !s.isOpen)
                  .toList();
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (closedSessions.isNotEmpty) ...[
                    _TextAction(
                      label: 'Reopen bag',
                      onTap: () => showBagPicker(context, controller),
                    ),
                    const SizedBox(width: 16),
                  ],
                  _TextAction(
                    label: 'New bag',
                    onTap: () => Get.to(() => const ScanBagPage()),
                  ),
                ],
              );
            },
          ),
        ]
        // ── Insufficient capacity (not yet full) ────────────────────────
        else if (insufficient) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFECECEF)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.amberText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This order needs $requiredTubes tube${requiredTubes == 1 ? '' : 's'} but only '
                  '$vacantDisplay slot${vacantDisplay == 1 ? '' : 's'} remain. '
                  'Start a new bag to keep the order together.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final closedSessions = (bag.allSessions as List)
                    .where((s) => !s.isOpen)
                    .toList();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (closedSessions.isNotEmpty) ...[
                      _TextAction(
                        label: 'Reopen bag',
                        onTap: () => showBagPicker(context, controller),
                      ),
                      const SizedBox(width: 16),
                    ],
                    _TextAction(
                      label: 'New bag',
                      onTap: () => Get.to(() => const ScanBagPage()),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ],
    );
  }
}

/// Lightweight text-only action link — replaces the old elevated/outlined
/// _ActionButton to keep the card compact and avoid heavy visual weight.
class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary800,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primary800,
          ),
        ),
      ),
    );
  }
}
