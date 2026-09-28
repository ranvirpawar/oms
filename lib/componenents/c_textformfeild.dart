import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CFormTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? iconPath;
  final bool isRequired;
  final bool isReadOnly;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final Widget? suffix;
  final bool isTextSuffix;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final String? prefixText;
  final String? initialValue;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? elevation;
  final bool labelAbove;
  final Widget? labelPrefix;

  const CFormTextField({
    super.key,
    this.controller,
    required this.label,
    this.iconPath,
    this.isRequired = true,
    this.isReadOnly = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.suffix,
    this.onChanged,
    this.isTextSuffix = false,
    this.prefixText,
    this.initialValue,
    this.iconColor,
    this.backgroundColor,
    this.elevation,
    this.labelAbove = false,
    this.labelPrefix,
  });

  @override
  Widget build(BuildContext context) {
    if (labelAbove) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (labelPrefix != null) ...[
                labelPrefix!,
                const SizedBox(width: 6),
              ],
              Text.rich(
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                  children: isRequired
                      ? [
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(color: Colors.red),
                          ),
                        ]
                      : [],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            elevation: elevation ?? 0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (iconPath != null) ...[
                    SvgPicture.asset(
                      iconPath!,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        iconColor ?? Theme.of(context).primaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: TextFormField(
                      initialValue: initialValue,
                      controller: controller,
                      keyboardType: keyboardType,
                      readOnly: isReadOnly,
                      maxLines: maxLines,
                      maxLength: maxLength,
                      onChanged: onChanged,
                      inputFormatters: inputFormatters,
                      decoration: InputDecoration(
                        prefixText: prefixText,
                        prefixStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF111827),
                        ),
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: isReadOnly
                            ? const Color(0xFF1F2937)
                            : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (suffix != null)
                    isTextSuffix
                        ? suffix!
                        : SizedBox(
                            width: 24,
                            height: 24,
                            child: Center(child: suffix),
                          ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Material(
      elevation: elevation ?? 0,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color:
              backgroundColor ??
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (iconPath != null) ...[
              SvgPicture.asset(
                iconPath!,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  iconColor ?? Theme.of(context).primaryColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        text: label,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        children: isRequired
                            ? [
                                const TextSpan(
                                  text: ' *',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ]
                            : [],
                      ),
                    ),
                  ),
                  TextFormField(
                    initialValue: initialValue,
                    controller: controller,
                    keyboardType: keyboardType,
                    readOnly: isReadOnly,
                    maxLines: maxLines,
                    maxLength: maxLength,
                    onChanged: onChanged,
                    inputFormatters: inputFormatters,
                    decoration: InputDecoration(
                      prefixText: prefixText,
                      prefixStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (suffix != null)
              isTextSuffix
                  ? suffix!
                  : SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(child: suffix),
                    ),
          ],
        ),
      ),
    );
  }
}
