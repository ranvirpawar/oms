import 'package:flutter/material.dart';

import 'metrics_data.dart';

class MetricsStrip extends StatelessWidget {
  final List<MetricData> items;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color backgroundColor;
  final List<BoxShadow>? boxShadow;
  final double dividerHeight;
  final Color? dividerColor;
  final CrossAxisAlignment cellAlignment; // ← new
  final Widget Function(Widget child)? animationBuilder;

  const MetricsStrip({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
    this.borderRadius = 20,
    this.backgroundColor = Colors.white,
    this.boxShadow,
    this.dividerHeight = 40,
    this.dividerColor,
    this.cellAlignment = CrossAxisAlignment.center, // default center
    this.animationBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: Row(
        children: List.generate(items.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Container(
              width: 1,
              height: dividerHeight,
              color: dividerColor ?? Colors.black.withOpacity(0.07),
            );
          }
          return Expanded(
            child: MetricCell(
              data: items[i ~/ 2],
              alignment: cellAlignment, // pass it down
            ),
          );
        }),
      ),
    );

    if (animationBuilder != null) {
      return animationBuilder!(content);
    }
    return content;
  }
}