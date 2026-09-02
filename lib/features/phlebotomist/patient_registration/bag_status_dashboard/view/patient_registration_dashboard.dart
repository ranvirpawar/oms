// views/patient_registration_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/bag_status_dashboard/view/patient_list_view.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/bag_status_dashboard/view/scan_bag_page.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/bag_status_dashboard/view/widget/bag_detail_view.dart';
import 'package:lifenity_connect/routes/route_manager.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../../constants/app_strings.dart';
import '../../../../../theme/app_colors.dart';
import '../controller/registrarion_bag_controller.dart';
import '../model/qr_bag_details.dart';
import '../model/qr_bag_session.dart';

class PatientRegistrationDashboard extends StatelessWidget {
  const PatientRegistrationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BagRegistrationController());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: CustomAppBar(
        title: AppStrings.bagStatusDashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: AppColors.surfaceContainer),
            onPressed: () => Get.to(() => const PatientListPage()),
          ),
        ],
      ),
      floatingActionButton: Obx(() => controller.isLoading.value
          ? const SizedBox.shrink()
          : FloatingActionButton.extended(
              onPressed: () => Get.to(() => const ScanBagPage()),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text(
                'Open New Bag',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryStrip(controller: controller),
                const SizedBox(height: 24),
                if (controller.hasBags) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 14),
                    child: Text(
                      'Your Bags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A202C),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  ...controller.allSessions.map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _BagCard(
                        session: session,
                        controller: controller,
                      ),
                    ),
                  ),
                ] else
                  _EmptyState(controller: controller),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Summary Strip ────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final BagRegistrationController controller;

  const _SummaryStrip({required this.controller});

  @override
  Widget build(BuildContext context) {
    final open = controller.allSessions.where((s) => s.isOpen).length;
    final closed = controller.allSessions.where((s) => !s.isOpen).length;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Total Bags',
            value: controller.allSessions.length.toString(),
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            label: 'Open',
            value: open.toString(),
            icon: Icons.lock_open_outlined,
            color: const Color(0xFF48BB78),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            label: 'Closed',
            value: closed.toString(),
            icon: Icons.lock_outline,
            color: const Color(0xFFED8936),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Individual Bag Card ──────────────────────────────────────────────────────

class _BagCard extends StatefulWidget {
  final QRBagSession session;
  final BagRegistrationController controller;

  const _BagCard({required this.session, required this.controller});

  @override
  State<_BagCard> createState() => _BagCardState();
}

class _BagCardState extends State<_BagCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    // Auto-expand the open bag
    _expanded = widget.session.isOpen;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: _expanded ? 1.0 : 0.0,
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animController.forward() : _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final ctrl = widget.controller;
    final isOpen = session.isOpen;

    final Color accent =
        isOpen ? const Color(0xFF48BB78) : const Color(0xFFED8936);

    return Obx(() {
      final details = ctrl.bagDetailsMap[session.bagId];

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
            // AFTER
            border: Border.all(
              color: isOpen
                  ? (ctrl.isBagFull(session.bagId)
                  ? const Color(0xFFFC8181).withOpacity(0.5)   // red when full
                  : const Color(0xFF48BB78).withOpacity(0.4))  // green when open & not full
                  : Colors.transparent,
              width: 1.5,
            ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header row ────────────────────────────────────────────────
            GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        isOpen ? Icons.inventory_2 : Icons.inventory_2_outlined,
                        color: accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                session.bagcode,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A202C),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusBadge(isOpen: isOpen),
                            ],
                          ),
                          const SizedBox(height: 3),
                          if (details != null)
                            Text(
                              '${details.patientCount} / ${details.capacity} tubes',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF718096),
                              ),
                            )
                          else
                            const Text(
                              'Tap to view details',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFFB0BAC9)),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 260),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFFB0BAC9),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expandable section ────────────────────────────────────────
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFF0F4F8)),
                  if (details != null) _DetailsBody(details: details),
                  _ActionRow(
                    session: session,
                    controller: ctrl,
                    isOpen: isOpen,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isOpen;

  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? const Color(0xFF48BB78) : const Color(0xFFED8936);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Open' : 'Closed',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isOpen ? const Color(0xFF276749) : const Color(0xFF7B341E),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bag Details Body (inside expanded card) ──────────────────────────────────

class _DetailsBody extends StatelessWidget {
  final QRBagDetails details;

  const _DetailsBody({required this.details});

  @override
  Widget build(BuildContext context) {
    final pct = details.capacity > 0
        ? (details.patientCount / details.capacity).clamp(0.0, 1.0)
        : 0.0;
    final Color fillColor = pct >= 0.9
        ? const Color(0xFFFC8181)
        : pct >= 0.6
            ? const Color(0xFFED8936)
            : const Color(0xFF48BB78);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniStat(
                label: 'Capacity',
                value: details.capacity.toString(),
                icon: Icons.all_inbox_rounded,
                color: const Color(0xFF4299E1),
              ),
              _MiniStat(
                label: 'Tubes',
                value: details.patientCount.toString(),
                icon: Icons.colorize_rounded,
                color: const Color(0xFFED8936),
              ),
              _MiniStat(
                label: 'Vacant',
                value: details.spaceVacant.toString(),
                icon: Icons.inbox_rounded,
                color: const Color(0xFF48BB78),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Space Utilization',
                style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fillColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFFEDF2F7),
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
          ),
        ],
      ),
    );
  }
}

