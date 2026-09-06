import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Self-contained, theme-agnostic OTP box input that can be reused on any
/// screen irrespective of the surrounding UI style.
///
/// Unlike the old login-screen version this widget owns its own
/// [TextEditingController] and [FocusNode] — they are created in
/// [State.initState] and disposed in [State.dispose]. No external controller
/// exists whose lifetime can get torn down out of order, so the
/// "A TextEditingController used after being disposed" crash can no longer
/// happen.
///
/// ## How it works
/// A single hidden [TextField] (opacity 0 wrapped in [IgnorePointer]) owns the
/// focus, keyboard, paste and SMS autofill. The visible boxes are painted on
/// top and each box handles taps: tapping before/after a digit moves the caret
/// there, exactly like a normal text field. Pasting or autofill dropping the
/// whole code in at once is handled in a single shot.
///
/// ## Flows that must not auto-detect
/// Set [enableAutofill] to `false` (default is `true`) — e.g. the patient
/// sample-collection OTP:
///
/// ```dart
/// OtpBoxesInput(
///   key: controller.otpInputKey,
///   enableAutofill: false, // no SMS auto-detect
///   onChanged: (code) => controller.otpError.value = '',
/// )
/// ```
class OtpBoxesInput extends StatefulWidget {
  const OtpBoxesInput({
    super.key,
    this.length = 4,
    this.initialCode = '',
    this.enabled = true,
    this.autofocus = true,
    this.enableAutofill = true,
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
    this.onChanged,
    this.onCompleted,
    this.boxWidth = 52,
    this.boxHeight = 58,
    this.spacing = 10,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.boxColor,
    this.filledBoxColor,
    this.disabledBoxColor,
    this.borderColor,
    this.filledBorderColor,
    this.focusBorderColor,
    this.borderWidth = 1.5,
    this.focusBorderWidth = 2,
    this.textStyle,
    this.cursorColor,
    this.showCursor = true,
  });

  /// Number of boxes / expected digits (e.g. 4).
  final int length;

  /// Code to show when the widget first mounts. Change it later via
  /// [OtpBoxesInputState.setCode].
  final String initialCode;

  /// When `false` the boxes render in a disabled state and accept no input.
  final bool enabled;

  /// Requests focus (opens the keyboard) as soon as the widget is shown.
  final bool autofocus;

  /// When `true` the hidden field advertises [AutofillHints.oneTimeCode] so
  /// the OS / sms_autofill plugin can drop the code in automatically. Turn it
  /// off for OTP flows that must not auto-detect.
  final bool enableAutofill;

  final TextInputType keyboardType;

  /// Overrides the default digits-only formatter if a different input format
  /// is needed.
  final List<TextInputFormatter>? inputFormatters;

  /// Called with the full current code on every change.
  final ValueChanged<String>? onChanged;

  /// Called when the code reaches [length] digits — whether typed, pasted or
  /// injected via [OtpBoxesInputState.setCode].
  final ValueChanged<String>? onCompleted;

  // ---- Sizing --------------------------------------------------------------
  final double boxWidth;
  final double boxHeight;

  /// Gap between two consecutive boxes.
  final double spacing;
  final BorderRadiusGeometry borderRadius;

  // ---- Styling -------------------------------------------------------------
  // Every color below falls back to the ambient Theme when left `null`, so the
  // same widget renders correctly on white screens, branded screens, dark
  // themes, etc.
  final Color? boxColor;
  final Color? filledBoxColor;
  final Color? disabledBoxColor;
  final Color? borderColor;
  final Color? filledBorderColor;
  final Color? focusBorderColor;
  final double borderWidth;
  final double focusBorderWidth;

  /// Text style for the entered digits.
  final TextStyle? textStyle;

  /// Color of the blinking caret.
  final Color? cursorColor;

  /// When `false` the blinking caret is hidden on the focused empty box.
  final bool showCursor;

  @override
  State<OtpBoxesInput> createState() => OtpBoxesInputState();
}

