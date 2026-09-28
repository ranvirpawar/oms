// active_bag_card.dart
//
// Modern, interactive card shown at the top of the sample collection screen.
// It surfaces the currently-open bag the phlebotomist is collecting into,
// its live capacity, and quick actions to switch/reopen bags (the
// one-open-at-a-time rule lives in BagRegistrationController) or scan a
// brand-new bag.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/routes/route_manager.dart';

import '../../../../../theme/app_colors.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/controller/registrarion_bag_controller.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/model/qr_bag_session.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/view/scan_bag_page.dart';
import '../../controller/bag_context_mixin.dart';
import '../../controller/sample_collection_controller.dart';

// active_bag_card.dart
//
// Modern, interactive card shown at the top of the sample collection screen.
// It surfaces the currently-open bag the phlebotomist is collecting into,
// its live capacity, and quick actions to switch/reopen bags (the
// one-open-at-a-time rule lives in BagRegistrationController) or scan a
// brand-new bag.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/routes/route_manager.dart';

import '../../../../../theme/app_colors.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/controller/registrarion_bag_controller.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/model/qr_bag_session.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status_dashboard/view/scan_bag_page.dart';
import '../../controller/sample_collection_controller.dart';

/// Opens the "switch bag" sheet. Lists every session (open + closed) with
/// capacity, plus actions to reopen a closed bag (which auto-closes the
/// current one), close the open one, or scan a brand-new bag.
Future<void> showBagPicker(BuildContext context, HasBagContext controller,  int? requiredCount,) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,

    backgroundColor: Colors.transparent,
    builder: (_) => _BagPickerSheet(controller: controller, requiredCount: requiredCount),
  );
}

class _BagPickerSheet extends StatelessWidget {
  const _BagPickerSheet({required this.controller, this.requiredCount});

  final HasBagContext controller;
  final int? requiredCount;


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Bag',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Only one bag stays open at a time.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _SheetCloseButton(),
            ],
          ),
          const SizedBox(height: 6),
          Obx(() {
            final sessions = controller.bagController.allSessions;
            if (sessions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No bags found yet.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
              );
            }
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.42,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sessions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (_, i) =>
                    _BagRow(controller: controller, session: sessions[i], requiredCount: requiredCount ?? 0 ),
              ),
            );
          }),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).maybePop();
                Get.to(() => const ScanBagPage());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
              label: const Text(
                'Scan New Bag',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ),
          /*  const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).maybePop();
                RouteManager.navigateToBagStatusDashboard();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary800,
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 16),
              label: const Text(
                'View all bags',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),*/
        ],
      ),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
    );
  }
}

class _BagRow extends StatelessWidget {
  const _BagRow({
    required this.controller,
    required this.session,
    required this.requiredCount,
  });

  final HasBagContext controller;
  final QRBagSession session;
  final int requiredCount;

  @override
  Widget build(BuildContext context) {
    // Obx here: bagDetailsMap is reactive and details load asynchronously.
    return Obx(() {
      final details = controller.bagController.bagDetailsMap[session.bagId];
      final isOpen = session.isOpen;

      final hasDetails = details != null && details.capacity > 0;
      final used = details?.patientCount ?? 0;
      final capacity = details?.capacity ?? 0;
      final vacant = (details?.spaceVacant ?? 0).clamp(0, 9999);

      final isFull = hasDetails && used >= capacity;
      final notEnoughSpace =
          hasDetails && !isFull && requiredCount > 0 && vacant < requiredCount;
      final canOpen = hasDetails && !isFull && !notEnoughSpace;

      String subtitle;
      if (!hasDetails) {
        subtitle = details == null ? 'Loading capacity…' : 'No capacity info';
      } else {
        subtitle = '$used of $capacity used · $vacant vacant';
      }

      String? hint;
      Color hintColor = AppColors.redText;
      if (isFull) {
        hint = 'Bag is full';
      } else if (notEnoughSpace) {
        hint = 'Needs $requiredCount slots, only $vacant vacant';
        hintColor = AppColors.amberText;
      }

      Widget trailing;
      if (isOpen) {
        trailing = _CloseButton(session: session);
      } else if (canOpen) {
        trailing = _ReopenButton(session: session);
      } else if (details == null) {
        trailing = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      } else {
        trailing = _StatusChip(
          label: isFull ? 'Full' : 'Low space',
          color: hintColor,
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isOpen ? AppColors.primaryGradient : null,
                color: isOpen ? null : AppColors.grayLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 20,
                color: isOpen ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          session.bagcode.isEmpty
                              ? 'Bag #${session.bagId}'
                              : session.bagcode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isOpen) ...[
                        const SizedBox(width: 8),
                        const _OpenChip(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hintColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      );
    });
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _OpenChip extends StatelessWidget {
  const _OpenChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Open',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.greenText,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.session});

  final QRBagSession session;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _confirmCloseBag(context, session),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.redText,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: const Size(0, 36),
      ),
      child: const Text(
        'Close',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _ReopenButton extends StatelessWidget {
  const _ReopenButton({required this.session});

  final QRBagSession session;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () => confirmOpenBag(
        context,
        session,
        onConfirmed: () => Navigator.of(context).maybePop(),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary100,
        foregroundColor: AppColors.primary900,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text(
        'Open',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

// ─── Confirmations ───────────────────────────────────────────────────────────

/// Asks for confirmation, then reopens [session] (a closed bag) via the
/// shared [BagRegistrationController].
///
/// [onConfirmed] lets sheet-based callers close their picker before the
/// reopen fires; callers without a sheet underneath (e.g. the
/// order-confirmation banner) omit it so nothing else gets popped.
Future<void> confirmOpenBag(
  BuildContext context,
  QRBagSession session, {
  VoidCallback? onConfirmed,
}) async {
  final bagController = Get.find<BagRegistrationController>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        session.isOpen ? 'Open this bag?' : 'Reopen this bag?',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: Text(
        bagController.hasOpenBag
            ? 'Opening "${session.bagcode}" will automatically close the bag '
                  'that is currently open. Continue?'
            : '${session.isOpen ? 'Open' : 'Reopen'} "${session.bagcode}" and '
                  'start collecting into it?',
        style: const TextStyle(fontSize: 13, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary700),
          child: Text(session.isOpen ? 'Open Bag' : 'Reopen Bag'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    onConfirmed?.call();
    await bagController.reopenBag(session);
  }
}

Future<void> _confirmCloseBag(
  BuildContext context,
  QRBagSession session,
) async {
  final bagController = Get.find<BagRegistrationController>();
  // Capture the navigator up-front so it is safe to use after the await.
  final navigator = Navigator.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Close this bag?',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: const Text(
        'Once closed, no more samples can be added to this bag.',
        style: TextStyle(fontSize: 13, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.redText),
          child: const Text('Close Bag'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    navigator.maybePop(); // close the picker
    await bagController.closeBag(session);
  }
}

Color _colorFor(double ratio) {
  if (ratio >= 0.9) return AppColors.redText;
  if (ratio >= 0.6) return AppColors.amberText;
  return AppColors.greenText;
}
