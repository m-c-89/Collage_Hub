import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/features/food/data/menu_data.dart';
import 'package:college_canteen/features/food/models/food_item.dart';

void main() {
  group('Menu Data Specifications', () {
    test('contains exactly 16 vegetarian items', () {
      expect(canteenMenuItems.length, 16);
    });

    test('has exactly 5 Snacks, 6 Meals, 3 Beverages, and 2 Desserts', () {
      final snacks = canteenMenuItems
          .where((i) => i.category == FoodCategory.snacks)
          .toList();
      final meals = canteenMenuItems
          .where((i) => i.category == FoodCategory.meals)
          .toList();
      final beverages = canteenMenuItems
          .where((i) => i.category == FoodCategory.beverages)
          .toList();
      final desserts = canteenMenuItems
          .where((i) => i.category == FoodCategory.desserts)
          .toList();

      expect(snacks.length, 5);
      expect(meals.length, 6);
      expect(beverages.length, 3);
      expect(desserts.length, 2);
    });

    test('exact items and prices match requirements', () {
      final priceMap = {
        for (var item in canteenMenuItems) item.name: item.price,
      };

      // Snacks
      expect(priceMap['Samosa (2 pcs)'], 20.0);
      expect(priceMap['Veg Puff'], 25.0);
      expect(priceMap['Vada Pav'], 25.0);
      expect(priceMap['French Fries'], 50.0);
      expect(priceMap['Veg Sandwich'], 40.0);

      // Meals
      expect(priceMap['Veg Thali'], 90.0);
      expect(priceMap['Paneer Roll'], 60.0);
      expect(priceMap['Hakka Noodles (Veg)'], 70.0);
      expect(priceMap['Veg Biryani'], 90.0);
      expect(priceMap['Chole Bhature'], 65.0);
      expect(priceMap['Masala Dosa'], 60.0);

      // Beverages
      expect(priceMap['Masala Chai'], 15.0);
      expect(priceMap['Cold Coffee'], 45.0);
      expect(priceMap['Fresh Lime Soda'], 30.0);

      // Desserts
      expect(priceMap['Chocolate Brownie'], 50.0);
      expect(priceMap['Gulab Jamun (2 pcs)'], 30.0);
    });

    test('all items have descriptions and valid imageUrls', () {
      for (final item in canteenMenuItems) {
        expect(item.description.trim().isNotEmpty, isTrue);
        expect(item.imageUrl.startsWith('https://'), isTrue);
        expect(item.prepTimeMinutes > 0, isTrue);
      }
    });
  });
}
