import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/services/app_logger.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/food/providers/checkout_provider.dart';
import 'package:college_canteen/features/home/screens/home_screen.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error(
        details.exceptionAsString(),
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error(
        'Unhandled platform error',
        error: error,
        stackTrace: stack,
      );
      return true;
    };

    if (kReleaseMode) {
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Material(
          color: AppTheme.scaffoldBackground,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong. Please try again later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      };
    }

    runApp(const CollegeCanteenApp());
  }, (error, stackTrace) {
    AppLogger.error(
      'Unhandled async error',
      error: error,
      stackTrace: stackTrace,
    );
  });
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
        home: const HomeScreen(),
      ),
    );
  }
}
