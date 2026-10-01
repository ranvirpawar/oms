import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../utils/widgets/metrics_data.dart';
import '../../../../utils/widgets/metrics_strip.dart';

/// Fit up to five columns in one row; scroll only for additional columns.
class DashboardMetricsStrip extends StatelessWidget {
  final List<MetricData> items;
  final Widget Function(Widget child)? animationBuilder;

  const DashboardMetricsStrip({
    super.key,
    required this.items,
    this.animationBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = max(
          constraints.maxWidth,
          items.length * MediaQuery.textScalerOf(context).scale(90),
        );
        final strip = SizedBox(
          width: width,
          child: MetricsStrip(
            items: items,
            reserveTwoLabelLines: true,
            cellAlignment: items.length > 3
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
          ),
        );
        final content = items.length <= 5
            ? SizedBox(
                width: constraints.maxWidth,
                child: FittedBox(fit: BoxFit.scaleDown, child: strip),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: strip,
              );
        return animationBuilder?.call(content) ?? content;
      },
    );
  }
}
