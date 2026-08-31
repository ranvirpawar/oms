import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomDisplayTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String iconPath;
  final bool isRequired;
  final bool isReadOnly;
  final TextInputType keyboardType;
  final int maxLines;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const CustomDisplayTextField({
    super.key,
    this.controller,
    required this.label,
    required this.iconPath,
    this.isRequired = true,
    this.isReadOnly = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Default styles matching ModernDropdown
    final TextStyle defaultLabelStyle = TextStyle(
      fontSize: 12,
      color: Colors.grey[600],
    );
    final TextStyle defaultValueStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: Colors.black,
    );

    final resolvedLabelStyle = labelStyle ?? defaultLabelStyle;
    final resolvedValueStyle = valueStyle ?? defaultValueStyle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment:
        maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      text: label,
                      style: resolvedLabelStyle,
                      children: isRequired
                          ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
                          : [],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Value display
                TextField(
                  readOnly: true,
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  style: resolvedValueStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
