import 'package:flutter/foundation.dart';

class HelperMethods {
  /// mask mobile number
  static String maskMobile(String mobile) {
    if (mobile.length != 10) return mobile;
    return '******${mobile.substring(mobile.length - 4)}';
  }

  /// Masks a mobile number keeping only the first two and last two digits
  /// visible, replacing everything in between with `****` — e.g.
  /// `7512345689` → `75****89`. Non-digit characters are stripped and a
  /// leading Indian country code (`91` / `+91` / `+91 `) is dropped first,
  /// so `+91 75123 45689` also renders as `75****89`.
  static String maskMobileMiddle(String mobile) {
    var digits = mobile.replaceAll(RegExp(r'\D'), '');
    // `+91 7512345689` has 12 digits; drop the leading `91` country code so
    // the passcode-style mask shows the local number, not its country prefix.
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    if (digits.length <= 4) return digits;
    return '${digits.substring(0, 2)}****${digits.substring(digits.length - 2)}';
  }

  static void printLongString(String text) {
    final pattern = RegExp('.{1,1000}');
    if (kDebugMode) {
      pattern.allMatches(text).forEach((match) => debugPrint(match.group(0)));
    }
  }

  static String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  // print statement with kdebugMode
  static void printDebug(String text) {
    if (kDebugMode) {
      printLongString(text);
    }
  }
}

String parseError(dynamic e) {
  final message = e.toString();

  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length);
  }
  if (message.isEmpty) return 'Something went wrong';
  return message;
}

void kPrint(String text) {
  if(kDebugMode){
    print(text);
  }
  // HelperMethods.printLongString(text);
}
