import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/features/food/data/menu_data.dart';
import 'package:college_canteen/features/food/domain/cart_pricing.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/food/providers/checkout_provider.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';
import 'package:college_canteen/features/food/screens/checkout_screen.dart';
import 'package:college_canteen/core/theme/app_theme.dart';

void main() {
  final r234 = kDeliveryLocations.firstWhere((l) => l.id == 'aitr-b3-f2-r234');
  final r316 = kDeliveryLocations.firstWhere((l) => l.id == 'aitr-b3-f3-r316');

  group('CartPricing via CheckoutProvider', () {
    late CheckoutProvider checkoutProvider;

    setUp(() {
      checkoutProvider = CheckoutProvider();
    });

    test('selectLocation/resetLocation toggles isLocationSelected', () {
      checkoutProvider.selectLocation(r234);
      expect(checkoutProvider.selectedLocation, equals(r234));
      expect(checkoutProvider.isLocationSelected, isTrue);

      checkoutProvider.resetLocation();
      expect(checkoutProvider.selectedLocation, isNull);
      expect(checkoutProvider.isLocationSelected, isFalse);
    });

    test('CartPricing: subtotal 130, location r234 (₹5) → fee 5, total 135', () {
      final result = CartPricing.compute(
        subtotal: 130,
        itemCount: 3,
        location: r234,
      );
      expect(result.subtotal, 130);
      expect(result.deliveryFee, 5);
      expect(result.grandTotal, 135);
      expect(result.canCheckout, isTrue);
      expect(result.taxAndServiceCharge, 0);
    });

    test('CartPricing: subtotal 130, location r316 (₹10) → fee 10, total 140', () {
      final result = CartPricing.compute(
        subtotal: 130,
        itemCount: 3,
        location: r316,
      );
      expect(result.deliveryFee, 10);
      expect(result.grandTotal, 140);
      expect(result.canCheckout, isTrue);
    });

    test('CartPricing: subtotal 20 (< 50), no fee, banner=minOrder', () {
      final result = CartPricing.compute(
        subtotal: 20,
        itemCount: 1,
        location: r234,
      );
      expect(result.deliveryFee, 0);
      expect(result.grandTotal, 20);
      expect(result.canCheckout, isFalse);
      expect(result.banner, CartBanner.minOrder);
      expect(result.shortfall, 30);
    });

    test('CartPricing: empty cart → canCheckout false, everything 0', () {
      final result = CartPricing.compute(
        subtotal: 0,
        itemCount: 0,
        location: r234,
      );
      expect(result.canCheckout, isFalse);
      expect(result.grandTotal, 0);
      expect(result.deliveryFee, 0);
    });

    test('CartPricing: subtotal >= 50, no location → banner=selectLocation', () {
      final result = CartPricing.compute(
        subtotal: 80,
        itemCount: 2,
      );
      expect(result.canCheckout, isFalse);
      expect(result.banner, CartBanner.selectLocation);
      expect(result.deliveryFee, 0);
      expect(result.grandTotal, 80);
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
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CheckoutScreen(),
        ),
      );
    }

    testWidgets('Proceed to Pay button is disabled when no location is chosen',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cartProvider = CartProvider();
      final profileProvider = ProfileProvider();
      final checkoutProvider = CheckoutProvider();

      final samosa = canteenMenuItems.firstWhere((i) => i.name.contains('Samosa'));
      // Add enough to meet minimum
      for (var i = 0; i < 3; i++) cartProvider.add(samosa); // 3×20 = 60 ≥ 50

      await tester.pumpWidget(buildTestApp(
        cartProvider: cartProvider,
        profileProvider: profileProvider,
        checkoutProvider: checkoutProvider,
      ));
      await tester.pumpAndSettle();

      // Button exists and is disabled (no location)
      final btns = find.widgetWithText(ElevatedButton, 'Proceed to Pay');
      expect(btns, findsOneWidget);
      final btn = tester.widget<ElevatedButton>(btns);
      expect(btn.onPressed, isNull);
    });

    testWidgets('Proceed to Pay button enabled once location selected',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cartProvider = CartProvider();
      final profileProvider = ProfileProvider();
      final checkoutProvider = CheckoutProvider();

      final samosa = canteenMenuItems.firstWhere((i) => i.name.contains('Samosa'));
      for (var i = 0; i < 3; i++) cartProvider.add(samosa); // 60 ≥ 50

      await tester.pumpWidget(buildTestApp(
        cartProvider: cartProvider,
        profileProvider: profileProvider,
        checkoutProvider: checkoutProvider,
      ));
      await tester.pumpAndSettle();

      // Select location programmatically
      checkoutProvider.selectLocation(r234);
      await tester.pumpAndSettle();

      // Button is now enabled
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Proceed to Pay'));
      expect(btn.onPressed, isNotNull);
    });
  });
}
