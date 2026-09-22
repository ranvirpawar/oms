import 'package:flutter/material.dart';
import 'package:flutter/services.dart';




class KTextFormField extends StatefulWidget {
  final TextEditingController controller;

  /// IconData, e.g. Icons.person — matches CartStatsCard's icon param.
  final IconData? icon;

  final String label;
  final String hint;
  final int? multi_line;
  final Widget? suffix_icon;
  final VoidCallback? onTap;
  final bool read_only;
  final TextInputType? inputType;
  final int? maxLength;
  final bool isRequired;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;

  /// Optional overrides — default to colorScheme.primary, same as
  /// CartStatsCard's icon chip, so every field matches it out of the box.
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const KTextFormField({
    super.key,
    required this.controller,
    required this.icon,
    required this.label,
    required this.hint,
    this.suffix_icon,
    this.onTap,
    this.multi_line,
    required this.read_only,
    this.inputType,
    this.maxLength,
    this.isRequired = false,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.autovalidateMode,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  State<KTextFormField> createState() => _KTextFormFieldState();
}

class _KTextFormFieldState extends State<KTextFormField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Color chipBg = widget.iconBackgroundColor ?? colorScheme.primary.withOpacity(0.08);
    final Color chipIconColor = widget.iconColor ?? colorScheme.primary;

    return Card(
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isFocused
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outlineVariant.withOpacity(0.4),
          width: _isFocused ? 1.2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIconChip(widget.icon, chipBg, chipIconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        text: widget.label,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        children: [
                          if (widget.isRequired)
                            TextSpan(
                              text: " *",
                              style: TextStyle(
                                color: colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextFormField(
                    focusNode: _focusNode,
                    controller: widget.controller,
                    maxLines: widget.multi_line,
                    readOnly: widget.read_only,
                    keyboardType: widget.inputType,
                    validator: widget.validator,
                    autovalidateMode: widget.autovalidateMode,
                    inputFormatters: widget.inputFormatters,
                    onTap: widget.onTap,
                    maxLength: widget.maxLength,
                    cursorColor: colorScheme.primary,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      isCollapsed: true,
                      counterText: "",
                      contentPadding: const EdgeInsets.only(top: 2, bottom: 6),
                      hintText: _isFocused ? widget.hint : null,
                      hintStyle: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 10
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorStyle: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.suffix_icon != null) ...[
              const SizedBox(width: 6),
              widget.suffix_icon!,
            ],
          ],
        ),
      ),
    );
  }

  /// Same icon-chip formula as CartStatsCard's `_buildStatItem`:
  /// padding 8, `primary.withOpacity(0.08)` fill, radius 12, icon size 20,
  /// icon color `colorScheme.primary`.
  Widget _buildIconChip(IconData? icon, Color bg, Color iconColor) {
    if (icon == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}