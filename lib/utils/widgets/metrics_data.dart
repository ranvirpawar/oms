import 'package:flutter/material.dart';

class MetricData {
  final String value;
  final String label;
  final IconData? icon;          // optional now
  final Color dot;

  const MetricData({
    required this.value,
    required this.label,
    this.icon,
    required this.dot,
  });
}

class MetricCell extends StatelessWidget {
  final MetricData data;
  final double valueFontSize;
  final double labelFontSize;

  const MetricCell({
    super.key,
    required this.data,
    this.valueFontSize = 19,
    this.labelFontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.dot,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                data.value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF161A2B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /*if (data.icon != null) ...[
                Icon(data.icon, size: 14, color: Colors.black.withOpacity(0.4)),
                const SizedBox(width: 4),
              ],*/
              Expanded(
                child: Text(
                  data.label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: Colors.black.withOpacity(0.5),
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