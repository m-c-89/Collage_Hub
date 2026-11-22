import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/features/vendor/models/vendor_profile.dart';
import 'package:college_canteen/features/vendor/services/vendor_id.dart';
import 'package:college_canteen/features/vendor/services/vendor_validators.dart';

void main() {
  group('validateBusinessName', () {
    test('requires 2 to 40 characters after trim', () {
      expect(validateBusinessName('A'), isNotNull);
      expect(validateBusinessName(' A '), isNotNull);
      expect(validateBusinessName('AB'), isNull);
      expect(validateBusinessName('College Canteen'), isNull);
      expect(validateBusinessName('a' * 40), isNull);
      expect(validateBusinessName('a' * 41), isNotNull);
      expect(validateBusinessName(null), isNotNull);
      expect(validateBusinessName('   '), isNotNull);
    });
  });

  group('validatePhone (table-driven)', () {
    const cases = [
      (phone: '9876543210', isValid: true, desc: '9876543210 ok'),
      (phone: '1234567890', isValid: false, desc: '1234567890 bad (starts with 1)'),
      (phone: '987654321', isValid: false, desc: '9 digits bad'),
      (phone: '98765432100', isValid: false, desc: '11 digits bad'),
      (phone: '8765432109', isValid: true, desc: 'starts with 8 ok'),
      (phone: '7654321098', isValid: true, desc: 'starts with 7 ok'),
      (phone: '6543210987', isValid: true, desc: 'starts with 6 ok'),
      (phone: '5432109876', isValid: false, desc: 'starts with 5 bad'),
      (phone: null, isValid: false, desc: 'null bad'),
      (phone: '', isValid: false, desc: 'empty bad'),
    ];

    for (final c in cases) {
      test(c.desc, () {
        final result = validatePhone(c.phone);
        if (c.isValid) {
          expect(result, isNull);
        } else {
          expect(result, isNotNull);
        }
      });
    }
  });

  group('validateFssai (table-driven)', () {
    const cases = [
      (
        fssai: '12345678901234',
        type: BusinessType.canteen,
        isValid: true,
        desc: '14 digits ok for canteen',
      ),
      (
        fssai: '1234567890123',
        type: BusinessType.canteen,
        isValid: false,
        desc: '13 digits bad for canteen',
      ),
      (
        fssai: '',
        type: BusinessType.canteen,
        isValid: false,
        desc: 'empty bad for canteen (fssaiRequired = true)',
      ),
      (
        fssai: null,
        type: BusinessType.canteen,
        isValid: false,
        desc: 'null bad for canteen (fssaiRequired = true)',
      ),
      (
        fssai: '',
        type: BusinessType.stationeryShop,
        isValid: true,
        desc: 'empty OK for stationeryShop (fssaiRequired = false)',
      ),
      (
        fssai: null,
        type: BusinessType.stationeryShop,
        isValid: true,
        desc: 'null OK for stationeryShop',
      ),
      (
        fssai: '1234567890123',
        type: BusinessType.stationeryShop,
        isValid: false,
        desc: '13 digits bad for stationeryShop when provided',
      ),
      (
        fssai: '12345678901234',
        type: BusinessType.stationeryShop,
        isValid: true,
        desc: '14 digits OK for stationeryShop when provided',
      ),
    ];

    for (final c in cases) {
      test(c.desc, () {
        final result = validateFssai(c.fssai, c.type);
        if (c.isValid) {
          expect(result, isNull);
        } else {
          expect(result, isNotNull);
        }
      });
    }
  });

  group('validatePrice (table-driven: 0 / 1 / 10000 / 10001)', () {
    const cases = [
      (price: 0, isValid: false, desc: '0 is bad'),
      (price: 1, isValid: true, desc: '1 is ok'),
      (price: 50, isValid: true, desc: '50 is ok'),
      (price: 10000, isValid: true, desc: '10000 is ok'),
      (price: 10001, isValid: false, desc: '10001 is bad'),
      (price: null, isValid: false, desc: 'null is bad'),
    ];

    for (final c in cases) {
      test(c.desc, () {
        final result = validatePrice(c.price);
        if (c.isValid) {
          expect(result, isNull);
        } else {
          expect(result, isNotNull);
        }
      });
    }
  });

  group('validateDiscount (table-driven: 80 of 100 ok; 100 of 100 bad; 0 bad)', () {
    const cases = [
      (discounted: 80, original: 100, isValid: true, desc: '80 of 100 ok'),
      (discounted: 100, original: 100, isValid: false, desc: '100 of 100 bad (not < original)'),
      (discounted: 0, original: 100, isValid: false, desc: '0 bad (must be >= 1)'),
      (discounted: 120, original: 100, isValid: false, desc: '120 of 100 bad (> original)'),
      (discounted: -10, original: 100, isValid: false, desc: '-10 bad'),
    ];

    for (final c in cases) {
      test(c.desc, () {
        final result = validateDiscount(
          originalPrice: c.original,
          discountedPrice: c.discounted,
        );
        if (c.isValid) {
          expect(result, isNull);
        } else {
          expect(result, isNotNull);
        }
      });
    }
  });

  group('validateCustomMessage (length 60 / 61)', () {
    test('null and empty are valid', () {
      expect(validateCustomMessage(null), isNull);
      expect(validateCustomMessage(''), isNull);
    });

    test('60 chars is valid, 61 is bad', () {
      expect(validateCustomMessage('a' * 60), isNull);
      expect(validateCustomMessage('a' * 61), isNotNull);
    });
  });

  group('validatePrep bounds (1 <= min <= max <= 180)', () {
    test('accepts valid bounds', () {
      expect(validatePrep(min: 1, max: 1), isNull);
      expect(validatePrep(min: 5, max: 15), isNull);
      expect(validatePrep(min: 1, max: 180), isNull);
    });

    test('rejects out of bound values', () {
      expect(validatePrep(min: 0, max: 10), isNotNull);
      expect(validatePrep(min: 15, max: 10), isNotNull);
      expect(validatePrep(min: 10, max: 181), isNotNull);
    });
  });

  group('VendorId helpers: slugifyVendorName and generateVendorId', () {
    test("slugifyVendorName('Sai Chai Point!') = 'sai-chai-point'", () {
      expect(slugifyVendorName('Sai Chai Point!'), 'sai-chai-point');
      expect(slugifyVendorName('  College   Canteen  '), 'college-canteen');
      expect(slugifyVendorName('---'), 'vendor');
      expect(slugifyVendorName(''), 'vendor');
    });

    test('generateVendorId regenerates on a collision', () {
      var callCount = 0;
      final generated = generateVendorId(
        'Sai Chai Point!',
        (id) {
          callCount++;
          // First check returns true (collision), second returns false (available)
          return callCount == 1;
        },
        Random(42),
      );

      expect(callCount, 2);
      expect(generated, startsWith('sai-chai-point-'));
      expect(RegExp(r'^sai-chai-point-\d{4}$').hasMatch(generated), isTrue);
    });
  });
}
