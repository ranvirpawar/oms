import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

// info_row_widget.dart
class InfoRow extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final EdgeInsets padding;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;
  final Color? iconColor;
  final double? iconSize;
  final Color? valueColor;


  const InfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.padding = EdgeInsets.zero,
    this.titleStyle,
    this.valueStyle,
    this.iconColor,
    this.iconSize,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultIconColor = iconColor ?? theme.primaryColor;

    final defaultTitleStyle = titleStyle ??
        TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        );
    final defaultValueStyle = valueStyle ??
        TextStyle(
          color: valueColor ?? Colors.black,

          fontSize: 12,
          fontWeight: FontWeight.w600,
        );

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // add container to icon
          SvgPicture.asset(
            icon,
            color: defaultIconColor,
            width: iconSize ?? 20,
            height: iconSize ?? 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: defaultTitleStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: defaultValueStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// Data class to hold row information
class InfoRowData {
  final String icon;
  final String title;
  final String value;

  InfoRowData({
    required this.icon,
    required this.title,
    required this.value,
  });
}