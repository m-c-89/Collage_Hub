import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';

void main() {
  group('CartProvider Unit Tests', () {
    late CartProvider cart;
    const testItem1 = FoodItem(
      id: 'test-samosa',
      name: 'Samosa (2 pcs)',
      category: FoodCategory.snacks,
      description: 'Test description',
      prepTimeMinutes: 5,
      price: 20.0,
      imageUrl: 'https://example.com/samosa.jpg',
    );

    const testItem2 = FoodItem(
      id: 'test-chai',
      name: 'Masala Chai',
      category: FoodCategory.beverages,
      description: 'Test chai',
      prepTimeMinutes: 4,
      price: 15.0,
      imageUrl: 'https://example.com/chai.jpg',
    );

    setUp(() {
      cart = CartProvider();
    });

    test('initial cart state is empty', () {
      expect(cart.items.isEmpty, isTrue);
      expect(cart.totalQuantity, 0);
      expect(cart.subtotal, 0.0);
      expect(cart.quantityOf('test-samosa'), 0);
    });

    test('add() inserts item with quantity 1 and notifies listeners', () {
      var notified = false;
      cart.addListener(() => notified = true);

      cart.add(testItem1);

      expect(notified, isTrue);
      expect(cart.items.length, 1);
      expect(cart.quantityOf(testItem1.id), 1);
      expect(cart.totalQuantity, 1);
      expect(cart.subtotal, 20.0);
    });

    test('add() on existing item increments quantity', () {
      cart.add(testItem1);
      cart.add(testItem1);

      expect(cart.items.length, 1);
      expect(cart.quantityOf(testItem1.id), 2);
      expect(cart.totalQuantity, 2);
      expect(cart.subtotal, 40.0);
    });

    test('increment() increases quantity', () {
      cart.add(testItem1);
      cart.increment(testItem1.id);

      expect(cart.quantityOf(testItem1.id), 2);
      expect(cart.subtotal, 40.0);
    });

    test('decrement() decreases quantity and removes at 0', () {
      cart.add(testItem1);
      cart.increment(testItem1.id); // qty 2
      expect(cart.quantityOf(testItem1.id), 2);

      cart.decrement(testItem1.id); // qty 1
      expect(cart.quantityOf(testItem1.id), 1);
      expect(cart.items.length, 1);

      cart.decrement(testItem1.id); // qty 0 -> removed!
      expect(cart.quantityOf(testItem1.id), 0);
      expect(cart.items.isEmpty, isTrue);
      expect(cart.totalQuantity, 0);
      expect(cart.subtotal, 0.0);
    });

    test('remove() completely deletes item regardless of quantity', () {
      cart.add(testItem1);
      cart.increment(testItem1.id);
      cart.add(testItem2);

      expect(cart.items.length, 2);
      expect(cart.totalQuantity, 3); // 2 samosa + 1 chai

      cart.remove(testItem1.id);

      expect(cart.items.length, 1);
      expect(cart.quantityOf(testItem1.id), 0);
      expect(cart.quantityOf(testItem2.id), 1);
      expect(cart.totalQuantity, 1);
      expect(cart.subtotal, 15.0);
    });

    test('clear() empties the cart', () {
      cart.add(testItem1);
      cart.add(testItem2);
      expect(cart.totalQuantity, 2);

      cart.clear();

      expect(cart.items.isEmpty, isTrue);
      expect(cart.totalQuantity, 0);
      expect(cart.subtotal, 0.0);
    });

    test('subtotal calculates Σ(price × quantity) accurately', () {
      cart.add(testItem1); // 20 * 1 = 20
      cart.increment(testItem1.id); // 20 * 2 = 40
      cart.add(testItem2); // 15 * 1 = 15
      cart.increment(testItem2.id); // 15 * 2 = 30
      cart.increment(testItem2.id); // 15 * 3 = 45

      // Subtotal should be 40 + 45 = 85
      expect(cart.totalQuantity, 5);
      expect(cart.subtotal, 85.0);
    });
  });
}
