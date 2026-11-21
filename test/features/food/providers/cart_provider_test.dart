import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';

void main() {
  group('CartProvider Unit Tests', () {
    late CartProvider cart;

    const testItem1 = MenuItem(
      id: 'test-samosa',
      name: 'Samosa (2 pcs)',
      category: FoodCategory.snacks,
      description: 'Test description',
      prepMinMinutes: 5,
      prepMaxMinutes: 8,
      price: 20,
      vendorId: 'canteen',
      vendorName: 'College Canteen',
      imageUrl: 'https://example.com/samosa.jpg',
    );

    const testItem2 = MenuItem(
      id: 'test-chai',
      name: 'Masala Chai',
      category: FoodCategory.beverages,
      description: 'Test chai',
      prepMinMinutes: 4,
      prepMaxMinutes: 6,
      price: 15,
      vendorId: 'canteen',
      vendorName: 'College Canteen',
      imageUrl: 'https://example.com/chai.jpg',
    );

    const differentVendorItem = MenuItem(
      id: 'juice-corner-mango',
      name: 'Mango Shake',
      category: FoodCategory.beverages,
      description: 'Fresh mango shake',
      prepMinMinutes: 5,
      prepMaxMinutes: 10,
      price: 50,
      vendorId: 'juice-corner',
      vendorName: 'Campus Juice Corner',
      imageUrl: 'https://example.com/mango.jpg',
    );

    setUp(() {
      cart = CartProvider();
    });

    test('initial cart state is empty', () {
      expect(cart.items.isEmpty, isTrue);
      expect(cart.totalQuantity, 0);
      expect(cart.subtotal, 0);
      expect(cart.quantityOf('test-samosa'), 0);
    });

    test('add/remove/quantity operations function correctly', () {
      var notified = false;
      cart.addListener(() => notified = true);

      // Add item 1
      final added = cart.add(testItem1);
      expect(added, isTrue);
      expect(notified, isTrue);
      expect(cart.items.length, 1);
      expect(cart.quantityOf(testItem1.id), 1);
      expect(cart.totalQuantity, 1);
      expect(cart.subtotal, 20);

      // Increment
      cart.increment(testItem1.id);
      expect(cart.quantityOf(testItem1.id), 2);
      expect(cart.totalQuantity, 2);
      expect(cart.subtotal, 40);

      // Add item 2
      cart.add(testItem2);
      expect(cart.items.length, 2);
      expect(cart.totalQuantity, 3);
      expect(cart.subtotal, 55);

      // Decrement
      cart.decrement(testItem1.id);
      expect(cart.quantityOf(testItem1.id), 1);
      expect(cart.totalQuantity, 2);
      expect(cart.subtotal, 35);

      // Remove
      cart.remove(testItem1.id);
      expect(cart.quantityOf(testItem1.id), 0);
      expect(cart.items.length, 1);
      expect(cart.totalQuantity, 1);
      expect(cart.subtotal, 15);

      // Clear
      cart.clear();
      expect(cart.items.isEmpty, isTrue);
      expect(cart.totalQuantity, 0);
      expect(cart.subtotal, 0);
    });

    test('syncWithCatalog updates changed price, removes unavailable and deleted items', () {
      cart.add(testItem1); // 20
      cart.add(testItem2); // 15
      cart.increment(testItem2.id); // 2 chai = 30; total subtotal = 50

      expect(cart.subtotal, 50);

      // Catalog with updated price for Samosa (20 -> 25), Chai unavailable, and an extra item
      final updatedCatalog = [
        testItem1.copyWith(price: 25), // price updated
        testItem2.copyWith(isAvailable: false), // unavailable
      ];

      final messages = cart.syncWithCatalog(updatedCatalog);

      expect(messages, contains('Price of Samosa (2 pcs) updated to ₹25'));
      expect(messages, contains('Masala Chai is no longer available'));

      // Subtotal stays correct afterwards: Samosa (qty 1 @ 25)
      expect(cart.items.length, 1);
      expect(cart.quantityOf(testItem1.id), 1);
      expect(cart.quantityOf(testItem2.id), 0);
      expect(cart.subtotal, 25);
    });

    test('syncWithCatalog removes item deleted from catalog', () {
      cart.add(testItem1);
      cart.add(testItem2);

      // Catalog where testItem2 is completely removed (deleted)
      final catalogWithoutChai = [testItem1];

      final messages = cart.syncWithCatalog(catalogWithoutChai);

      expect(messages, contains('Masala Chai is no longer available'));
      expect(cart.items.length, 1);
      expect(cart.quantityOf(testItem2.id), 0);
      expect(cart.subtotal, 20);
    });

    test('single-vendor rule blocks different vendorId until replaced', () {
      // Cart has items from 'canteen'
      cart.add(testItem1);
      expect(cart.currentVendorId, 'canteen');
      expect(cart.currentVendorName, 'College Canteen');

      // Attempting to add item from 'juice-corner' without replace is blocked
      expect(cart.hasDifferentVendor(differentVendorItem), isTrue);
      final addedBlocked = cart.add(differentVendorItem);
      expect(addedBlocked, isFalse);

      // Cart still contains only canteen items
      expect(cart.items.length, 1);
      expect(cart.items.first.item.id, testItem1.id);
      expect(cart.currentVendorId, 'canteen');

      // Now add with replace = true (or replaceWith)
      cart.replaceWith(differentVendorItem);

      // Cart is replaced with juice-corner items
      expect(cart.items.length, 1);
      expect(cart.items.first.item.id, differentVendorItem.id);
      expect(cart.currentVendorId, 'juice-corner');
      expect(cart.currentVendorName, 'Campus Juice Corner');
      expect(cart.subtotal, 50);
    });
  });
}
