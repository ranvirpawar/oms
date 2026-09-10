import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../../../../../theme/app_colors.dart';
import '../../../patient_registration/bag_status_dashboard/view/scan_bag_page.dart';
import '../../controller/bag_context_mixin.dart';

import 'active_bag_card.dart';

import 'package:flutter/services.dart';

class BagContextBanner extends StatelessWidget {
  final HasBagContext bagContext;

  /// Whether this instance lives on the sample-collection page. Only there
  /// can the phlebo act on the bag state (reopen / start new bag) — every
  /// other page that reuses this card (e.g. an order/detail summary) is
  /// read-only and should show the exact same information with no CTAs.
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
      final looksOpen = bagContext.hasOpenBag &&
          (bagContext.activeBagId > 0 || bagContext.activeBagcode.isNotEmpty);

      return _PremiumCard(
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
  const _PremiumCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
  final dynamic bag; // BagController (typed dynamic to avoid an import cycle here)
  final bool showActions;

  const _NoOpenBagContent({
    super.key,
    required this.controller,
    required this.bag,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    final closedSessions = (bag.allSessions as List).where((s) => !s.isOpen).toList();

    final String message;
    if (closedSessions.isEmpty) {
      message = 'You need to open a bag before you can collect samples for '
          'this order.';
    } else if (closedSessions.length == 1) {
      message = 'Bag ${closedSessions.first.bagcode} is closed. Reopen it to '
          'keep collecting into it, or start a new one.';
    } else {
      message = 'Your bag is closed. Reopen one of your bags to keep '
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
          const SizedBox(height: 14),
          Row(
            children: [
              if (closedSessions.isNotEmpty) ...[
                Expanded(
                  child: _ActionButton(
                    label: closedSessions.length == 1 ? 'Reopen bag' : 'Reopen',
                    filled: true,
                    onTap: () {
                      if (closedSessions.length == 1) {
                        confirmOpenBag(context, closedSessions.first);
                      } else {
                        showBagPicker(context, controller);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'New bag',
                    filled: false,
                    onTap: () => Get.to(() => const ScanBagPage()),
                  ),
                ),
              ] else
                Expanded(
                  child: _ActionButton(
                    label: 'Open new bag',
                    filled: true,
                    onTap: () => Get.to(() => const ScanBagPage()),
                  ),
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
    final color = ratio >= 0.9
        ? AppColors.redText
        : (ratio >= 0.6 ? AppColors.amberText : AppColors.greenText);
    final pct = (ratio * 100).round().clamp(0, 100);
    final insufficient = controller.bagCapacityInsufficient;

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
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collecting into ${controller.activeBagcode.isEmpty ? 'Bag #${controller.activeBagId}' : controller.activeBagcode}',
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
                        ? '${controller.bagUsed} of ${controller.bagCapacity} slots used'
                        : 'Open session',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),
            ),
            if (controller.bagCapacity > 0) ...[
              const SizedBox(width: 8),
              Text('$pct%', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
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
        if (insufficient) ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFECECEF)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 17, color: AppColors.amberText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This order has ${controller.requiredSampleCount} samples, but only '
                      '${controller.bagVacant} slot${controller.bagVacant == 1 ? '' : 's'} left in '
                      'this bag. Start a new bag to keep the whole order together.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 10),
            Builder(builder: (context) {
              final closedSessions =
              (bag.allSessions as List).where((s) => !s.isOpen).toList();
              if (closedSessions.isEmpty) {
                return _ActionButton(
                  label: 'Start new bag',
                  filled: false,
                  onTap: () => Get.to(() => const ScanBagPage()),
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: closedSessions.length == 1 ? 'Reopen bag' : 'Reopen',
                      filled: false,
                      onTap: () {
                        if (closedSessions.length == 1) {
                          confirmOpenBag(context, closedSessions.first);
                        } else {
                          showBagPicker(context, controller);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: 'New bag',
                      filled: false,
                      onTap: () => Get.to(() => const ScanBagPage()),
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ],
    );
  }
}

/// --- Shared pressable CTA ------------------------------------------------
///
/// Real tap target (min 44pt tall) with a physical press response instead of
/// a bare TextButton, so it can never render as an invisible/zero-size tap
/// area.
class _ActionButton extends StatefulWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.filled, required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.filled ? AppColors.primary800 : Colors.transparent,
            border: widget.filled ? null : Border.all(color: AppColors.primary800.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.filled ? Colors.white : AppColors.primary800,
            ),
          ),
        ),
      ),
    );
  }
}




/*
class BagContextBanner extends StatelessWidget {
  final OrderConfirmationController controller;

  const BagContextBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Obx(() {
          final bag = controller.bagController;
          // Hide while the very first session fetch is still in flight.
          if (bag.isLoading.value && !bag.hasBags) return const SizedBox.shrink();

          if (!controller.hasOpenBag) {
            // Closed assigned bags can be reopened — don't force the phlebo
            // through the new-bag scan flow when their own bag just needs
            // reopening.
            final closedSessions = bag.allSessions.where((s) => !s.isOpen).toList();
            final message = closedSessions.isEmpty
                ? 'No open bag — open one so samples can be tagged to it.'
                : closedSessions.length == 1
                ? 'Bag ${closedSessions.first.bagcode} is closed — reopen it '
                'so samples can be tagged to it.'
                : 'No open bag — reopen one of your closed bags to continue.';

            return Column(
              children: [

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.amberLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.amberBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: AppColors.amberText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (closedSessions.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            if (closedSessions.length == 1) {
                              confirmOpenBag(context, closedSessions.first);
                            } else {
                              showBagPicker(context, controller);
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary800,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text(
                            'Reopen',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () => Get.to(() => const ScanBagPage()),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary800,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                        ),
                        child: Text(
                          closedSessions.isEmpty ? 'Open' : 'New',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          final ratio = controller.bagFillRatio;
          final color = ratio >= 0.9
              ? AppColors.redText
              : (ratio >= 0.6 ? AppColors.amberText : AppColors.greenText);
          final pct = (ratio * 100).round().clamp(0, 100).toInt();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.emerald200),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
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
                        'Collecting into ${controller.activeBagcode.isEmpty ? 'Bag #${controller.activeBagId}' : controller.activeBagcode}',
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
                            ? '${controller.bagUsed} of ${controller.bagCapacity} slots used'
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
          );
        }),
      ],
    );
  }
}*/
