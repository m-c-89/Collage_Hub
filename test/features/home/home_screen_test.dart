import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/food/providers/checkout_provider.dart';
import 'package:college_canteen/features/home/screens/home_screen.dart';
import 'package:college_canteen/features/profile/customer_profile.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';

void main() {
  Widget buildTestableHomeScreen({ProfileProvider? profileProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileProvider>.value(
          value: profileProvider ?? ProfileProvider(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }

  group('HomeScreen Tests', () {
    testWidgets('shows Welcome, Campus Explorer! when profile is empty',
        (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Welcome, Campus Explorer!'), findsOneWidget);
      expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
    });

    testWidgets('shows Welcome back, {firstName}! when profile is populated',
        (tester) async {
      final profileProvider = ProfileProvider()
        ..save(
          const CustomerProfile(
            fullName: 'Aarav Sharma',
            mobileNumber: '9876543210',
          ),
        );

      await tester.pumpWidget(
        buildTestableHomeScreen(profileProvider: profileProvider),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back, Aarav!'), findsOneWidget);
      expect(find.text('Welcome, Campus Explorer!'), findsNothing);
    });

    testWidgets('all 3 spheres render and navigate to respective screens',
        (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      // Verify spheres
      expect(find.text('Foods'), findsOneWidget);
      expect(find.text('Bus'), findsOneWidget);
      expect(find.text('Stationary'), findsOneWidget);

      // Tap Bus
      await tester.tap(find.text('Bus'));
      await tester.pumpAndSettle();
      expect(
        find.text('Live Campus Bus Tracking — Coming Soon'),
        findsOneWidget,
      );

      // Back to Home
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Foods'), findsOneWidget);

      // Tap Stationary
      await tester.tap(find.text('Stationary'));
      await tester.pumpAndSettle();
      expect(
        find.text('Quick Printouts & Stationary — Coming Soon'),
        findsOneWidget,
      );

      // Back to Home
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Foods'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at 320x568 (compact)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow at 390x844 (standard mobile)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow at 1200x800 (wide web)',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
