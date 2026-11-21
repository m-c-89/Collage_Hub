import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/features/food/models/food_item.dart';

void main() {
  group('MenuItem Model Tests', () {
    test('prepLabel formats correctly', () {
      const item1 = MenuItem(
        name: 'Item 1',
        price: 50,
        prepMinMinutes: 20,
        prepMaxMinutes: 25,
      );
      expect(item1.prepLabel, '20-25 mins');

      const item2 = MenuItem(
        name: 'Item 2',
        price: 50,
        prepMinMinutes: 10,
        prepMaxMinutes: 10,
      );
      expect(item2.prepLabel, '10 mins');
    });

    test('hasDiscount is true only when originalPrice > price', () {
      const discounted = MenuItem(
        name: 'Discounted',
        price: 80,
        originalPrice: 100,
      );
      expect(discounted.hasDiscount, isTrue);

      const samePrice = MenuItem(
        name: 'Same Price',
        price: 80,
        originalPrice: 80,
      );
      expect(samePrice.hasDiscount, isFalse);

      const higherPrice = MenuItem(
        name: 'Higher Price',
        price: 80,
        originalPrice: 70,
      );
      expect(higherPrice.hasDiscount, isFalse);

      const noOriginal = MenuItem(
        name: 'No Original',
        price: 80,
      );
      expect(noOriginal.hasDiscount, isFalse);
    });

    test('discountPercent calculates percentage correctly (e.g. 100 -> 80 = 20)', () {
      const item1 = MenuItem(
        name: 'Item 1',
        price: 80,
        originalPrice: 100,
      );
      expect(item1.discountPercent, 20);

      const item2 = MenuItem(
        name: 'Item 2',
        price: 150,
        originalPrice: 200,
      );
      expect(item2.discountPercent, 25);

      const noDiscount = MenuItem(
        name: 'No Discount',
        price: 80,
        originalPrice: 80,
      );
      expect(noDiscount.discountPercent, 0);

      const withoutOriginal = MenuItem(
        name: 'Without Original',
        price: 80,
      );
      expect(withoutOriginal.discountPercent, 0);
    });

    test('ids are stable: preserved when provided, derived as slug when missing', () {
      const explicitItem = MenuItem(
        id: 'custom-samosa-id',
        name: 'Samosa (2 pcs)',
        price: 20,
      );
      expect(explicitItem.id, 'custom-samosa-id');

      const derivedItem1 = MenuItem(
        name: 'Samosa (2 pcs)',
        price: 20,
      );
      expect(derivedItem1.id, 'samosa-2-pcs');
      // Stability check across accesses
      expect(derivedItem1.id, 'samosa-2-pcs');

      const derivedItem2 = MenuItem(
        name: 'Hakka Noodles (Veg)',
        price: 70,
      );
      expect(derivedItem2.id, 'hakka-noodles-veg');
    });
  });
}
