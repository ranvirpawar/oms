// ─── Summary Strip ────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../../../theme/app_colors.dart';
import '../../controller/registrarion_bag_controller.dart';

class SummaryStrip extends StatelessWidget {
  final BagRegistrationController controller;

  const SummaryStrip({super.key, required this.controller});

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