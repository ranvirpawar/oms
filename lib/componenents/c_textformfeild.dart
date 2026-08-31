import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CFormTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String iconPath;
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

  const CFormTextField({
    super.key,
     this.controller,
    required this.label,
    required this.iconPath,
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
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation??0,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor?? Theme.of(context).primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          /* maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,*/
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              color: iconColor?? Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        children: isRequired
                            ? [
                                const TextSpan(
                                  text: ' *',
                                  style: TextStyle(color: Colors.red),
                                )
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
                      prefixStyle:  const TextStyle(
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
