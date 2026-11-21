import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/main.dart';
import 'package:college_canteen/features/food/widgets/food_card.dart';

void main() {
  testWidgets('App renders College Canteen with 100% Pure Veg badge and chips',
      (WidgetTester tester) async {
    // Provide a reasonable surface size to avoid overflow during tests
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const CollegeCanteenApp());
    await tester.pumpAndSettle();

    // Verify AppBar title and 100% Pure Veg leaf badge
    expect(find.text('College Canteen'), findsOneWidget);
    expect(find.text('100% Pure Veg'), findsOneWidget);
    expect(find.byIcon(Icons.eco), findsOneWidget);

    // Verify ChoiceChips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Snacks'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Beverages'), findsOneWidget);
    expect(find.text('Desserts'), findsOneWidget);

    // Initially "All" is selected and all 16 items are in the list
    expect(find.byType(FoodCard), findsWidgets);

    // Filter by 'Desserts'
    await tester.tap(find.text('Desserts'));
    await tester.pumpAndSettle();

    // Verify only dessert items appear
    expect(find.text('Chocolate Brownie'), findsOneWidget);
    expect(find.text('Gulab Jamun (2 pcs)'), findsOneWidget);
    expect(find.text('Veg Thali'), findsNothing);

    // Tap "Add to Order" on Chocolate Brownie
    final addBtn = find.text('Add to Order').first;
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Counter should now show quantity '1'
    expect(find.text('1'), findsOneWidget);

    // Sticky bottom bar should appear with Proceed to Order
    expect(find.text('Proceed to Order'), findsOneWidget);
    expect(find.textContaining('1 item | ₹50'), findsOneWidget);

    // Tap Proceed to Order button on menu screen (mandatory profile step when hasProfile is false)
    await tester.tap(find.text('Proceed to Order'));
    await tester.pumpAndSettle();

    // Verify Create Customer Profile screen is opened
    expect(find.text('Create Customer Profile'), findsOneWidget);
    expect(find.text('Save & Continue'), findsOneWidget);
    expect(find.text('Back to Cart'), findsOneWidget);
  });
}
