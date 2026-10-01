import 'dart:math';

import 'package:flutter/material.dart';

import '../../../utils/widgets/metrics_data.dart';
import 'dashboard_summary_model.dart';

/// Random accents are generated once per column, so refreshes don't change them.
class DashboardMetrics {
  final Random _random;
  final Map<String, Color> _colors = {};

  DashboardMetrics({Random? random}) : _random = random ?? Random();

  List<MetricData> build(List<DashboardSummaryMetric> metrics) => metrics
      .map(
        (metric) => MetricData(
          value: metric.value.toString().padLeft(2, '0'),
          label: metric.label,
          dot: _colors.putIfAbsent(
            DashboardSummaryItem.normalizeKey(metric.key),
            () => HSLColor.fromAHSL(
              1,
              _random.nextDouble() * 360,
              0.65,
              0.40,
            ).toColor(),
          ),
        ),
      )
      .toList();
}
