import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/demo/demo_seeder.dart';
import 'package:college_canteen/core/notifications/app_notification.dart';
import 'package:college_canteen/core/notifications/notification_host.dart';
import 'package:college_canteen/core/notifications/order_event_notifier.dart';
import 'package:college_canteen/core/notifications/order_expiry_service.dart';
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
    final feedbackRepository = InMemoryFeedbackRepository();
    if (AppConfig.kDemoMode) {
      DemoSeeder.seed(
        orderRepository,
        feedbackRepo: feedbackRepository,
      );
    }
    final paymentGateway = MockPaymentGateway();
    const roleAccessService = DemoRoleAccessService();
    final notificationService = InAppNotificationService();
    final orderEventNotifier = OrderEventNotifier(
      orderRepository: orderRepository,
      notificationService: notificationService,
    );
    final orderExpiryService = OrderExpiryService(
      orderRepository: orderRepository,
    );

    runApp(CollegeCanteenApp(
      vendorRepository: vendorRepository,
      menuRepository: menuRepository,
      orderRepository: orderRepository,
      paymentGateway: paymentGateway,
      feedbackRepository: feedbackRepository,
      roleAccessService: roleAccessService,
      notificationService: notificationService,
      orderEventNotifier: orderEventNotifier,
      orderExpiryService: orderExpiryService,
    ));
  }, (error, stackTrace) {
    AppLogger.error(
      'Unhandled async error',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

class CollegeCanteenApp extends StatefulWidget {
  final VendorRepository? vendorRepository;
  final MenuRepository? menuRepository;
  final OrderRepository? orderRepository;
  final PaymentGateway? paymentGateway;
  final FeedbackRepository? feedbackRepository;
  final RoleAccessService? roleAccessService;
  final AppNotificationService? notificationService;
  final OrderEventNotifier? orderEventNotifier;
  final OrderExpiryService? orderExpiryService;

  const CollegeCanteenApp({
    super.key,
    this.vendorRepository,
    this.menuRepository,
    this.orderRepository,
    this.paymentGateway,
    this.feedbackRepository,
    this.roleAccessService,
    this.notificationService,
    this.orderEventNotifier,
    this.orderExpiryService,
  });

  @override
  State<CollegeCanteenApp> createState() => _CollegeCanteenAppState();
}

class _CollegeCanteenAppState extends State<CollegeCanteenApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final VendorRepository _vendorRepository;
  late final MenuRepository _menuRepository;
  late final OrderRepository _orderRepository;
  late final PaymentGateway _paymentGateway;
  late final FeedbackRepository _feedbackRepository;
  late final RoleAccessService _roleAccessService;
  late final AppNotificationService _notificationService;
  late final OrderEventNotifier _orderEventNotifier;
  late final OrderExpiryService _orderExpiryService;

  bool _internalNotificationService = false;
  bool _internalOrderEventNotifier = false;
  bool _internalOrderExpiryService = false;

  @override
  void initState() {
    super.initState();
    _vendorRepository = widget.vendorRepository ?? InMemoryVendorRepository();
    _menuRepository = widget.menuRepository ?? InMemoryMenuRepository();
    _orderRepository = widget.orderRepository ??
        InMemoryOrderRepository(
          menuRepository: _menuRepository,
          isVendorOpen: _vendorRepository.isAcceptingOrders,
        );
    _paymentGateway = widget.paymentGateway ?? MockPaymentGateway();
    _feedbackRepository =
        widget.feedbackRepository ?? InMemoryFeedbackRepository();
    _roleAccessService =
        widget.roleAccessService ?? const DemoRoleAccessService();

    if (widget.notificationService != null) {
      _notificationService = widget.notificationService!;
    } else {
      _notificationService = InAppNotificationService();
      _internalNotificationService = true;
    }

    if (widget.orderEventNotifier != null) {
      _orderEventNotifier = widget.orderEventNotifier!;
    } else {
      _orderEventNotifier = OrderEventNotifier(
        orderRepository: _orderRepository,
        notificationService: _notificationService,
      );
      _internalOrderEventNotifier = true;
    }

    if (widget.orderExpiryService != null) {
      _orderExpiryService = widget.orderExpiryService!;
    } else {
      _orderExpiryService = OrderExpiryService(
        orderRepository: _orderRepository,
      );
      _internalOrderExpiryService = true;
    }
  }

  @override
  void dispose() {
    if (_internalOrderExpiryService) {
      _orderExpiryService.dispose();
    }
    if (_internalOrderEventNotifier) {
      _orderEventNotifier.dispose();
    }
    if (_internalNotificationService &&
        _notificationService is InAppNotificationService) {
      (_notificationService as InAppNotificationService).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<VendorRepository>.value(value: _vendorRepository),
        Provider<RoleAccessService>.value(value: _roleAccessService),
        Provider<MenuRepository>.value(value: _menuRepository),
        Provider<OrderRepository>.value(value: _orderRepository),
        Provider<PaymentGateway>.value(value: _paymentGateway),
        Provider<FeedbackRepository>.value(value: _feedbackRepository),
        Provider<AppNotificationService>.value(value: _notificationService),
        Provider<OrderEventNotifier>.value(value: _orderEventNotifier),
        Provider<OrderExpiryService>.value(value: _orderExpiryService),
        ChangeNotifierProvider<VendorsProvider>(
          create: (_) => VendorsProvider(vendorRepository: _vendorRepository),
        ),
        ChangeNotifierProvider<MenuProvider>(
          create: (_) => MenuProvider(repository: _menuRepository),
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
            orderRepository: _orderRepository,
            profileProvider: ctx.read<ProfileProvider>(),
          ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'College Canteen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) => NotificationHost(
          navigatorKey: _navigatorKey,
          notificationService: _notificationService,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
