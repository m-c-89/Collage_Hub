import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/food/providers/checkout_provider.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';
import 'package:college_canteen/features/food/screens/menu_screen.dart';
import 'package:college_canteen/core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CollegeCanteenApp());
}

class CollegeCanteenApp extends StatelessWidget {
  const CollegeCanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(),
        ),
        ChangeNotifierProvider<CheckoutProvider>(
          create: (_) => CheckoutProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'College Canteen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MenuScreen(),
      ),
    );
  }
}
