import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/main.dart';
import 'package:college_canteen/features/food/widgets/food_card.dart';

void main() {
  testWidgets('App renders HomeScreen with spheres, navigates to MenuScreen and back',
      (WidgetTester tester) async {
    // Provide a reasonable surface size to avoid overflow during tests
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const CollegeCanteenApp());
    await tester.pumpAndSettle();

    // Verify HomeScreen renders with default guest greeting
    expect(find.text('Welcome, Campus Explorer!'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);

    // Verify Spheres
    expect(find.text('Foods'), findsOneWidget);
    expect(find.text('Bus'), findsOneWidget);
    expect(find.text('Stationary'), findsOneWidget);

    // Tap "Foods" sphere to open MenuScreen
    await tester.tap(find.text('Foods'));
    await tester.pumpAndSettle();

    // Verify MenuScreen is loaded with AppBar title and 100% Pure Veg leaf badge
    expect(find.text('College Canteen'), findsOneWidget);
    expect(find.text('100% Pure Veg'), findsOneWidget);
    expect(find.byIcon(Icons.eco), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    // Verify ChoiceChips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Snacks'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Beverages'), findsOneWidget);
    expect(find.text('Desserts'), findsOneWidget);

    // Filter by 'Desserts'
    await tester.tap(find.text('Desserts'));
    await tester.pumpAndSettle();

    expect(find.text('Chocolate Brownie'), findsOneWidget);
    expect(find.text('Gulab Jamun (2 pcs)'), findsOneWidget);
    expect(find.text('Veg Thali'), findsNothing);

    // Tap back button to return to HomeScreen
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Should be back on HomeScreen
    expect(find.text('Welcome, Campus Explorer!'), findsOneWidget);
    expect(find.text('Foods'), findsOneWidget);
  });
}
