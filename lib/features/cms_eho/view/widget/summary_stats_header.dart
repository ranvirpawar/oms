// ─────────────────────────────────────────────────────────────────────────────
// summary_stats_header.dart
//
// The hero stats strip at the top of the dashboard showing:
//   • Total facilities
//   • Total patients served
//   • Overall completion %
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../model/consumption_model.dart';

class SummaryStatsHeader extends StatelessWidget {
  final List<ConsumptionModel> data;

  const SummaryStatsHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final totalFacilities =
        data.map((e) => e.fType).toSet().length;
    final totalPatients = data.fold(0, (s, e) => s + e.patCount);
    final totalTarget = data.fold(0, (s, e) => s + e.yearlyTarget);
    final overallPercent =
        totalTarget > 0 ? (totalPatients / totalTarget * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.domain_rounded,
            label: 'Facilities',
            value: totalFacilities.toString(),
            color: AppColors.primary,
          ),
          _divider(),
          _StatChip(
            icon: Icons.people_alt_rounded,
            label: 'Patients',
            value: _fmt(totalPatients),
            color: const Color(0xFF34D399),
          ),
          _divider(),
          _StatChip(
            icon: Icons.track_changes_rounded,
            label: 'Overall',
            value: '${overallPercent.toStringAsFixed(1)}%',
            color: const Color(0xFFFBBF24),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: Colors.white.withOpacity(0.15),
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,

            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,

            ),
          ),
        ],
      ),
    );
  }
}
