import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/main.dart';
import 'package:college_canteen/features/profile/customer_profile.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';
import 'package:college_canteen/features/food/screens/checkout_screen.dart';
import 'package:college_canteen/features/profile/profile_screen.dart';
import 'package:college_canteen/core/theme/app_theme.dart';

void main() {
  group('ProfileScreen Form Validation Tests', () {
    testWidgets('shows validation errors on empty or invalid inputs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileScreen(isMandatory: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save & Continue with blank inputs
      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();

      // Required errors
      expect(find.text('Full Name is required'), findsOneWidget);
      expect(find.text('Mobile Number is required'), findsOneWidget);

      // Enter invalid data
      final textFields = find.byType(TextFormField);

      // Full Name: with numbers
      await tester.enterText(textFields.at(0), 'Jo12');
      // Mobile Number: less than 10 digits
      await tester.enterText(textFields.at(1), '55555');

      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Letters and spaces only'), findsOneWidget);
      expect(find.text('Mobile Number must be exactly 10 digits'), findsOneWidget);

      // Test mobile starts with 6-9
      await tester.enterText(textFields.at(1), '1234567890');
      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Mobile Number must start with 6, 7, 8, or 9'),
        findsOneWidget,
      );
    });

    testWidgets('valid form saves profile and proceeds to CheckoutScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final profileProvider = ProfileProvider();
      final cartProvider = CartProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileScreen(isMandatory: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Rohit Sharma');
      await tester.enterText(textFields.at(1), '9876543210');

      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();

      // Profile saved in provider
      expect(profileProvider.hasProfile, isTrue);
      expect(profileProvider.profile?.fullName, 'Rohit Sharma');
      expect(profileProvider.profile?.mobileNumber, '9876543210');

      // Navigated to Checkout (coming next)
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(find.text('Checkout (coming next)'), findsOneWidget);
      expect(find.text('Rohit Sharma'), findsOneWidget);
    });

    testWidgets('Back to Cart button exits mandatory mode',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(isMandatory: true),
                    ),
                  );
                },
                child: const Text('Go To Profile'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go To Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Create Customer Profile'), findsOneWidget);
      expect(find.text('Back to Cart'), findsOneWidget);

      await tester.tap(find.text('Back to Cart'));
      await tester.pumpAndSettle();

      // Returned to previous screen
      expect(find.text('Go To Profile'), findsOneWidget);
    });

    testWidgets('editing from profile icon is pre-filled and can pop freely',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final profileProvider = ProfileProvider()
        ..save(
          const CustomerProfile(
            fullName: 'Ananya Rao',
            mobileNumber: '9123456780',
          ),
        );

      await tester.pumpWidget(
        ChangeNotifierProvider<ProfileProvider>.value(
          value: profileProvider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileScreen(isMandatory: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Customer Profile'), findsOneWidget);
      expect(find.text('Ananya Rao'), findsOneWidget);
      expect(find.text('9123456780'), findsOneWidget);

      // Change name and save
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ananya K Rao');
      await tester.tap(find.text('Save Details'));
      await tester.pumpAndSettle();

      expect(profileProvider.profile?.fullName, 'Ananya K Rao');
    });
  });

  group('Full Customer Journey: First Proceed forces form, Second Proceed skips it', () {
    testWidgets('first Proceed forces form, second Proceed skips to checkout',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const CollegeCanteenApp());
      await tester.pumpAndSettle();

      // Add item to cart
      await tester.tap(find.text('Add to Order').first);
      await tester.pumpAndSettle();

      // FIRST PROCEED: Tapping Proceed to Order when hasProfile is false
      await tester.tap(find.text('Proceed to Order'));
      await tester.pumpAndSettle();

      // Forced to Create Customer Profile screen
      expect(find.text('Create Customer Profile'), findsOneWidget);
      expect(find.text('Back to Cart'), findsOneWidget);

      // Fill in valid details
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Kavita Iyer');
      await tester.enterText(textFields.at(1), '9988776655');

      // Tap Save & Continue
      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();

      // Now at Checkout screen
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(find.text('Checkout (coming next)'), findsOneWidget);
      expect(find.text('Kavita Iyer'), findsOneWidget);

      // Return back to menu screen
      await tester.tap(find.text('Back to Menu'));
      await tester.pumpAndSettle();

      // Verify on Menu Screen with items in cart
      expect(find.text('College Canteen'), findsOneWidget);
      expect(find.text('Proceed to Order'), findsOneWidget);

      // SECOND PROCEED: Tapping Proceed to Order now hasProfile is true!
      await tester.tap(find.text('Proceed to Order'));
      await tester.pumpAndSettle();

      // Should SKIP profile form and go directly to Checkout!
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(find.text('Create Customer Profile'), findsNothing);
      expect(find.text('Checkout (coming next)'), findsOneWidget);
    });
  });
}
