import 'package:flutter_test/flutter_test.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';

void main() {
  group('HelperMethods.maskMobileMiddle', () {
    test('masks a 10-digit number to first-two/last-two digits', () {
      expect(HelperMethods.maskMobileMiddle('7512345689'), '75****89');
    });

    test('masks an 8-digit number the same way', () {
      expect(HelperMethods.maskMobileMiddle('75123489'), '75****89');
    });

    test('handles prefixed/country formatting by stripping non-digits', () {
      expect(HelperMethods.maskMobileMiddle('+91 75123 45689'), '75****89');
    });

    test('returns short numbers unchanged', () {
      expect(HelperMethods.maskMobileMiddle('1234'), '1234');
      expect(HelperMethods.maskMobileMiddle('12'), '12');
    });

    test('returns empty string when there is no number', () {
      expect(HelperMethods.maskMobileMiddle(''), '');
    });
  });
}