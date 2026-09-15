import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../theme/app_colors.dart';
import '../../controller/sample_collection_controller.dart';
import '../../model/barcode_formatter.dart';
import '../../model/barcode_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../theme/app_colors.dart';
import '../../controller/sample_collection_controller.dart';
import '../../model/barcode_formatter.dart';
import '../../model/barcode_validator.dart';
import '../../model/sample_collection_models.dart';

class TubeBarcodeGroup extends StatelessWidget {
  final SampleBarcodeEntry entry;
  final SampleCollectionController controller;

  const TubeBarcodeGroup({super.key, required this.entry, required this.controller});

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
      final rows = entry.tubeRows.isEmpty
          ? [TubeRowData(id: 'default', name: 'Tube', isManual: false)]
          : entry.tubeRows;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _TubeRow(
              row: rows[i],
              status: status,
              isPrimary: i == 0, // only the first row is interactive
              barcodeController: entry.barcodeController,
              onScanTap: () => controller.openBarcodeScanner(entry),
              onChanged: (value) => controller.onBarcodeChanged(entry, value),
              onRemove: rows[i].isManual ? () => entry.removeManualTube(rows[i].id) : null,
              onNameChanged: rows[i].isManual ? () => entry.manualTubes.refresh() : null,
            ),
          ],
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
                      style: const TextStyle(fontSize: 11, color: AppColors.redText, fontWeight: FontWeight.w600),
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

class _TubeRow extends StatelessWidget {
  final TubeRowData row;
  final BarcodeCheckStatus status;
  final bool isPrimary;
  final TextEditingController barcodeController;
  final VoidCallback onScanTap;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onNameChanged;

  const _TubeRow({
    required this.row,
    required this.status,
    required this.isPrimary,
    required this.barcodeController,
    required this.onScanTap,
    required this.onChanged,
    this.onRemove,
    this.onNameChanged,
  });

  static const _errorStatuses = {
    BarcodeCheckStatus.unavailable,
    BarcodeCheckStatus.duplicate,
    BarcodeCheckStatus.formatError,
    BarcodeCheckStatus.error,
  };

  @override
  Widget build(BuildContext context) {
    final hasError = _errorStatuses.contains(status);

    return Container(
      height: 44, // was 40 — extra 4px gives the field visual breathing room
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // only the primary row reflects verification status in its border;
          // secondary rows are purely a mirrored display, so they stay neutral
          color: isPrimary
              ? (hasError
              ? AppColors.redText
              : status == BarcodeCheckStatus.available
              ? Colors.transparent
              : Colors.transparent)
              : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
        SizedBox(
        width: 74,
        child: _TubeTag(name: row.name), // now used for both manual and API rows
      ),
          const SizedBox(width: 6),
          Container(width: 1, height: 18, color: AppColors.border),
          const SizedBox(width: 6),
          Expanded(
            child: isPrimary
                ? TextField(
              controller: barcodeController,
              onChanged: onChanged,
              onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
              maxLength: 15,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.characters,
              textAlignVertical: TextAlignVertical.center,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(BarcodeValidator.maxLength),
                _JaaPrefixFormatter(),
              ],
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                isDense: true,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(vertical: 10), // fixes the squashed height
                border: InputBorder.none,
                hintText: 'Enter or scan barcode',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w400),
              ),
            )
                : _ReadOnlyBarcodeValue(controller: barcodeController),
          ),
          // status icon only on the primary row — secondary rows show no
          // verification state of their own since they don't own the value
          if (isPrimary) _VerificationSuffix(status: status),
          if (isPrimary) ...[
            const SizedBox(width: 2),
            _ScanButton(onTap: onScanTap),
          ],
          if (onRemove != null) ...[
            const SizedBox(width: 2),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 15, color: AppColors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Non-interactive mirror of the shared barcode value for every row after
/// the first. It listens to [barcodeController] directly instead of being
/// bound to it, since attaching one controller to multiple TextFields at
/// once is what caused the invisible/overlapping text.
class _ReadOnlyBarcodeValue extends StatelessWidget {
  final TextEditingController controller;
  const _ReadOnlyBarcodeValue({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final text = value.text;
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text.isEmpty ? 'Enter or scan barcode' : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.0,
              color: text.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
        );
      },
    );
  }
}
/*class TubeBarcodeGroup extends StatelessWidget {
  final SampleBarcodeEntry entry;
  final SampleCollectionController controller;

  const TubeBarcodeGroup({
    super.key,
    required this.entry,
    required this.controller,
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
      final rows = entry.tubeRows.isEmpty
          ? [TubeRowData(id: 'default', name: 'Tube', isManual: false)]
          : entry.tubeRows;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _TubeRow(
              row: rows[i],
              status: status,
              barcodeController: entry.barcodeController,
              onScanTap: () => controller.openBarcodeScanner(entry),
              onChanged: (value) => controller.onBarcodeChanged(entry, value),
              onRemove: rows[i].isManual
                  ? () => entry.removeManualTube(rows[i].id)
                  : null,
              onNameChanged: rows[i].isManual ? () => entry.manualTubes.refresh() : null,
            ),
          ],
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

class _TubeRow extends StatelessWidget {
  final TubeRowData row;
  final BarcodeCheckStatus status;
  final TextEditingController barcodeController;
  final VoidCallback onScanTap;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onNameChanged;

  const _TubeRow({
    required this.row,
    required this.status,
    required this.barcodeController,
    required this.onScanTap,
    required this.onChanged,
    this.onRemove,
    this.onNameChanged,
  });

  static const _errorStatuses = {
    BarcodeCheckStatus.unavailable,
    BarcodeCheckStatus.duplicate,
    BarcodeCheckStatus.formatError,
    BarcodeCheckStatus.error,
  };

  @override
  Widget build(BuildContext context) {
    final hasError = _errorStatuses.contains(status);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
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
          SizedBox(
            width: 74,
            child: row.isManual
                ? _ManualTubeNameField(controller: row.nameController!, onChanged: onNameChanged)
                : _TubeTag(name: row.name),
          ),
          const SizedBox(width: 6),
          Container(width: 1, height: 18, color: AppColors.border),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: barcodeController,
              onChanged: onChanged,
              maxLength: 15,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(BarcodeValidator.maxLength),
                _JaaPrefixFormatter(),
              ],
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                counterText: '',
                border: InputBorder.none,
                hintText: 'Enter or scan barcode',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w400),
              ),
            ),
          ),
          _VerificationSuffix(status: status),
          const SizedBox(width: 2),
          _ScanButton(onTap: onScanTap),
          if (onRemove != null) ...[
            const SizedBox(width: 2),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 15, color: AppColors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}*/