// ─── Action Row per card ──────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final QRBagSession session;
  final BagRegistrationController controller;
  final bool isOpen;

  const _ActionRow({
    required this.session,
    required this.controller,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          // View Details — always visible
          Expanded(
            child: _SmallButton(
              label: 'View',
              icon: Icons.remove_red_eye_outlined,
              color: AppColors.primary,
              outlined: true,
              onTap: () => Get.to(
                () => const BagDetailView(),
                arguments: {
                  'sessionId': session.sessionID,
                  'bagId': session.bagId,
                  'bagcode': session.bagcode,
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (isOpen) ...[
            Expanded(
              child: _SmallButton(
                label: 'Close',
                icon: Icons.lock_outline,
                color: AppColors.secondary,
                outlined: true,
                onTap: () => _confirmClose(context),
              ),
            ),
            const SizedBox(width: 10),
            // AFTER
            Expanded(
              child: _SmallButton(
                label: 'Collect',
                icon: Icons.person_add_alt_1,
                color: controller.isBagFull(session.bagId)
                    ? const Color(0xFFCBD5E0) // greyed out when full
                    : AppColors.primary,
                onTap: () {
                  if (controller.isBagFull(session.bagId)) {
                    _showBagFullSheet(context);
                  } else {
                    RouteManager.navigateToPatientRegistration(
                      session.bagId.toString(),
                    );
                  }
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: _SmallButton(
                label: 'Reopen',
                icon: Icons.lock_open_rounded,
                color: const Color(0xFFED8936),
                onTap: () => _confirmReopen(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
  void _showBagFullSheet(BuildContext context) {
    final details = controller.bagDetailsMap[session.bagId];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BagFullSheet(
        bagcode: session.bagcode,
        details: details,
      ),
    );
  }
  void _confirmClose(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Close Bag?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to close bag ${session.bagcode}? '
          'You can reopen it later if needed.',
          style: const TextStyle(color: Color(0xFF718096)),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.closeBag(session);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Close Bag', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmReopen(BuildContext context) {
    final currentlyOpen = controller.activeBag;
    final willAutoClose =
        currentlyOpen != null && currentlyOpen.bagId != session.bagId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reopen Bag?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reopen bag ${session.bagcode}?',
              style: const TextStyle(color: Color(0xFF718096)),
            ),
            if (willAutoClose) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFED8936), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFED8936), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bag ${currentlyOpen.bagcode} will be automatically closed.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7B341E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.reopenBag(session);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFED8936),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reopen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Bag Full Bottom Sheet ────────────────────────────────────────────────────

class _BagFullSheet extends StatelessWidget {
  final String bagcode;
  final QRBagDetails? details;

  const _BagFullSheet({required this.bagcode, this.details});

  @override
  Widget build(BuildContext context) {
    final capacity = details?.capacity ?? 0;
    final filled = details?.patientCount ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Icon with pulsing red ring
          _FullBagIcon(),

          const SizedBox(height: 20),

          // Title
          const Text(
            'Bag Is Full',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A202C),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bag $bagcode has reached its maximum capacity.\nPlease open a new bag to continue registering.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 28),

          // Capacity visual
          if (details != null) ...[
            _CapacityBar(filled: filled, capacity: capacity),
            const SizedBox(height: 28),
          ],

          // CTA row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF718096),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.to(() => const ScanBagPage());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text(
                    'Open New Bag',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing icon ─────────────────────────────────────────────────────────────

class _FullBagIcon extends StatefulWidget {
  @override
  State<_FullBagIcon> createState() => _FullBagIconState();
}

class _FullBagIconState extends State<_FullBagIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFC8181).withOpacity(0.12),
          border: Border.all(
            color: const Color(0xFFFC8181).withOpacity(0.35),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.inventory_2,
          color: Color(0xFFE53E3E),
          size: 36,
        ),
      ),
    );
  }
}

// ─── Capacity bar ─────────────────────────────────────────────────────────────

class _CapacityBar extends StatelessWidget {
  final int filled;
  final int capacity;
  const _CapacityBar({required this.filled, required this.capacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7D7)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.colorize_rounded,
                      size: 14, color: Color(0xFFE53E3E)),
                  SizedBox(width: 6),
                  Text(
                    'Tubes registered',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF718096),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$filled',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                    TextSpan(
                      text: ' / $capacity',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: capacity > 0 ? (filled / capacity).clamp(0.0, 1.0) : 1.0,
              backgroundColor: const Color(0xFFFED7D7),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53E3E)),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE53E3E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded,
                    size: 12, color: Color(0xFFE53E3E)),
                SizedBox(width: 5),
                Text(
                  'No space available — bag is at full capacity',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE53E3E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small button ─────────────────────────────────────────────────────────────

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _SmallButton({
    required this.label,
    required this.icon,
    required this.color,
    this.outlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withOpacity(0.6)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(icon, size: 15),
              label: Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(icon, size: 15),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final BagRegistrationController controller;

  const _EmptyState({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 52,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Bags Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "Open New Bag" below to scan\na bag and start collecting samples.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Strip ────────────────────────────────────────────────────────────
