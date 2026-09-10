/// Pure barcode format rules for sample collection.
///
/// Format: starts with "JAA", then 7–9 digits.
/// Total length: 10–12 characters.
/// Examples: JAA0000001 … JAA999999999
class BarcodeValidator {
  BarcodeValidator._();

  static const String prefix = 'JAA';
  static const int minLength = 10; // JAA + 7 digits
  static const int maxLength = 12; // JAA + 9 digits

  /// Returns `true` only when the value fully matches the required format.
  static bool isValid(String value) {
    final trimmed = value.trim().toUpperCase();
    if (trimmed.length < minLength || trimmed.length > maxLength) {
      return false;
    }
    if (!trimmed.startsWith(prefix)) {
      return false;
    }
    final numericPart = trimmed.substring(prefix.length);
    // Must be only digits and the correct remaining length.
    return RegExp(r'^\d+$').hasMatch(numericPart) &&
        numericPart.length >= 7 &&
        numericPart.length <= 9;
  }

  /// Human-readable message when [isValid] is false.
  static String invalidMessage(String value) {
    final trimmed = value.trim().toUpperCase();
    if (trimmed.isEmpty) return '';
    if (!trimmed.startsWith(prefix)) {
      return 'Barcode must start with $prefix.';
    }
    if (trimmed.length < minLength || trimmed.length > maxLength) {
      return 'Barcode must be $minLength–$maxLength characters (e.g. JAA0000001).';
    }
    final numericPart = trimmed.substring(prefix.length);
    if (!RegExp(r'^\d+$').hasMatch(numericPart)) {
      return 'Only digits are allowed after $prefix.';
    }
    return 'Invalid barcode format.';
  }
}