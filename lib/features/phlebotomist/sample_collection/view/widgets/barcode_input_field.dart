import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../theme/app_colors.dart';
import '../../controller/sample_collection_controller.dart';
import '../../model/barcode_formatter.dart';

class BarcodeInputField extends StatelessWidget {
  final SampleBarcodeEntry entry;
  final VoidCallback onScanTap;
  final ValueChanged<String> onChanged;

  const BarcodeInputField({
    super.key,
    required this.entry,
    required this.onScanTap,
    required this.onChanged,
  });

  static const _errorStatuses = {
    BarcodeCheckStatus.unavailable,
    BarcodeCheckStatus.duplicate,
    BarcodeCheckStatus.formatError,
    BarcodeCheckStatus.error,
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = entry.barcodeStatus.value;
      final hasError = _errorStatuses.contains(status);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.grayLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? AppColors.redText
                    : status == BarcodeCheckStatus.available
                    ? AppColors.greenBorder
                    : Colors.transparent,
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
                    controller: entry.barcodeController,
                    onChanged: onChanged,
                    maxLength: 15,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                    ],

                    decoration: InputDecoration(
                      isDense: true,
                      counterText: '',
                      hintText: 'Enter or scan barcode',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      suffixIcon: _VerificationSuffix(status: status),
                    ),
                  ),
                ),

                const SizedBox(width: 4),
                _ScanButton(onTap: onScanTap),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: hasError
                ? Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_rounded, size: 13, color: AppColors.redText),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      entry.barcodeMessage.value,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.redText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }
}

/// Suffix icon reflecting live verification state: spinner while checking,
/// a check for verified/available, an error mark otherwise.
class _VerificationSuffix extends StatelessWidget {
  final BarcodeCheckStatus status;
  const _VerificationSuffix({required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
      child: switch (status) {
        BarcodeCheckStatus.checking => const SizedBox(
          key: ValueKey('checking'),
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
        ),
        BarcodeCheckStatus.available => const Icon(
          Icons.verified_rounded,
          key: ValueKey('verified'),
          size: 18,
          color: AppColors.greenText,
        ),
        BarcodeCheckStatus.unavailable ||
        BarcodeCheckStatus.duplicate ||
        BarcodeCheckStatus.formatError ||
        BarcodeCheckStatus.error =>
        const Icon(
          Icons.error_rounded,
          key: ValueKey('error'),
          size: 18,
          color: AppColors.redText,
        ),
        BarcodeCheckStatus.idle => const SizedBox.shrink(key: ValueKey('idle')),
      },
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
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.qr_code_scanner_rounded, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}


/*class BarcodeInputField extends StatelessWidget {
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
}*/
/*

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
}*/
