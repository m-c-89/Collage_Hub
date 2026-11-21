import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/features/food/data/menu_data.dart';
import 'package:college_canteen/features/profile/customer_profile.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/food/providers/checkout_provider.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';
import 'package:college_canteen/features/food/screens/cart_screen.dart';
import 'package:college_canteen/features/food/screens/checkout_screen.dart';
import 'package:college_canteen/features/food/screens/menu_screen.dart';
import 'package:college_canteen/features/profile/profile_screen.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/widgets/category_filter_bar.dart';
import 'package:college_canteen/features/food/widgets/food_card.dart';
import 'package:college_canteen/features/food/widgets/quantity_selector.dart';

void main() {
  runApp(const PreviewsApp());
}

/// Full interactive preview of the application
class PreviewsApp extends StatelessWidget {
  const PreviewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
      ],
      child: MaterialApp(
        title: 'College Canteen - Preview',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MenuScreen(),
      ),
    );
  }
}

/// Standalone Preview: FoodCard in initial state
Widget previewFoodCard() {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Center(
        child: SizedBox(
          width: 400,
          child: FoodCard(
            item: canteenMenuItems.first, // Samosa
            quantity: 0,
            onAdd: _dummyCallback,
            onIncrement: _dummyCallback,
            onDecrement: _dummyCallback,
          ),
        ),
      ),
    ),
  );
}

/// Standalone Preview: FoodCard with active quantity
Widget previewFoodCardWithQuantity() {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Center(
        child: SizedBox(
          width: 400,
          child: FoodCard(
            item: canteenMenuItems[5], // Veg Thali
            quantity: 2,
            onAdd: _dummyCallback,
            onIncrement: _dummyCallback,
            onDecrement: _dummyCallback,
          ),
        ),
      ),
    ),
  );
}

/// Standalone Preview: Category Filter Bar
Widget previewCategoryFilterBar() {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Center(
        child: CategoryFilterBar(
          selectedCategory: 'Snacks',
          onSelected: (_) {},
        ),
      ),
    ),
  );
}

/// Standalone Preview: Quantity Selector states
Widget previewQuantitySelector() {
  return const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QuantitySelector(
              quantity: 0,
              onAdd: _dummyCallback,
              onIncrement: _dummyCallback,
              onDecrement: _dummyCallback,
            ),
            SizedBox(width: 16),
            QuantitySelector(
              quantity: 3,
              onAdd: _dummyCallback,
              onIncrement: _dummyCallback,
              onDecrement: _dummyCallback,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Standalone Preview: Cart Screen with items
Widget previewCartScreenWithItems() {
  final provider = CartProvider()
    ..add(canteenMenuItems[0]) // Samosa
    ..add(canteenMenuItems[0]) // Samosa x2
    ..add(canteenMenuItems[5]); // Veg Thali x1

  return ChangeNotifierProvider<CartProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const CartScreen(),
    ),
  );
}

/// Standalone Preview: Cart Screen Empty State
Widget previewCartScreenEmpty() {
  return ChangeNotifierProvider<CartProvider>(
    create: (_) => CartProvider(),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const CartScreen(),
    ),
  );
}

/// Standalone Preview: Create Customer Profile (Mandatory Mode)
Widget previewProfileScreenMandatory() {
  return ChangeNotifierProvider<ProfileProvider>(
    create: (_) => ProfileProvider(),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const ProfileScreen(isMandatory: true),
    ),
  );
}

/// Standalone Preview: Edit Customer Profile (Pre-filled)
Widget previewProfileScreenEdit() {
  final provider = ProfileProvider()
    ..save(
      const CustomerProfile(
        fullName: 'Aarav Sharma',
        mobileNumber: '9876543210',
      ),
    );

  return ChangeNotifierProvider<ProfileProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const ProfileScreen(isMandatory: false),
    ),
  );
}

/// Standalone Preview: Checkout Screen
Widget previewCheckoutScreen() {
  final profileProvider = ProfileProvider()
    ..save(
      const CustomerProfile(
        fullName: 'Aarav Sharma',
        mobileNumber: '9876543210',
      ),
    );

  final cartProvider = CartProvider()
    ..add(canteenMenuItems[0])
    ..add(canteenMenuItems[5]);

  final checkoutProvider = CheckoutProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
      ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
      ChangeNotifierProvider<CheckoutProvider>.value(value: checkoutProvider),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const CheckoutScreen(),
    ),
  );
}

void _dummyCallback() {}
