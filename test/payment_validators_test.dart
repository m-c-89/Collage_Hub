import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/features/food/services/payment_validators.dart';

void main() {
  group('Payment Validators Tests', () {
    group('UPI ID validation', () {
      final cases = [
        ('ravi@okaxis', true, 'valid UPI ID'),
        ('user.name@bank', true, 'valid UPI ID with period'),
        ('my-upi_id@paytm', true, 'valid UPI ID with dash and underscore'),
        ('a@b', false, 'too short on prefix and bank code'),
        ('no-at-sign', false, 'missing @ symbol'),
        ('@bank', false, 'missing prefix'),
        ('user@', false, 'missing suffix'),
        ('', false, 'empty string'),
      ];

      for (final (input, expected, description) in cases) {
        test('isValidUpiId("$input") -> $expected ($description)', () {
          expect(isValidUpiId(input), expected);
        });
      }
    });

    group('Card Number validation & formatting', () {
      final validationCases = [
        ('4111 1111 1111 1111', true, 'valid 16 digits with spaces'),
        ('4111111111111111', true, 'valid 16 contiguous digits'),
        ('4111 1111 1111 111', false, '15 digits is invalid'),
        ('4111 1111 1111 1111 1', false, '17 digits is invalid'),
        ('4111 1111 1111 111a', false, 'letters are invalid'),
        ('', false, 'empty string is invalid'),
      ];

      for (final (input, expected, description) in validationCases) {
        test('isValidCardNumber("$input") -> $expected ($description)', () {
          expect(isValidCardNumber(input), expected);
        });
      }

      test('formatCardNumber groups digits into blocks of 4', () {
        expect(formatCardNumber('4111111111111111'), '4111 1111 1111 1111');
        expect(formatCardNumber('4111 1111 1111 1111'), '4111 1111 1111 1111');
        expect(formatCardNumber('12345'), '1234 5');
        expect(formatCardNumber(''), '');
      });
    });

    group('Expiry MM/YY validation', () {
      final testNow = DateTime(2026, 11, 21);

      final cases = [
        ('11/26', true, 'current month and year is valid'),
        ('12/26', true, 'future month in current year is valid'),
        ('01/27', true, 'future year is valid'),
        ('10/26', false, 'past month in current year is invalid'),
        ('12/25', false, 'past year is invalid'),
        ('13/27', false, 'month > 12 is invalid'),
        ('00/27', false, 'month 00 is invalid'),
        ('invalid', false, 'non-date string is invalid'),
        ('', false, 'empty string is invalid'),
      ];

      for (final (input, expected, description) in cases) {
        test('isValidExpiry("$input", 2026-11-21) -> $expected ($description)', () {
          expect(isValidExpiry(input, testNow), expected);
        });
      }
    });

    group('CVV validation', () {
      final cases = [
        ('123', true, 'valid 3 digits'),
        ('000', true, 'valid 3 zeros'),
        ('12', false, '2 digits is invalid'),
        ('1234', false, '4 digits is invalid'),
        ('12a', false, 'letters are invalid'),
        ('', false, 'empty string is invalid'),
      ];

      for (final (input, expected, description) in cases) {
        test('isValidCvv("$input") -> $expected ($description)', () {
          expect(isValidCvv(input), expected);
        });
      }
    });

    group('Cardholder Name length bounds', () {
      final cases = [
        ('A', false, '1 char is below minimum 2'),
        ('AB', true, '2 chars is valid minimum bound'),
        ('Rohit Sharma', true, 'normal name is valid'),
        ('A' * 40, true, '40 chars is valid maximum bound'),
        ('A' * 41, false, '41 chars exceeds maximum bound 40'),
        ('', false, 'empty string is invalid'),
      ];

      for (final (input, expected, description) in cases) {
        test('isValidName length ${input.length} -> $expected ($description)', () {
          expect(isValidName(input), expected);
        });
      }
    });
  });
}
