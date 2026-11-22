import 'dart:async';
import 'dart:math' as math;

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/domain/cart_pricing.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/services/order_timeouts.dart';

abstract interface class OrderRepository {
  Stream<List<Order>> watchOrders();
  List<Order> get currentOrders;
  OrderQuote quote(PlaceOrderRequest request);
  Future<Order> placeOrder(PlaceOrderRequest request);
  Future<Order> proposeEta(String orderId, String vendorId, int prepMinutes);
  Future<Order> respondToEta(
    String orderId,
    String customerId, {
    required bool agree,
  });
  Future<Order> assignPartner(String orderId, String partnerId);
  Future<List<Order>> assignPartners(List<String> orderIds, String partnerId);
  Future<Order> updateStatus(
    String orderId,
    OrderStatus next,
    UserRole actor, {
    required String actorId,
    CancelReason? reason,
  });
  Future<Order> payForOrder(
    String orderId,
    String customerId,
    PaymentMethod method, {
    String? paymentReference,
  });
  Future<int> expireStaleOrders();
  void seedOrders(List<Order> orders);
}

class InMemoryOrderRepository implements OrderRepository {
  final MenuRepository _menuRepository;
  final List<DeliveryLocation> _deliveryLocations;
  final DateTime Function() _clock;
  final bool Function(String vendorId) _isVendorOpen;
  final math.Random _random;
  final bool _autoAcceptAfterCustomerAgrees;

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
    bool? autoAcceptAfterCustomerAgrees,
  })  : _menuRepository = menuRepository,
        _deliveryLocations = deliveryLocations,
        _clock = clock ?? DateTime.now,
        _isVendorOpen = isVendorOpen ?? ((_) => true),
        _random = random ?? math.Random(),
        _autoAcceptAfterCustomerAgrees = autoAcceptAfterCustomerAgrees ??
            AppConfig.autoAcceptAfterCustomerAgrees,
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
    final orderId = _generateOrderId(placedAt);

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
      paymentMethod: null,
      paymentStatus: PaymentStatus.unpaid,
      status: OrderStatus.placed,
      placedAt: placedAt,
      estimatedReadyTime: null,
      statusHistory: [(OrderStatus.placed, placedAt)],
      assignedPartnerId: null,
      proposedPrepMinutes: null,
      paidAt: null,
      cancelReason: null,
    );

    _orders.add(order);
    if (!_ordersController.isClosed) {
      _ordersController.add(currentOrders);
    }

    return order;
  }

  @override
  Future<Order> proposeEta(
    String orderId,
    String vendorId,
    int prepMinutes,
  ) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw StateError('Order not found: $orderId');
    }

    final order = _orders[index];
    if (order.vendorId != vendorId) {
      throw StateError('Vendor $vendorId does not own order $orderId');
    }
    if (order.status != OrderStatus.placed) {
      throw StateError(
        'Cannot propose ETA for order $orderId in status ${order.status.name}',
      );
    }
    if (prepMinutes < AppConfig.minProposedPrepMinutes ||
        prepMinutes > AppConfig.maxProposedPrepMinutes) {
      throw ArgumentError.value(
        prepMinutes,
        'prepMinutes',
        'Proposed prep time must be between ${AppConfig.minProposedPrepMinutes} and ${AppConfig.maxProposedPrepMinutes} minutes',
      );
    }

    final now = _clock();
    final updatedHistory =
        List<(OrderStatus, DateTime)>.from(order.statusHistory)
          ..add((OrderStatus.etaProposed, now));

    final updated = order.copyWith(
      status: OrderStatus.etaProposed,
      proposedPrepMinutes: prepMinutes,
      statusHistory: updatedHistory,
    );

    _orders[index] = updated;
    if (!_ordersController.isClosed) {
      _ordersController.add(currentOrders);
    }
    return updated;
  }

  @override
  Future<Order> respondToEta(
    String orderId,
    String customerId, {
    required bool agree,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw StateError('Order not found: $orderId');
    }

    final order = _orders[index];
    if (order.customerId != customerId) {
      throw StateError('Customer $customerId does not own order $orderId');
    }
    if (order.status != OrderStatus.etaProposed) {
      throw StateError(
        'Cannot respond to ETA for order $orderId in status ${order.status.name}',
      );
    }

    final now = _clock();
    if (!agree) {
      final updatedHistory =
          List<(OrderStatus, DateTime)>.from(order.statusHistory)
            ..add((OrderStatus.cancelled, now));
      final updated = order.copyWith(
        status: OrderStatus.cancelled,
        cancelReason: CancelReason.customerDeclinedWait,
        statusHistory: updatedHistory,
      );
      _orders[index] = updated;
      if (!_ordersController.isClosed) {
        _ordersController.add(currentOrders);
      }
      return updated;
    }

    // Customer agrees
    final agreedHistory =
        List<(OrderStatus, DateTime)>.from(order.statusHistory)
          ..add((OrderStatus.etaAgreed, now));
    var updated = order.copyWith(
      status: OrderStatus.etaAgreed,
      statusHistory: agreedHistory,
    );

    if (_autoAcceptAfterCustomerAgrees) {
      final acceptedHistory =
          List<(OrderStatus, DateTime)>.from(updated.statusHistory)
            ..add((OrderStatus.accepted, now));
      updated = updated.copyWith(
        status: OrderStatus.accepted,
        statusHistory: acceptedHistory,
      );
    }

    _orders[index] = updated;
    if (!_ordersController.isClosed) {
      _ordersController.add(currentOrders);
    }
    return updated;
  }

  @override
  Future<Order> assignPartner(String orderId, String partnerId) async {
    final updated = await assignPartners([orderId], partnerId);
    return updated.first;
  }

  @override
  Future<List<Order>> assignPartners(
    List<String> orderIds,
    String partnerId,
  ) async {
    final uniqueIds = orderIds.toSet().toList();
    if (uniqueIds.isEmpty) {
      throw const AppException('Order list cannot be empty');
    }

    final indices = <int>[];
    for (final id in uniqueIds) {
      final index = _orders.indexWhere((o) => o.id == id);
      if (index == -1) {
        throw AppException('Order not found: $id');
      }
      final order = _orders[index];
      if (order.assignedPartnerId != null) {
        throw const AppException('Order already taken');
      }
      if (order.status != OrderStatus.preparing &&
          order.status != OrderStatus.readyForPickup) {
        throw const AppException('This order is not available for delivery');
      }
      indices.add(index);
    }

    final updatedList = <Order>[];
    for (final index in indices) {
      final updated = _orders[index].copyWith(
        assignedPartnerId: partnerId,
      );
      _orders[index] = updated;
      updatedList.add(updated);
    }

    if (!_ordersController.isClosed) {
      _ordersController.add(currentOrders);
    }

    return updatedList;
  }

  @override
  Future<Order> updateStatus(
    String orderId,
    OrderStatus next,
    UserRole actor, {
    required String actorId,
    CancelReason? reason,
  }) async {
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

    // Ownership checks
    if (actor == UserRole.vendor && currentOrder.vendorId != actorId) {
      throw StateError('Vendor $actorId does not own order $orderId');
    }
    if (actor == UserRole.customer && currentOrder.customerId != actorId) {
      throw StateError('Customer $actorId does not own order $orderId');
    }
    if (actor == UserRole.deliveryPartner &&
        currentOrder.assignedPartnerId != actorId) {
      throw const AppException('This order is assigned to another partner');
    }

    final now = _clock();
    final updatedHistory =
        List<(OrderStatus, DateTime)>.from(currentOrder.statusHistory)
          ..add((next, now));

    CancelReason? effectiveReason = reason;
    PaymentStatus effectivePaymentStatus = currentOrder.paymentStatus;

    if (next == OrderStatus.cancelled) {
      effectiveReason ??= switch (actor) {
        UserRole.customer => CancelReason.customerCancelled,
        UserRole.vendor => (currentOrder.status == OrderStatus.placed ||
                currentOrder.status == OrderStatus.etaProposed ||
                currentOrder.status == OrderStatus.etaAgreed)
            ? CancelReason.vendorRejected
            : CancelReason.vendorCancelled,
        _ => null,
      };

      if (currentOrder.paymentStatus == PaymentStatus.paid) {
        effectivePaymentStatus = PaymentStatus.refundPending;
      }
    }

    final updatedOrder = currentOrder.copyWith(
      status: next,
      statusHistory: updatedHistory,
      cancelReason: effectiveReason,
      paymentStatus: effectivePaymentStatus,
    );

    _orders[index] = updatedOrder;
    if (!_ordersController.isClosed) {
      _ordersController.add(currentOrders);
    }

    return updatedOrder;
  }

  @override
  Future<Order> payForOrder(
    String orderId,
    String customerId,
    PaymentMethod method, {
    String? paymentReference,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw StateError('Order not found: $orderId');
    }

    final order = _orders[index];
    if (order.customerId != customerId) {
      throw StateError('Customer $customerId does not own order $orderId');
    }

    // Idempotent: repeat call on already paid or COD order returns unchanged
    if (order.paymentStatus == PaymentStatus.paid ||
        order.paymentStatus == PaymentStatus.payOnDelivery) {
      return order;
    }

    if (order.status != OrderStatus.accepted ||
        order.paymentStatus != PaymentStatus.unpaid) {
      throw StateError(
        'Cannot pay for order $orderId with status ${order.status.name} and payment status ${order.paymentStatus.name}',
      );
    }

    final now = _clock();
    if (OrderTimeouts.isExpired(order, now)) {
      final updatedHistory =
          List<(OrderStatus, DateTime)>.from(order.statusHistory)
            ..add((OrderStatus.cancelled, now));
      final cancelledOrder = order.copyWith(
        status: OrderStatus.cancelled,
        cancelReason: CancelReason.paymentTimeout,
        statusHistory: updatedHistory,
      );
      _orders[index] = cancelledOrder;
      if (!_ordersController.isClosed) {
        _ordersController.add(currentOrders);
      }
      throw const OrderValidationException(
        'Payment window has expired. Your order has been cancelled.',
      );
    }

    final paymentStatus = method == PaymentMethod.cod
        ? PaymentStatus.payOnDelivery
        : PaymentStatus.paid;
    final paidAt = method == PaymentMethod.cod ? null : now;
    final prepMinutes = order.proposedPrepMinutes ?? 0;
    final estimatedReadyTime = now.add(Duration(minutes: prepMinutes));

    final updatedHistory =
        List<(OrderStatus, DateTime)>.from(order.statusHistory)
          ..add((OrderStatus.preparing, now));

    final updatedOrder = order.copyWith(
      status: OrderStatus.preparing,
      paymentMethod: method,
      paymentStatus: paymentStatus,
      paidAt: paidAt,
      estimatedReadyTime: estimatedReadyTime,
      statusHistory: updatedHistory,
    );

    _orders[index] = updatedOrder;
    if (!_ordersController.isClosed) {
      _ordersController.add(currentOrders);
    }
    return updatedOrder;
  }

  @override
  Future<int> expireStaleOrders() async {
    final now = _clock();
    var cancelledCount = 0;

    for (var i = 0; i < _orders.length; i++) {
      final order = _orders[i];
      if (OrderTimeouts.isExpired(order, now)) {
        final reason =
            OrderTimeouts.reasonFor(order) ?? CancelReason.vendorNoResponse;
        final updatedHistory =
            List<(OrderStatus, DateTime)>.from(order.statusHistory)
              ..add((OrderStatus.cancelled, now));
        var paymentStatus = order.paymentStatus;
        if (paymentStatus == PaymentStatus.paid) {
          paymentStatus = PaymentStatus.refundPending;
        }

        _orders[i] = order.copyWith(
          status: OrderStatus.cancelled,
          cancelReason: reason,
          paymentStatus: paymentStatus,
          statusHistory: updatedHistory,
        );
        cancelledCount++;
      }
    }

    if (cancelledCount > 0 && !_ordersController.isClosed) {
      _ordersController.add(currentOrders);
    }
    return cancelledCount;
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
