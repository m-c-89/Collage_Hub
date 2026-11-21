import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/utils/money.dart';

void main() {
  group('formatRupees', () {
    test('formats numbers using Indian digit grouping', () {
      expect(formatRupees(0), '₹0');
      expect(formatRupees(55), '₹55');
      expect(formatRupees(999), '₹999');
      expect(formatRupees(1250), '₹1,250');
      expect(formatRupees(12500), '₹12,500');
      expect(formatRupees(125000), '₹1,25,000');
      expect(formatRupees(1250000), '₹12,50,000');
      expect(formatRupees(12500000), '₹1,25,00,000');
    });

    test('handles negative values correctly', () {
      expect(formatRupees(-55), '-₹55');
      expect(formatRupees(-1250), '-₹1,250');
      expect(formatRupees(-125000), '-₹1,25,000');
    });
  });
}