/// Public state of [OtpBoxesInput] so callers can read and drive the code
/// programmatically, e.g.:
///
/// ```dart
/// final key = GlobalKey<OtpBoxesInputState>();
/// // ...
/// key.currentState?.setCode(smsCode);
/// key.currentState?.clear();
/// ```
class OtpBoxesInputState extends State<OtpBoxesInput>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _caretBlink;

  // Re-entrancy guard: setting controller.selection below synchronously
  // re-fires the listener (TextEditingController notifies on ANY value
  // change, text or selection). Without this we'd either loop or
  // double-process the same logical change.
  bool _guardingSelection = false;

  // Tracked so we can tell a single keystroke (delta ±1) apart from a
  // paste/SMS-autofill (delta > 1 in one shot) inside the listener.
  late String _previousText;

  /// The currently entered code ('' when empty).
  String get code => _controller.text;

  /// True once the code has exactly [OtpBoxesInput.length] digits.
  bool get isComplete => _controller.text.length == widget.length;

  /// Whether the hidden input currently holds focus.
  bool get hasFocus => _focusNode.hasFocus;

  /// Programmatically fills the boxes (e.g. from SMS autofill). Fires
  /// onChanged/onCompleted exactly like manual typing. Safe no-op when the
  /// widget is not mounted.
  void setCode(String value) {
    if (!mounted) return;
    final safe = value.length > widget.length
        ? value.substring(0, widget.length)
        : value;
    _controller.text = safe;
    _setSelectionSafely(TextSelection.collapsed(offset: safe.length));
  }

  /// Clears all digits and refocuses (when [OtpBoxesInput.autofocus] is true).
  /// Safe no-op when not mounted.
  void clear() {
    if (!mounted) return;
    _controller.clear();
    _setSelectionSafely(const TextSelection.collapsed(offset: 0));
    if (widget.autofocus) _focusNode.requestFocus();
  }

  void focus() {
    if (mounted) _focusNode.requestFocus();
  }

  void unfocus() {
    if (mounted) _focusNode.unfocus();
  }

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    final initial = widget.initialCode.length > widget.length
        ? widget.initialCode.substring(0, widget.length)
        : widget.initialCode;
    _controller = TextEditingController(text: initial);
    _previousText = _controller.text;
    _focusNode = FocusNode(debugLabel: 'otpHiddenField');
    _caretBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _controller.addListener(_handleControllerChange);

    if (widget.autofocus && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focus();
      });
    }
  }

  @override
  void didUpdateWidget(OtpBoxesInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.length != oldWidget.length &&
        _controller.text.length > widget.length) {
      _controller.text = _controller.text.substring(0, widget.length);
      _setSelectionSafely(TextSelection.collapsed(offset: widget.length));
    }
    if (widget.enabled && !oldWidget.enabled && widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focus();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    _focusNode.dispose();
    _caretBlink.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Input handling
  // -------------------------------------------------------------------------
  void _handleControllerChange() {
    // Ignore the re-entrant call caused by us setting selection below.
    if (_guardingSelection) return;

    final newText = _controller.text;
    final textChanged = newText != _previousText;

    if (textChanged) {
      final lengthDelta = newText.length - _previousText.length;
      _previousText = newText;

      // Only override the caret for a multi-char jump (paste / SMS autofill
      // dropping the whole code in at once) or a genuinely invalid selection.
      // A single typed digit or single backspace already carries a correct
      // caret position from Flutter/our own tap handler — don't stomp on it,
      // that was the original bug.
      if (lengthDelta.abs() > 1 || !_controller.selection.isValid) {
        _setSelectionSafely(TextSelection.collapsed(offset: newText.length));
      }

      widget.onChanged?.call(newText);
      if (newText.length == widget.length) {
        widget.onCompleted?.call(newText);
      }
    }

    setState(() {}); // repaint boxes (covers text AND caret moves)
  }

  void _setSelectionSafely(TextSelection selection) {
    _guardingSelection = true;
    _controller.selection = selection;
    _guardingSelection = false;
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controller.text.isEmpty) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Handles a tap on box [index]. [localDx] is the tap's x position within
  /// that box (0..boxWidth), used to decide whether the caret lands before or
  /// after a digit that's already there.
  void _handleBoxTap(int index, double localDx) {
    if (!widget.enabled) return;
    final code = _controller.text;
    final int targetOffset;

    if (index >= code.length) {
      targetOffset = code.length;
    } else {
      targetOffset = localDx > widget.boxWidth / 2 ? index + 1 : index;
    }

    _ensureKeyboardVisible();               // <-- was _focusNode.requestFocus();
    _setSelectionSafely(TextSelection.collapsed(offset: targetOffset));
    setState(() {});
  }

  void _handleFallbackTap() {
    if (!widget.enabled) return;
    _ensureKeyboardVisible();               // <-- was _focusNode.requestFocus();
    _setSelectionSafely(
      TextSelection.collapsed(offset: _controller.text.length),
    );
    setState(() {});
  }
  void _ensureKeyboardVisible() {
    if (_focusNode.hasFocus) {
      // The FocusNode never actually lost focus (e.g. keyboard dismissed via
      // Android back button), so requestFocus() below would be a no-op and
      // the keyboard would stay hidden forever. Ask the platform directly.
      SystemChannels.textInput.invokeMethod('TextInput.show');
    } else {
      _focusNode.requestFocus();
    }
  }


  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String code = _controller.text;
    final int cursorOffset = _controller.selection.isValid
        ? _controller.selection.baseOffset.clamp(0, code.length)
        : code.length;
    final TextStyle previewTextStyle = widget.textStyle ??
        (theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ) ??
            const TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
    final double totalWidth = widget.boxWidth * widget.length +
        widget.spacing * (widget.length - 1);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleFallbackTap,
      child: SizedBox(
        width: totalWidth,
        height: widget.boxHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hidden field FIRST (bottom of the stack) and wrapped in
            // IgnorePointer: it exists purely to own focus, the keyboard,
            // paste, and SMS autofill. It must never intercept taps — Opacity
            // alone does NOT stop hit-testing.
            IgnorePointer(
              child: Opacity(
                opacity: 0,
                child: Focus(
                  onKeyEvent: _handleKey,
                  child: SizedBox(
                    width: totalWidth,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus && widget.enabled,
                      enabled: widget.enabled,
                      readOnly: !widget.enabled,
                      keyboardType: widget.keyboardType,
                      textAlign: TextAlign.center,
                      maxLength: widget.length,
                      autofillHints: widget.enableAutofill
                          ? const <String>[AutofillHints.oneTimeCode]
                          : null,
                      inputFormatters: widget.inputFormatters ??
                          <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                      enableInteractiveSelection: false,
                      showCursor: false,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Visible boxes ON TOP — each owns its own tap handler.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) SizedBox(width: widget.spacing),
                  _buildBox(i, code, cursorOffset, previewTextStyle, colorScheme),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(
    int index,
    String code,
    int cursorOffset,
    TextStyle previewTextStyle,
    ColorScheme colorScheme,
  ) {
    final bool filled = index < code.length;
    final bool isCursorHere = index == cursorOffset;
    final bool focused = isCursorHere && _focusNode.hasFocus;

    final Color boxFill;
    final Color borderColor;
    if (!widget.enabled) {
      boxFill = widget.disabledBoxColor ??
          (widget.boxColor ?? colorScheme.surface).withValues(alpha: 0.5);
      borderColor = (widget.borderColor ?? colorScheme.outlineVariant)
          .withValues(alpha: 0.4);
    } else {
      boxFill = filled
          ? widget.filledBoxColor ?? widget.boxColor ?? colorScheme.surface
          : widget.boxColor ?? colorScheme.surface;
      borderColor = focused
          ? widget.focusBorderColor ?? colorScheme.primary
          : filled
              ? widget.filledBorderColor ?? colorScheme.primary
              : widget.borderColor ?? colorScheme.outlineVariant;
    }
    final double borderWidth =
        focused ? widget.focusBorderWidth : widget.borderWidth;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _handleBoxTap(index, details.localPosition.dx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.boxWidth,
        height: widget.boxHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: boxFill,
          borderRadius: widget.borderRadius,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: filled
            ? Text(code[index], style: previewTextStyle)
            : focused && widget.showCursor
                ? FadeTransition(
                    opacity: _caretBlink,
                    child: Container(
                      width: 2,
                      height: (previewTextStyle.fontSize ?? 22) * 1.2,
                      color: widget.cursorColor ?? colorScheme.primary,
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}