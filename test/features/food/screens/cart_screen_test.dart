import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/features/food/data/menu_data.dart';
import 'package:college_canteen/main.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/food/screens/cart_screen.dart';
import 'package:college_canteen/core/theme/app_theme.dart';

void main() {
  group('CartScreen Widget Tests', () {
    testWidgets('displays empty state when cart has no items',
        (WidgetTester tester) async {
      final cart = CartProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<CartProvider>.value(
          value: cart,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify empty state texts and icon
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.text('Browse Menu'), findsOneWidget);
      expect(find.text('Proceed to Order'), findsNothing);
    });

    testWidgets('Browse Menu button pops screen', (WidgetTester tester) async {
      final cart = CartProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<CartProvider>.value(
          value: cart,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
                child: const Text('Open Cart'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Cart
      await tester.tap(find.text('Open Cart'));
      await tester.pumpAndSettle();

      expect(find.text('Your cart is empty'), findsOneWidget);

      // Tap Browse Menu
      await tester.tap(find.text('Browse Menu'));
      await tester.pumpAndSettle();

      // Back to home
      expect(find.text('Open Cart'), findsOneWidget);
      expect(find.text('Your cart is empty'), findsNothing);
    });

    testWidgets(
        'lists cart items with veg symbol, unit price, (− qty +), line total, and Base Food Price',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      final samosa = canteenMenuItems[0]; // Samosa: ₹20
      final thali = canteenMenuItems[5]; // Veg Thali: ₹90

      cart.add(samosa);
      cart.increment(samosa.id); // 2 samosas = ₹40
      cart.add(thali); // 1 thali = ₹90

      final profileProvider = ProfileProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Names
      expect(find.text('Samosa (2 pcs)'), findsOneWidget);
      expect(find.text('Veg Thali'), findsOneWidget);

      // Unit prices
      expect(find.text('₹20 each'), findsOneWidget);
      expect(find.text('₹90 each'), findsOneWidget);

      // Line totals
      expect(find.text('Line Total: ₹40'), findsOneWidget);
      expect(find.text('Line Total: ₹90'), findsOneWidget);

      // Quantities
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Base Food Price label and total (40 + 90 = 130)
      expect(find.text('Base Food Price'), findsOneWidget);
      expect(find.text('₹130'), findsOneWidget);

      // Proceed to Order button
      expect(find.text('Proceed to Order'), findsOneWidget);

      // Tap Proceed to Order when no profile -> opens Create Customer Profile
      await tester.tap(find.text('Proceed to Order'));
      await tester.pumpAndSettle();
      expect(find.text('Create Customer Profile'), findsOneWidget);
    });

    testWidgets('quantity modifications sync and removing last item shows empty state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      final samosa = canteenMenuItems[0]; // Samosa: ₹20
      cart.add(samosa); // qty 1

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Samosa (2 pcs)'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('₹20'), findsOneWidget);

      // Increment
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('Line Total: ₹40'), findsOneWidget);
      expect(find.text('₹40'), findsOneWidget);

      // Decrement twice (2 -> 1 -> 0)
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      // Cart is now empty!
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Samosa (2 pcs)'), findsNothing);
    });

    testWidgets('full integration: add from menu screen and open cart screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const CollegeCanteenApp());
      await tester.pumpAndSettle();

      // Add Samosa from menu screen
      await tester.tap(find.text('Add to Order').first);
      await tester.pumpAndSettle();

      // Tap AppBar Cart icon to open Cart screen
      await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
      await tester.pumpAndSettle();

      // Now inside Cart Screen!
      expect(find.text('Your Cart'), findsOneWidget);
      expect(find.text('Base Food Price'), findsOneWidget);
      expect(find.text('Proceed to Order'), findsOneWidget);

      // Tap Proceed to Order in Cart Screen when no profile -> opens Create Customer Profile
      await tester.tap(find.text('Proceed to Order'));
      await tester.pumpAndSettle();
      expect(find.text('Create Customer Profile'), findsOneWidget);
    });
  });
}
