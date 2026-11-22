import 'dart:async';
import 'dart:math' as math;

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/domain/cart_pricing.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/models/order.dart';

abstract interface class OrderRepository {
  Stream<List<Order>> watchOrders();
  List<Order> get currentOrders;
  OrderQuote quote(PlaceOrderRequest request);
  Future<Order> placeOrder(PlaceOrderRequest request);
  Future<Order> updateStatus(String orderId, OrderStatus next, UserRole actor);
}

class InMemoryOrderRepository implements OrderRepository {
  final MenuRepository _menuRepository;
  final List<DeliveryLocation> _deliveryLocations;
  final DateTime Function() _clock;
  final bool Function(String vendorId) _isVendorOpen;
  final math.Random _random;

  final List<Order> _orders;
  final StreamController<List<Order>> _ordersController =
      StreamController<List<Order>>.broadcast();

  InMemoryOrderRepository({
    required MenuRepository menuRepository,
    List<DeliveryLocation> deliveryLocations = kDeliveryLocations,
    DateTime Function()? clock,
    bool Function(String vendorId)? isVendorOpen,
    math.Random? random,
    List<Order>? initialOrders,
  })  : _menuRepository = menuRepository,
        _deliveryLocations = deliveryLocations,
        _clock = clock ?? DateTime.now,
        _isVendorOpen = isVendorOpen ?? ((_) => true),
        _random = random ?? math.Random(),
        _orders = List<Order>.from(initialOrders ?? const []);

  void seedOrders(List<Order> orders) {
    _orders.addAll(orders);
    if (!_ordersController.isClosed) {
      _ordersController.add(currentOrders);
    }
  }

  @override
  List<Order> get currentOrders => List.unmodifiable(_orders);

  @override
  Stream<List<Order>> watchOrders() async* {
    yield currentOrders;
    yield* _ordersController.stream;
  }

  @override
  OrderQuote quote(PlaceOrderRequest request) {
    final catalog = _menuRepository.currentItems;
    final vendorName = catalog
            .cast<MenuItem?>()
            .firstWhere(
              (i) => i?.vendorId == request.vendorId,
              orElse: () => null,
            )
            ?.vendorName ??
        (request.vendorId == AppConfig.defaultVendorId
            ? AppConfig.defaultVendorName
            : request.vendorId);

    if (!_isVendorOpen(request.vendorId)) {
      throw OrderValidationException(
        '$vendorName is not accepting orders right now',
      );
    }

    final location = _deliveryLocations.cast<DeliveryLocation?>().firstWhere(
          (l) => l?.id == request.locationId,
          orElse: () => null,
        );
    if (location == null) {
      throw const OrderValidationException(
        'Delivery location is invalid or missing',
      );
    }

    if (request.lines.isEmpty || request.lines.every((line) => line.$2 <= 0)) {
      throw const OrderValidationException('Cart cannot be empty');
    }

    final orderItems = <OrderItem>[];
    var totalQuantity = 0;
    var subtotal = 0;

    // Check multiple vendors across lines
    final lineVendorIds = <String>{};
    for (final line in request.lines) {
      if (line.$2 <= 0) continue;
      final item = catalog.cast<MenuItem?>().firstWhere(
            (i) => i?.id == line.$1,
            orElse: () => null,
          );
      if (item != null) {
        lineVendorIds.add(item.vendorId);
      }
    }
    if (lineVendorIds.length > 1) {
      throw const OrderValidationException(
        'Cannot order items from multiple vendors',
      );
    }

    for (final line in request.lines) {
      final itemId = line.$1;
      final quantity = line.$2;
      if (quantity <= 0) continue;

      final item = catalog.cast<MenuItem?>().firstWhere(
            (i) => i?.id == itemId,
            orElse: () => null,
          );
      if (item == null) {
        throw OrderValidationException('Item "$itemId" not found in menu');
      }
      if (!item.isAvailable) {
        throw OrderValidationException(
          'Item "${item.name}" is currently unavailable',
        );
      }
      if (item.vendorId != request.vendorId) {
        throw const OrderValidationException(
          'Cannot order items from multiple vendors',
        );
      }

      final lineTotal = item.price * quantity;
      subtotal += lineTotal;
      totalQuantity += quantity;
      orderItems.add(
        OrderItem(
          itemId: item.id,
          name: item.name,
          quantity: quantity,
          unitPrice: item.price,
          lineTotal: lineTotal,
        ),
      );
    }

    if (orderItems.isEmpty) {
      throw const OrderValidationException('Cart cannot be empty');
    }

    final pricing = CartPricing.compute(
      subtotal: subtotal,
      itemCount: totalQuantity,
      location: location,
    );

    if (!pricing.meetsMinimum) {
      throw OrderValidationException(
        'Order subtotal (₹$subtotal) is below the minimum required ₹${AppConfig.minOrderSubtotal}',
      );
    }

    return OrderQuote(
      lines: orderItems,
      subtotal: pricing.subtotal,
      deliveryFee: pricing.deliveryFee,
      taxAndServiceCharge: pricing.taxAndServiceCharge,
      grandTotal: pricing.grandTotal,
      vendorId: request.vendorId,
      vendorName: vendorName,
      location: location,
    );
  }

