import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/core/notifications/app_notification.dart';
import 'package:college_canteen/core/notifications/order_event_notifier.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/services/order_notifications.dart';

Order createTestOrder({
  String id = 'ORD-001',
  String customerId = 'cust-1',
  String vendorId = 'canteen',
  String vendorName = 'College Canteen',
  OrderStatus status = OrderStatus.placed,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
  int? proposedPrepMinutes,
  CancelReason? cancelReason,
}) {
  final now = DateTime(2026, 11, 22, 12, 0);
  return Order(
    id: id,
    clientRequestId: 'req-$id',
    customerId: customerId,
    vendorId: vendorId,
    vendorName: vendorName,
    module: OrderModule.food,
    items: const [
      OrderItem(
        itemId: 'snack-1',
        name: 'Samosa',
        quantity: 2,
        unitPrice: 20,
        lineTotal: 40,
      ),
    ],
    locationId: 'loc-1',
    building: 'Block 1',
    block: 'A',
    floor: 1,
    room: '101',
    address: 'Room 101, Block A',
    subtotal: 40,
    deliveryFee: 10,
    taxAndServiceCharge: 0,
    grandTotal: 50,
    paymentStatus: paymentStatus,
    status: status,
    placedAt: now,
    statusHistory: [(status, now)],
    proposedPrepMinutes: proposedPrepMinutes,
    cancelReason: cancelReason,
  );
}

class FakeOrderRepository implements OrderRepository {
  final StreamController<List<Order>> controller =
      StreamController<List<Order>>.broadcast();
  List<Order> orders = [];


  @override
  Future<Order> assignPartner(String orderId, String partnerId) =>
      throw UnimplementedError();

  @override
  Future<List<Order>> assignPartners(List<String> orderIds, String partnerId) =>
      throw UnimplementedError();
  @override
  Stream<List<Order>> watchOrders() => controller.stream;
  @override
  void seedOrders(List<Order> orders) {}
  @override
  List<Order> get currentOrders => orders;

  @override
  Future<int> expireStaleOrders() async => 0;

  @override
  Future<Order> payForOrder(
    String orderId,
    String customerId,
    PaymentMethod method, {
    String? paymentReference,
  }) async =>
      orders.first;

  @override
  Future<Order> placeOrder(PlaceOrderRequest request) async => orders.first;

  @override
  Future<Order> proposeEta(
    String orderId,
    String vendorId,
    int prepMinutes,
  ) async =>
      orders.first;

  @override
  OrderQuote quote(PlaceOrderRequest request) => throw UnimplementedError();

  @override
  Future<Order> respondToEta(
    String orderId,
    String customerId, {
    required bool agree,
  }) async =>
      orders.first;

  @override
  Future<Order> updateStatus(
    String orderId,
    OrderStatus next,
    UserRole actor, {
    required String actorId,
    CancelReason? reason,
  }) async =>
      orders.first;

  void dispose() {
    controller.close();
  }
}

class FakeNotificationService implements AppNotificationService {
  final List<AppNotification> notifications = [];
  final StreamController<AppNotification> _controller =
      StreamController<AppNotification>.broadcast();

  @override
  Stream<AppNotification> get stream => _controller.stream;

