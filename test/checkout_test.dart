import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/data/locations_data.dart';
import 'package:college_canteen/data/menu_data.dart';
import 'package:college_canteen/models/campus_location.dart';
import 'package:college_canteen/models/cart_item.dart';
import 'package:college_canteen/providers/cart_provider.dart';
import 'package:college_canteen/providers/checkout_provider.dart';
import 'package:college_canteen/providers/profile_provider.dart';
import 'package:college_canteen/screens/checkout_screen.dart';
import 'package:college_canteen/widgets/bill_summary.dart';

void main() {
  group('Checkout Flow & Formula Unit Tests', () {
    late CheckoutProvider checkoutProvider;
    final samosa = canteenMenuItems.firstWhere((item) => item.name.contains('Samosa'));
    final vegThali = canteenMenuItems.firstWhere((item) => item.name == 'Veg Thali');
    final block2Location = campusLocations.firstWhere((loc) => loc.name == 'Block-2');
    final loc234Location = campusLocations.firstWhere((loc) => loc.name == '234');

    setUp(() {
      checkoutProvider = CheckoutProvider();
    });

    test('1. 2 x Samosa (₹20) + 1 x Veg Thali (₹90) to "Block-2" (Zone 2): subtotal 130, qty 3, extra 60, total ₹190', () {
      final items = [
        CartItem(item: samosa, quantity: 2), // 2 * 20 = 40
        CartItem(item: vegThali, quantity: 1), // 1 * 90 = 90
      ];

      checkoutProvider.selectLocation(block2Location);

      expect(block2Location.zone, DeliveryZone.zone2);
      expect(block2Location.chargePerItem, 20.0);

      final foodSubtotal = checkoutProvider.calculateFoodSubtotal(items);
      final totalQuantity = checkoutProvider.calculateTotalQuantity(items);
      final zoneChargePerItem = checkoutProvider.calculateZoneChargePerItem();
      final zoneExtraTotal = checkoutProvider.calculateZoneExtraTotal(items);
      final totalAmount = checkoutProvider.calculateTotalAmount(items);

      expect(foodSubtotal, 130.0);
      expect(totalQuantity, 3);
      expect(zoneChargePerItem, 20.0);
      expect(zoneExtraTotal, 60.0);
      expect(totalAmount, 190.0);
    });

    test('2. The same cart to "234" (Zone 1): extra 45, total ₹175', () {
      final items = [
        CartItem(item: samosa, quantity: 2), // 40
        CartItem(item: vegThali, quantity: 1), // 90
      ];

      checkoutProvider.selectLocation(loc234Location);

      expect(loc234Location.zone, DeliveryZone.zone1);
      expect(loc234Location.chargePerItem, 15.0);

      final foodSubtotal = checkoutProvider.calculateFoodSubtotal(items);
      final totalQuantity = checkoutProvider.calculateTotalQuantity(items);
      final zoneChargePerItem = checkoutProvider.calculateZoneChargePerItem();
      final zoneExtraTotal = checkoutProvider.calculateZoneExtraTotal(items);
      final totalAmount = checkoutProvider.calculateTotalAmount(items);

      expect(foodSubtotal, 130.0);
      expect(totalQuantity, 3);
      expect(zoneChargePerItem, 15.0);
      expect(zoneExtraTotal, 45.0); // 15 * 3
      expect(totalAmount, 175.0); // 130 + 45
    });

    test('3. Single item and an empty cart (total 0)', () {
      // Single item test
      final singleItemCart = [
        CartItem(item: samosa, quantity: 1),
      ];

      checkoutProvider.selectLocation(loc234Location);
      expect(checkoutProvider.calculateFoodSubtotal(singleItemCart), 20.0);
      expect(checkoutProvider.calculateTotalQuantity(singleItemCart), 1);
      expect(checkoutProvider.calculateZoneExtraTotal(singleItemCart), 15.0);
      expect(checkoutProvider.calculateTotalAmount(singleItemCart), 35.0);

      checkoutProvider.selectLocation(block2Location);
      expect(checkoutProvider.calculateZoneExtraTotal(singleItemCart), 20.0);
      expect(checkoutProvider.calculateTotalAmount(singleItemCart), 40.0);

      // Empty cart test
      final emptyCart = <CartItem>[];

      expect(checkoutProvider.calculateFoodSubtotal(emptyCart), 0.0);
      expect(checkoutProvider.calculateTotalQuantity(emptyCart), 0);
      expect(checkoutProvider.calculateZoneExtraTotal(emptyCart), 0.0);
      expect(checkoutProvider.calculateTotalAmount(emptyCart), 0.0);

      // Empty cart with no location selected
      checkoutProvider.resetLocation();
      expect(checkoutProvider.selectedLocation, isNull);
      expect(checkoutProvider.calculateTotalAmount(emptyCart), 0.0);
    });

    test('Location reset on checkout screen resets selected location to null', () {
      checkoutProvider.selectLocation(block2Location);
      expect(checkoutProvider.selectedLocation, equals(block2Location));
      expect(checkoutProvider.isLocationSelected, isTrue);

      checkoutProvider.resetLocation();
      expect(checkoutProvider.selectedLocation, isNull);
      expect(checkoutProvider.isLocationSelected, isFalse);
    });
  });

  group('Checkout Widget Tests', () {
    Widget buildTestApp({
      required CartProvider cartProvider,
      required ProfileProvider profileProvider,
      required CheckoutProvider checkoutProvider,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cartProvider),
          ChangeNotifierProvider.value(value: profileProvider),
          ChangeNotifierProvider.value(value: checkoutProvider),
        ],
        child: const MaterialApp(
          home: CheckoutScreen(),
        ),
      );
    }

    testWidgets('Confirm Order button is disabled when no location is chosen', (tester) async {
      final cartProvider = CartProvider();
      final profileProvider = ProfileProvider();
      final checkoutProvider = CheckoutProvider();

      final samosa = canteenMenuItems.firstWhere((item) => item.name.contains('Samosa'));
      cartProvider.add(samosa);

      await tester.pumpWidget(
        buildTestApp(
          cartProvider: cartProvider,
          profileProvider: profileProvider,
          checkoutProvider: checkoutProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Should show helper text
      expect(find.text('Please select a delivery location'), findsOneWidget);

      // Confirm Order button exists and is disabled
      final confirmBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Confirm Order'));
      expect(confirmBtn.onPressed, isNull);
    });

    testWidgets('Live bill breakdown updates when location is selected', (tester) async {
      final cartProvider = CartProvider();
      final profileProvider = ProfileProvider();
      final checkoutProvider = CheckoutProvider();

      final samosa = canteenMenuItems.firstWhere((item) => item.name.contains('Samosa'));
      cartProvider.add(samosa); // qty 1 = 20

      await tester.pumpWidget(
        buildTestApp(
          cartProvider: cartProvider,
          profileProvider: profileProvider,
          checkoutProvider: checkoutProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select location'), findsOneWidget);
      expect(find.text('₹20'), findsWidgets); // Subtotal ₹20

      // Select a location programmatically or via dropdown
      final loc234 = campusLocations.firstWhere((loc) => loc.name == '234');
      checkoutProvider.selectLocation(loc234);
      await tester.pumpAndSettle();

      // Location is chosen, helper text disappears
      expect(find.text('Please select a delivery location'), findsNothing);
      expect(find.text('234 (Zone 1)'), findsOneWidget);
      expect(find.text('₹15 × 1 = ₹15'), findsOneWidget);
      expect(find.text('₹35'), findsOneWidget); // 20 + 15 = 35

      // Confirm Order button is now enabled
      final confirmBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Confirm Order'));
      expect(confirmBtn.onPressed, isNotNull);
    });
  });
}
