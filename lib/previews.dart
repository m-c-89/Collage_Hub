import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/data/feedback_repository.dart';
import 'package:college_canteen/features/food/data/menu_data.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/data/payment_gateway.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/food/providers/checkout_provider.dart';
import 'package:college_canteen/features/food/providers/menu_provider.dart';
import 'package:college_canteen/features/food/providers/orders_provider.dart';
import 'package:college_canteen/features/profile/customer_profile.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';
import 'package:college_canteen/features/food/screens/cart_screen.dart';
import 'package:college_canteen/features/food/screens/checkout_screen.dart';
import 'package:college_canteen/features/food/screens/payment_screen.dart';
import 'package:college_canteen/features/food/screens/order_confirmation_screen.dart';
import 'package:college_canteen/features/food/screens/order_tracking_screen.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/home/screens/home_screen.dart';
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
    final repo = InMemoryMenuRepository();
    final orderRepo = InMemoryOrderRepository(menuRepository: repo);
    final payment = MockPaymentGateway();
    final feedbackRepo = InMemoryFeedbackRepository();

    return MultiProvider(
      providers: [
        Provider<MenuRepository>.value(value: repo),
        Provider<OrderRepository>.value(value: orderRepo),
        Provider<PaymentGateway>.value(value: payment),
        Provider<FeedbackRepository>.value(value: feedbackRepo),
        ChangeNotifierProvider(create: (_) => MenuProvider(repository: repo)),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(
          create: (ctx) => OrdersProvider(
            orderRepository: orderRepo,
            profileProvider: ctx.read<ProfileProvider>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'College Canteen - Preview',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
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

/// Standalone Preview: Home Screen
Widget previewHomeScreen({String? name}) {
  final profileProvider = ProfileProvider();
  if (name != null) {
    profileProvider.save(
      CustomerProfile(
        fullName: name,
        mobileNumber: '9876543210',
      ),
    );
  }

  final repo = InMemoryMenuRepository();
  final orderRepo = InMemoryOrderRepository(menuRepository: repo);
  final paymentGateway = MockPaymentGateway();
  final feedbackRepo = InMemoryFeedbackRepository();

  return MultiProvider(
    providers: [
      Provider<MenuRepository>.value(value: repo),
      Provider<OrderRepository>.value(value: orderRepo),
      Provider<PaymentGateway>.value(value: paymentGateway),
      Provider<FeedbackRepository>.value(value: feedbackRepo),
      ChangeNotifierProvider(create: (_) => MenuProvider(repository: repo)),
      ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => CheckoutProvider()),
      ChangeNotifierProvider(
        create: (_) => OrdersProvider(
          orderRepository: orderRepo,
          profileProvider: profileProvider,
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    ),
  );
}

/// Standalone Preview: Payment Screen
Widget previewPaymentScreen() {
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

  final checkoutProvider = CheckoutProvider()
    ..selectLocation(kDeliveryLocations.first);

  final repo = InMemoryMenuRepository();
  final orderRepo = InMemoryOrderRepository(menuRepository: repo);
  final paymentGateway = MockPaymentGateway();

  return MultiProvider(
    providers: [
      Provider<OrderRepository>.value(value: orderRepo),
      Provider<PaymentGateway>.value(value: paymentGateway),
      ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
      ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
      ChangeNotifierProvider<CheckoutProvider>.value(value: checkoutProvider),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const PaymentScreen(),
    ),
  );
}

/// Standalone Preview: Order Confirmation Screen
Widget previewOrderConfirmationScreen() {
  final order = Order(
    id: 'ORD-123456-7890',
    clientRequestId: 'REQ-DEMO-1',
    customerId: '9876543210',
    vendorId: 'canteen',
    vendorName: 'College Canteen',
    module: OrderModule.food,
    items: const [
      OrderItem(
        itemId: 'snack-1',
        name: 'Samosa (2 pcs)',
        quantity: 2,
        unitPrice: 20,
        lineTotal: 40,
      ),
      OrderItem(
        itemId: 'meal-1',
        name: 'Veg Thali',
        quantity: 1,
        unitPrice: 90,
        lineTotal: 90,
      ),
    ],
    locationId: 'aitr-b3-f2-r234',
    building: 'Block 3',
    block: 'B',
    floor: 2,
    room: 'Room 234',
    address: 'Block 3, Floor 2, Room 234',
    subtotal: 130,
    deliveryFee: 5,
    taxAndServiceCharge: 0,
    grandTotal: 135,
    paymentMethod: PaymentMethod.upi,
    paymentStatus: PaymentStatus.paid,
    status: OrderStatus.placed,
    placedAt: DateTime.now(),
    estimatedReadyTime: DateTime.now().add(const Duration(minutes: 15)),
    statusHistory: [(OrderStatus.placed, DateTime.now())],
  );

  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: OrderConfirmationScreen(order: order),
  );
}

/// Standalone Preview: Order Tracking Screen
Widget previewOrderTrackingScreen() {
  final repo = InMemoryMenuRepository();
  final orderRepo = InMemoryOrderRepository(menuRepository: repo);
  final feedbackRepo = InMemoryFeedbackRepository();

  final profileProvider = ProfileProvider()
    ..save(
      const CustomerProfile(
        fullName: 'Aarav Sharma',
        mobileNumber: '9876543210',
      ),
    );

  final ordersProvider = OrdersProvider(
    orderRepository: orderRepo,
    profileProvider: profileProvider,
  );

  return MultiProvider(
    providers: [
      Provider<OrderRepository>.value(value: orderRepo),
      Provider<FeedbackRepository>.value(value: feedbackRepo),
      ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
      ChangeNotifierProvider<OrdersProvider>.value(value: ordersProvider),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const OrderTrackingScreen(),
    ),
  );
}

void _dummyCallback() {}