  @override
  void notify(AppNotification n) {
    notifications.add(n);
    _controller.add(n);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  final now = DateTime(2026, 11, 22, 12, 0);

  group('diffOrderNotifications - Table Rows', () {
    test('Row 1: new order (placed) -> vendor', () {
      final order = createTestOrder(status: OrderStatus.placed);
      final notifications = diffOrderNotifications([], [order], now);

      expect(notifications.length, 1);
      final n = notifications.first;
      expect(n.recipientType, RecipientType.vendor);
      expect(n.recipientId, 'canteen');
      expect(n.orderId, 'ORD-001');
      expect(n.title, isNotEmpty);
      expect(n.body, 'New order request ORD-001. Send the preparation time');
      expect(n.id, 'ORD-001_placed');
    });

    test('Row 2: placed -> etaProposed -> customer', () {
      final before = createTestOrder(status: OrderStatus.placed);
      final after = before.copyWith(
        status: OrderStatus.etaProposed,
        proposedPrepMinutes: 20,
      );
      final notifications = diffOrderNotifications([before], [after], now);

      expect(notifications.length, 1);
      final n = notifications.first;
      expect(n.recipientType, RecipientType.customer);
      expect(n.recipientId, 'cust-1');
      expect(n.orderId, 'ORD-001');
      expect(n.title, isNotEmpty);
      expect(
        n.body,
        'College Canteen: ready ~20 min after you pay. Agree or decline',
      );
      expect(n.id, 'ORD-001_etaProposed');
    });

    test('Row 3: etaProposed -> etaAgreed -> vendor', () {
      final before = createTestOrder(
        status: OrderStatus.etaProposed,
        proposedPrepMinutes: 25,
      );
      final after = before.copyWith(status: OrderStatus.etaAgreed);
      final notifications = diffOrderNotifications([before], [after], now);

      expect(notifications.length, 1);
      final n = notifications.first;
      expect(n.recipientType, RecipientType.vendor);
      expect(n.recipientId, 'canteen');
      expect(n.title, isNotEmpty);
      expect(n.body, 'Customer agreed to 25 min. Accept the order');
      expect(n.id, 'ORD-001_etaAgreed');
    });

    test(
        'Row 4: etaProposed -> cancelled (customerDeclinedWait) -> vendor',
        () {
      final before = createTestOrder(status: OrderStatus.etaProposed);
      final after = before.copyWith(
        status: OrderStatus.cancelled,
        cancelReason: CancelReason.customerDeclinedWait,
      );
      final notifications = diffOrderNotifications([before], [after], now);

      expect(notifications.length, 1);
      final n = notifications.first;
      expect(n.recipientType, RecipientType.vendor);
      expect(n.recipientId, 'canteen');
      expect(n.title, isNotEmpty);
      expect(n.body, 'Customer declined the waiting time');
      expect(n.id, 'ORD-001_cancelled');
    });

    test('Row 5: etaAgreed -> accepted -> customer', () {
      final before = createTestOrder(status: OrderStatus.etaAgreed);
      final after = before.copyWith(status: OrderStatus.accepted);
      final notifications = diffOrderNotifications([before], [after], now);

      expect(notifications.length, 1);
      final n = notifications.first;
      expect(n.recipientType, RecipientType.customer);
      expect(n.recipientId, 'cust-1');
      expect(n.title, isNotEmpty);
      expect(
        n.body,
        'Accepted! Pay within ${AppConfig.paymentWindowMinutes} min to start preparing',
      );
      expect(n.id, 'ORD-001_accepted');
    });

    test('Row 6: accepted -> preparing -> vendor', () {
      final before = createTestOrder(
        status: OrderStatus.accepted,
        proposedPrepMinutes: 15,
      );
      final after = before.copyWith(status: OrderStatus.preparing);
      final notifications = diffOrderNotifications([before], [after], now);

      expect(notifications.length, 1);
      final n = notifications.first;
      expect(n.recipientType, RecipientType.vendor);
      expect(n.recipientId, 'canteen');
      expect(n.title, isNotEmpty);
      expect(
        n.body,
        'Payment received (or Cash on Delivery confirmed). Preparing ORD-001, ready in 15 min',
      );
      expect(n.id, 'ORD-001_preparing');
    });

    test('Row 7: any -> cancelled by vendor/system -> customer', () {
      final before = createTestOrder(status: OrderStatus.placed);
      final after = before.copyWith(
        status: OrderStatus.cancelled,
        cancelReason: CancelReason.vendorRejected,
      );
      final notifications = diffOrderNotifications([before], [after], now);

      expect(notifications.length, 1);
      final n = notifications.first;
      expect(n.recipientType, RecipientType.customer);
      expect(n.recipientId, 'cust-1');
      expect(n.title, isNotEmpty);
      expect(n.body, CancelReason.vendorRejected.label);
      expect(n.id, 'ORD-001_cancelled');
    });

    test('Row 8: any -> cancelled by customer/timeout -> vendor', () {
      final before = createTestOrder(status: OrderStatus.placed);
      final after = before.copyWith(
        status: OrderStatus.cancelled,
        cancelReason: CancelReason.customerCancelled,
      );
      final notifications = diffOrderNotifications([before], [after], now);

      expect(notifications.length, 1);
      final n = notifications.first;
      expect(n.recipientType, RecipientType.vendor);
      expect(n.recipientId, 'canteen');
      expect(n.title, isNotEmpty);
      expect(n.body, CancelReason.customerCancelled.label);
      expect(n.id, 'ORD-001_cancelled');
    });

    test('Row 9: preparing -> readyForPickup -> customer', () {
      final before = createTestOrder(status: OrderStatus.preparing);
      final after = before.copyWith(status: OrderStatus.readyForPickup);
      final notifications = diffOrderNotifications([before], [after], now);

      expect(notifications.length, 1);
      final n = notifications.first;
      expect(n.recipientType, RecipientType.customer);
      expect(n.recipientId, 'cust-1');
      expect(n.title, isNotEmpty);
      expect(
        n.body,
        'Your order is ready; a delivery partner will pick it up',
      );
      expect(n.id, 'ORD-001_readyForPickup');
    });

    test('Row 10: readyForPickup -> outForDelivery -> customer', () {
      final before = createTestOrder(status: OrderStatus.readyForPickup);
      final after = before.copyWith(status: OrderStatus.outForDelivery);
      final notifications = diffOrderNotifications([before], [after], now);

      expect(notifications.length, 1);
      final n = notifications.first;
      expect(n.recipientType, RecipientType.customer);
      expect(n.recipientId, 'cust-1');
      expect(n.title, isNotEmpty);
      expect(n.body, 'Your order is on the way');
      expect(n.id, 'ORD-001_outForDelivery');
    });

    test('Row 11: outForDelivery -> delivered -> customer', () {
      final before = createTestOrder(status: OrderStatus.outForDelivery);
      final after = before.copyWith(status: OrderStatus.delivered);
      final notifications = diffOrderNotifications([before], [after], now);

      expect(notifications.length, 1);
      final n = notifications.first;
      expect(n.recipientType, RecipientType.customer);
      expect(n.recipientId, 'cust-1');
      expect(n.title, isNotEmpty);
      expect(n.body, 'Delivered. Please rate your order');
      expect(n.id, 'ORD-001_delivered');
    });
  });

  group('Snapshot & deduplication rules', () {
    test('identical consecutive snapshots produce nothing', () {
      final order = createTestOrder(status: OrderStatus.placed);
      final notifications = diffOrderNotifications([order], [order], now);
      expect(notifications, isEmpty);
    });

    test('ids are deterministic and deduplicated', () {
      final order = createTestOrder(status: OrderStatus.placed);
      final diff1 = diffOrderNotifications([], [order], now);
      final diff2 = diffOrderNotifications([], [order], now);

      expect(diff1.first.id, equals(diff2.first.id));
      expect(diff1.first.id, 'ORD-001_placed');

      // Multiple identical items in after list produce deduplicated notification
      final diffWithDups = diffOrderNotifications([], [order, order], now);
      expect(diffWithDups.length, 1);
    });

    test('vendor cancel notifies customer with reason label, customer decline notifies vendor', () {
      final orderVendorCancel = createTestOrder(
        id: 'ORD-VC',
        status: OrderStatus.cancelled,
        cancelReason: CancelReason.vendorCancelled,
      );
      final beforeVC = orderVendorCancel.copyWith(status: OrderStatus.preparing);
      final notifVC = diffOrderNotifications([beforeVC], [orderVendorCancel], now);
      expect(notifVC.length, 1);
      expect(notifVC.first.recipientType, RecipientType.customer);
      expect(notifVC.first.body, CancelReason.vendorCancelled.label);

      final orderCustDecline = createTestOrder(
        id: 'ORD-CD',
        status: OrderStatus.cancelled,
        cancelReason: CancelReason.customerDeclinedWait,
      );
      final beforeCD = orderCustDecline.copyWith(status: OrderStatus.etaProposed);
      final notifCD = diffOrderNotifications([beforeCD], [orderCustDecline], now);
      expect(notifCD.length, 1);
      expect(notifCD.first.recipientType, RecipientType.vendor);
      expect(notifCD.first.body, 'Customer declined the waiting time');
    });
  });

  group('OrderEventNotifier', () {
    test('the first emission produces nothing (notifier-level, with a fake stream)', () async {
      final fakeRepo = FakeOrderRepository();
      final fakeService = FakeNotificationService();
      final notifier = OrderEventNotifier(
        orderRepository: fakeRepo,
        notificationService: fakeService,
        clock: () => now,
      );

      final order1 = createTestOrder(status: OrderStatus.placed);

      // First emission
      fakeRepo.controller.add([order1]);
      await Future<void>.delayed(Duration.zero);

      // First emission must produce nothing
      expect(fakeService.notifications, isEmpty);

      // Second emission with status change
      final order2 = order1.copyWith(
        status: OrderStatus.etaProposed,
        proposedPrepMinutes: 15,
      );
      fakeRepo.controller.add([order2]);
      await Future<void>.delayed(Duration.zero);

      expect(fakeService.notifications.length, 1);
      expect(fakeService.notifications.first.recipientType, RecipientType.customer);
      expect(fakeService.notifications.first.body, contains('ready ~15 min'));

      // Identical snapshot produces nothing
      fakeRepo.controller.add([order2]);
      await Future<void>.delayed(Duration.zero);
      expect(fakeService.notifications.length, 1);

      notifier.dispose();
      fakeRepo.dispose();
      fakeService.dispose();
    });
  });
}
