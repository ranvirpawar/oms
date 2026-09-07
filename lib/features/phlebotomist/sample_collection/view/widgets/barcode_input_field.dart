import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../theme/app_colors.dart';



class BarcodeInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onScanTap;
  final ValueChanged<String> onChanged;
  final bool hasError;

  const BarcodeInputField({
    super.key,
    required this.controller,
    required this.onScanTap,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? AppColors.redText : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.numbers_rounded, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLength: 14,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              decoration: const InputDecoration(
                isDense: true,
                counterText: '',
                hintText: 'Enter or scan barcode',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w400),
                border: InputBorder.none,
              ),
            ),
          ),
          _ScanButton(onTap: onScanTap),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: AppColors.accent700,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.qr_code_scanner_rounded, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}