  @override
  Future<Order> placeOrder(PlaceOrderRequest request) async {
    // Idempotent check
    final existingIndex = _orders.indexWhere(
      (o) => o.clientRequestId == request.clientRequestId,
    );
    if (existingIndex >= 0) {
      return _orders[existingIndex];
    }

    final orderQuote = quote(request);

    if (orderQuote.grandTotal != request.expectedTotal) {
      throw PriceChangedException(orderQuote.grandTotal);
    }

    final placedAt = _clock();
    final catalog = _menuRepository.currentItems;
    final maxPrep = orderQuote.lines.map((line) {
      final catItem = catalog.firstWhere((i) => i.id == line.itemId);
      return catItem.prepMaxMinutes;
    }).fold(0, (max, current) => current > max ? current : max);

    final estimatedReadyTime = placedAt.add(Duration(minutes: maxPrep));
    final orderId = _generateOrderId(placedAt);

    final paymentStatus = request.paymentMethod == PaymentMethod.cod
        ? PaymentStatus.payOnDelivery
        : PaymentStatus.paid;

    final order = Order(
      id: orderId,
      clientRequestId: request.clientRequestId,
      customerId: request.customerId,
      vendorId: orderQuote.vendorId,
      vendorName: orderQuote.vendorName,
      module: OrderModule.food,
      items: orderQuote.lines,
      locationId: orderQuote.location.id,
      building: orderQuote.location.building,
      block: orderQuote.location.block,
      floor: orderQuote.location.floor,
      room: orderQuote.location.room,
      address: orderQuote.location.address,
      subtotal: orderQuote.subtotal,
      deliveryFee: orderQuote.deliveryFee,
      taxAndServiceCharge: orderQuote.taxAndServiceCharge,
      grandTotal: orderQuote.grandTotal,
      paymentMethod: request.paymentMethod,
      paymentStatus: paymentStatus,
      status: OrderStatus.placed,
      placedAt: placedAt,
      estimatedReadyTime: estimatedReadyTime,
      statusHistory: [(OrderStatus.placed, placedAt)],
      assignedPartnerId: null,
    );

    _orders.add(order);
    if (!_ordersController.isClosed) {
      _ordersController.add(currentOrders);
    }

    return order;
  }

  @override
  Future<Order> updateStatus(
    String orderId,
    OrderStatus next,
    UserRole actor,
  ) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw StateError('Order not found: $orderId');
    }

    final currentOrder = _orders[index];
    if (!OrderStatus.isTransitionAllowed(currentOrder.status, next, actor)) {
      throw StateError(
        'Cannot transition order $orderId from ${currentOrder.status.name} to ${next.name} as ${actor.name}',
      );
    }

    final now = _clock();
    final updatedHistory =
        List<(OrderStatus, DateTime)>.from(currentOrder.statusHistory)
          ..add((next, now));

    final updatedOrder = currentOrder.copyWith(
      status: next,
      statusHistory: updatedHistory,
    );

    _orders[index] = updatedOrder;
    if (!_ordersController.isClosed) {
      _ordersController.add(currentOrders);
    }

    return updatedOrder;
  }

  String _generateOrderId(DateTime placedAt) {
    final yy = (placedAt.year % 100).toString().padLeft(2, '0');
    final mm = placedAt.month.toString().padLeft(2, '0');
    final dd = placedAt.day.toString().padLeft(2, '0');
    final datePrefix = 'ORD-$yy$mm$dd-';

    final existingTodayCount = _orders
        .where((o) => o.id.startsWith(datePrefix))
        .map((o) => o.id)
        .toSet()
        .length;

    if (existingTodayCount >= 10000) {
      throw const OrderValidationException(
        'Order capacity reached for today. Please try again tomorrow.',
      );
    }

    final existingIds = _orders.map((o) => o.id).toSet();
    while (true) {
      final nnnn = _random.nextInt(10000).toString().padLeft(4, '0');
      final candidateId = '$datePrefix$nnnn';
      if (!existingIds.contains(candidateId)) {
        return candidateId;
      }
    }
  }

  void dispose() {
    _ordersController.close();
  }
}
