import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/services/app_logger.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/data/feedback_repository.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/data/payment_gateway.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/food/providers/checkout_provider.dart';
import 'package:college_canteen/features/food/providers/menu_provider.dart';
import 'package:college_canteen/features/food/providers/orders_provider.dart';
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

    final menuRepository = InMemoryMenuRepository();
    final orderRepository =
        InMemoryOrderRepository(menuRepository: menuRepository);
    final paymentGateway = MockPaymentGateway();
    final feedbackRepository = InMemoryFeedbackRepository();

    runApp(CollegeCanteenApp(
      menuRepository: menuRepository,
      orderRepository: orderRepository,
      paymentGateway: paymentGateway,
      feedbackRepository: feedbackRepository,
    ));
  }, (error, stackTrace) {
    AppLogger.error(
      'Unhandled async error',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

class CollegeCanteenApp extends StatelessWidget {
  final MenuRepository? menuRepository;
  final OrderRepository? orderRepository;
  final PaymentGateway? paymentGateway;
  final FeedbackRepository? feedbackRepository;

  const CollegeCanteenApp({
    super.key,
    this.menuRepository,
    this.orderRepository,
    this.paymentGateway,
    this.feedbackRepository,
  });

  @override
  Widget build(BuildContext context) {
    final menuRepo = menuRepository ?? InMemoryMenuRepository();
    final orderRepo = orderRepository ??
        InMemoryOrderRepository(menuRepository: menuRepo);
    final payment = paymentGateway ?? MockPaymentGateway();
    final feedbackRepo =
        feedbackRepository ?? InMemoryFeedbackRepository();

    return MultiProvider(
      providers: [
        Provider<MenuRepository>.value(value: menuRepo),
        Provider<OrderRepository>.value(value: orderRepo),
        Provider<PaymentGateway>.value(value: payment),
        Provider<FeedbackRepository>.value(value: feedbackRepo),
        ChangeNotifierProvider<MenuProvider>(
          create: (_) => MenuProvider(repository: menuRepo),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(),
        ),
        ChangeNotifierProvider<CheckoutProvider>(
          create: (_) => CheckoutProvider(),
        ),
        ChangeNotifierProvider<OrdersProvider>(
          create: (ctx) => OrdersProvider(
            orderRepository: orderRepo,
            profileProvider: ctx.read<ProfileProvider>(),
          ),
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
