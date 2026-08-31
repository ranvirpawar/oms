import 'package:flutter/services.dart';

class InputFormatters {
  // Formatter to allow only digits and alphabets
  static List<TextInputFormatter> get alphaNumeric {
    return [FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9]*$'))];
  }

  // Formatter to allow only digits
  static List<TextInputFormatter> get digits {
    return [FilteringTextInputFormatter.digitsOnly];
  }
  // Formatter to allow only alphabets
  static List<TextInputFormatter> get alphabets {
    return [FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z ]*$'))];
  }
}
class SingleWordFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;

    // Allow only alphabets + optional single space at the end
    final regExp = RegExp(r'^[a-zA-Z]+ ?$');

    if (regExp.hasMatch(text) || text.isEmpty) {
      // ✅ Valid case (letters only or one trailing space)
      return newValue;
    }

    // ❌ Invalid case (e.g., letters after space)
    // Keep the old value (do not erase everything)
    return oldValue;
  }
}