/// Compact tube-name tag. Long names (e.g. "Sodium Fluoride vial",
/// "Sterile Urine container") truncate with an ellipsis; the full name is
/// available via long-press/hover tooltip so nothing is ever hidden, just
/// shortened on first glance.
class _TubeTag extends StatelessWidget {
  final String name;
  const _TubeTag({required this.name});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name.isEmpty ? 'Tube' : name,
      waitDuration: const Duration(milliseconds: 350),
      child: Text(
        name.isEmpty ? 'Tube' : name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.accent700,
        ),
      ),
    );
  }
}

/// Inline editable name field for a manually-added tube row.
class _ManualTubeNameField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;

  const _ManualTubeNameField({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged?.call(),
      maxLines: 1,
      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.accent700),
      decoration: const InputDecoration(
        isDense: true,
        isCollapsed: true,
        border: InputBorder.none,
        hintText: 'Tube name',
        hintStyle: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
      ),
    );
  }
}

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
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
        ),
        BarcodeCheckStatus.available => const Icon(
          Icons.verified_rounded,
          key: ValueKey('verified'),
          size: 16,
          color: AppColors.greenText,
        ),
        BarcodeCheckStatus.unavailable ||
        BarcodeCheckStatus.duplicate ||
        BarcodeCheckStatus.formatError ||
        BarcodeCheckStatus.error =>
        const Icon(Icons.error_rounded, key: ValueKey('error'), size: 16, color: AppColors.redText),
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
    return Material(
      color: AppColors.primary700,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _JaaPrefixFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    const prefix = BarcodeValidator.prefix;
    String text = newValue.text.toUpperCase();

    if (!text.startsWith(prefix)) {
      text = prefix + text.replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      final after = text.substring(prefix.length).replaceAll(RegExp(r'[^0-9]'), '');
      text = prefix + after;
    }
    if (text.length > BarcodeValidator.maxLength) {
      text = text.substring(0, BarcodeValidator.maxLength);
    }
    int offset = newValue.selection.baseOffset;
    if (offset < prefix.length) offset = prefix.length;
    if (offset > text.length) offset = text.length;

    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: offset));
  }
}
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
                    keyboardType: TextInputType.number,          // numeric keypad only
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      // Force uppercase + only allow digits after the fixed prefix
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(BarcodeValidator.maxLength),
                      // Optional: a custom formatter that never lets the user delete the "JAA"
                      _JaaPrefixFormatter(),
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

/*
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

class _JaaPrefixFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    const prefix = BarcodeValidator.prefix;
    String text = newValue.text.toUpperCase();

    // Always keep the prefix
    if (!text.startsWith(prefix)) {
      text = prefix + text.replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      // Keep only digits after the prefix
      final after = text.substring(prefix.length).replaceAll(RegExp(r'[^0-9]'), '');
      text = prefix + after;
    }

    // Clamp length
    if (text.length > BarcodeValidator.maxLength) {
      text = text.substring(0, BarcodeValidator.maxLength);
    }

    // Keep cursor after the prefix at minimum
    int offset = newValue.selection.baseOffset;
    if (offset < prefix.length) offset = prefix.length;
    if (offset > text.length) offset = text.length;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}*/
