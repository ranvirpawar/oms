import 'package:flutter/material.dart';

class MetricData {
  final String value;
  final String label;
  final IconData? icon; // optional now
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
  final CrossAxisAlignment alignment; // ← new
  final bool reserveTwoLabelLines;

  const MetricCell({
    super.key,
    required this.data,
    this.valueFontSize = 19,
    this.labelFontSize = 11,
    this.alignment = CrossAxisAlignment.center, // default = center
    this.reserveTwoLabelLines = false,
  });

  Widget _fitValue(BuildContext context, Widget child) {
    if (!reserveTwoLabelLines) return child;
    return SizedBox(
      height: MediaQuery.textScalerOf(context).scale(valueFontSize) * 1.2,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment == CrossAxisAlignment.center
            ? Alignment.center
            : Alignment.centerLeft,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCenter = alignment == CrossAxisAlignment.center;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: alignment,
        children: [
          _fitValue(
            context,
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isCenter
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
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
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: reserveTwoLabelLines
                ? MediaQuery.textScalerOf(context).scale(labelFontSize) *
                      1.2 *
                      2
                : null,
            child: Text(
              data.label,
              maxLines: reserveTwoLabelLines ? 2 : null,
              overflow: reserveTwoLabelLines ? TextOverflow.ellipsis : null,
              textAlign: isCenter ? TextAlign.center : TextAlign.start,
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
    );
  }
}
