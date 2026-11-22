import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/demo/demo_seeder.dart';
import 'package:college_canteen/core/services/app_logger.dart';
import 'package:college_canteen/core/services/role_access_service.dart';
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
import 'package:college_canteen/features/vendor/data/vendor_repository.dart';
import 'package:college_canteen/features/vendor/providers/vendors_provider.dart';

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

    final vendorRepository = InMemoryVendorRepository();
    final menuRepository = InMemoryMenuRepository();
    final orderRepository = InMemoryOrderRepository(
      menuRepository: menuRepository,
      isVendorOpen: vendorRepository.isAcceptingOrders,
    );
    if (AppConfig.kDemoMode) {
      DemoSeeder.seed(orderRepository);
    }
    final paymentGateway = MockPaymentGateway();
    final feedbackRepository = InMemoryFeedbackRepository();
    const roleAccessService = DemoRoleAccessService();

    runApp(CollegeCanteenApp(
      vendorRepository: vendorRepository,
      menuRepository: menuRepository,
      orderRepository: orderRepository,
      paymentGateway: paymentGateway,
      feedbackRepository: feedbackRepository,
      roleAccessService: roleAccessService,
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
  final VendorRepository? vendorRepository;
  final MenuRepository? menuRepository;
  final OrderRepository? orderRepository;
  final PaymentGateway? paymentGateway;
  final FeedbackRepository? feedbackRepository;
  final RoleAccessService? roleAccessService;

  const CollegeCanteenApp({
    super.key,
    this.vendorRepository,
    this.menuRepository,
    this.orderRepository,
    this.paymentGateway,
    this.feedbackRepository,
    this.roleAccessService,
  });

  @override
  Widget build(BuildContext context) {
    final vendorRepo = vendorRepository ?? InMemoryVendorRepository();
    final menuRepo = menuRepository ?? InMemoryMenuRepository();
    final orderRepo = orderRepository ??
        InMemoryOrderRepository(
          menuRepository: menuRepo,
          isVendorOpen: vendorRepo.isAcceptingOrders,
        );
    final payment = paymentGateway ?? MockPaymentGateway();
    final feedbackRepo =
        feedbackRepository ?? InMemoryFeedbackRepository();
    final roleAccess = roleAccessService ?? const DemoRoleAccessService();

    return MultiProvider(
      providers: [
        Provider<VendorRepository>.value(value: vendorRepo),
        Provider<RoleAccessService>.value(value: roleAccess),
        Provider<MenuRepository>.value(value: menuRepo),
        Provider<OrderRepository>.value(value: orderRepo),
        Provider<PaymentGateway>.value(value: payment),
        Provider<FeedbackRepository>.value(value: feedbackRepo),
        ChangeNotifierProvider<VendorsProvider>(
          create: (_) => VendorsProvider(vendorRepository: vendorRepo),
        ),
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
