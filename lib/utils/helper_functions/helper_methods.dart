import 'package:flutter/foundation.dart';

class HelperMethods {
  /// mask mobile number
  static String maskMobile(String mobile) {
    if (mobile.length != 10) return mobile;
    return '******${mobile.substring(mobile.length - 4)}';
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
