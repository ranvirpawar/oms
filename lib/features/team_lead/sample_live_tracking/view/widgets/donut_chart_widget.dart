import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';


import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';

class DonutChartWidget extends StatelessWidget {
  final Map<String, int> distribution;

  const DonutChartWidget({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final entries = distribution.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text('No bag activity yet today', style: AppTextStyles.bodySecondary),
        ),
      );
    }

    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    final sections = <PieChartSectionData>[
      for (var i = 0; i < entries.length; i++)
        PieChartSectionData(
          value: entries[i].value.toDouble(),
          color: AppColors.chartColors[i % AppColors.chartColors.length],
          radius: 22,
          showTitle: false,
        ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 38,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'Active\nBags',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length; i++)
                _legend(
                  entries[i].key,
                  entries[i].value,
                  total,
                  AppColors.chartColors[i % AppColors.chartColors.length],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(String label, int value, int total, Color color) {
    final pct = total > 0 ? ((value / total) * 100).toStringAsFixed(1) : '0.0';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary, overflow: TextOverflow.ellipsis)),
          Text('$value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(width: 3),
          Text('($pct%)', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
