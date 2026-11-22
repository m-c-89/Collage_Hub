import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/services/order_timeouts.dart';

void main() {
  final baseTime = DateTime(2026, 11, 22, 10, 0, 0);

  Order makeOrder({
    required String id,
    required OrderStatus status,
    PaymentStatus paymentStatus = PaymentStatus.unpaid,
    DateTime? enteredAt,
  }) {
    final t = enteredAt ?? baseTime;
    return Order(
      id: id,
      clientRequestId: 'req-$id',
      customerId: 'cust-1',
      vendorId: 'canteen',
      vendorName: 'College Canteen',
      module: OrderModule.food,
      items: const [],
      locationId: 'loc-1',
      building: 'B1',
      block: 'A',
      floor: 1,
      room: '101',
      address: 'Address 101',
      subtotal: 50,
      deliveryFee: 5,
      taxAndServiceCharge: 0,
      grandTotal: 55,
      paymentStatus: paymentStatus,
      status: status,
      placedAt: baseTime,
      statusHistory: [(status, t)],
    );
  }

  group('OrderTimeouts - expiration boundaries (table-driven)', () {
    test('placed: 2:59 not expired, 3:00 expired', () {
      final order = makeOrder(id: 'o-placed', status: OrderStatus.placed);

      // 2 minutes 59 seconds: not expired
      final at259 = baseTime.add(const Duration(minutes: 2, seconds: 59));
      expect(OrderTimeouts.isExpired(order, at259), isFalse);

      // 3 minutes 0 seconds: expired
      final at300 = baseTime.add(const Duration(minutes: 3));
      expect(OrderTimeouts.isExpired(order, at300), isTrue);
    });

    test('etaProposed at 5:00 expired (4:59 not expired)', () {
      final order =
          makeOrder(id: 'o-eta-prop', status: OrderStatus.etaProposed);

      final at459 = baseTime.add(const Duration(minutes: 4, seconds: 59));
      expect(OrderTimeouts.isExpired(order, at459), isFalse);

      final at500 = baseTime.add(const Duration(minutes: 5));
      expect(OrderTimeouts.isExpired(order, at500), isTrue);
    });

    test('etaAgreed at 3:00 expired (2:59 not expired)', () {
      final order =
          makeOrder(id: 'o-eta-agree', status: OrderStatus.etaAgreed);

      final at259 = baseTime.add(const Duration(minutes: 2, seconds: 59));
      expect(OrderTimeouts.isExpired(order, at259), isFalse);

      final at300 = baseTime.add(const Duration(minutes: 3));
      expect(OrderTimeouts.isExpired(order, at300), isTrue);
    });

    test('accepted-unpaid at 5:00 expired (4:59 not expired)', () {
      final order = makeOrder(
        id: 'o-acc-unpaid',
        status: OrderStatus.accepted,
        paymentStatus: PaymentStatus.unpaid,
      );

      final at459 = baseTime.add(const Duration(minutes: 4, seconds: 59));
      expect(OrderTimeouts.isExpired(order, at459), isFalse);

      final at500 = baseTime.add(const Duration(minutes: 5));
      expect(OrderTimeouts.isExpired(order, at500), isTrue);
    });

    test('preparing and delivered never expire', () {
      final prepOrder =
          makeOrder(id: 'o-prep', status: OrderStatus.preparing);
      final delOrder =
          makeOrder(id: 'o-del', status: OrderStatus.delivered);

      final farFuture = baseTime.add(const Duration(days: 30));

      expect(OrderTimeouts.limitFor(prepOrder), isNull);
      expect(OrderTimeouts.deadlineFor(prepOrder), isNull);
      expect(OrderTimeouts.isExpired(prepOrder, farFuture), isFalse);

      expect(OrderTimeouts.limitFor(delOrder), isNull);
      expect(OrderTimeouts.deadlineFor(delOrder), isNull);
      expect(OrderTimeouts.isExpired(delOrder, farFuture), isFalse);
    });
  });

  group('OrderTimeouts - reasonFor per status', () {
    test('returns correct CancelReason for each status', () {
      final placed = makeOrder(id: '1', status: OrderStatus.placed);
      final etaProp = makeOrder(id: '2', status: OrderStatus.etaProposed);
      final etaAgr = makeOrder(id: '3', status: OrderStatus.etaAgreed);
      final acceptedUnpaid = makeOrder(
        id: '4',
        status: OrderStatus.accepted,
        paymentStatus: PaymentStatus.unpaid,
      );
      final preparing = makeOrder(id: '5', status: OrderStatus.preparing);
      final delivered = makeOrder(id: '6', status: OrderStatus.delivered);

      expect(OrderTimeouts.reasonFor(placed), CancelReason.vendorNoResponse);
      expect(OrderTimeouts.reasonFor(etaProp), CancelReason.customerNoResponse);
      expect(OrderTimeouts.reasonFor(etaAgr), CancelReason.vendorNoResponse);
      expect(
          OrderTimeouts.reasonFor(acceptedUnpaid), CancelReason.paymentTimeout);
      expect(OrderTimeouts.reasonFor(preparing), isNull);
      expect(OrderTimeouts.reasonFor(delivered), isNull);
    });
  });

  group('OrderTimeouts - secondsRemaining never negative', () {
    test('decreases to 0 and clamps at 0', () {
      final order = makeOrder(id: 'o-sec', status: OrderStatus.placed);

      // 1 minute in: 120 seconds left
      expect(
        OrderTimeouts.secondsRemaining(
            order, baseTime.add(const Duration(minutes: 1))),
        120,
      );

      // Exactly at deadline: 0
      expect(
        OrderTimeouts.secondsRemaining(
            order, baseTime.add(const Duration(minutes: 3))),
        0,
      );

      // 10 minutes past deadline: clamps to 0
      expect(
        OrderTimeouts.secondsRemaining(
            order, baseTime.add(const Duration(minutes: 10))),
        0,
      );
    });
  });

  group('OrderTimeouts - expireStaleOrders in InMemoryOrderRepository', () {
    test('cancels right orders with right reasons, returns count, and emits once',
        () async {
      final menuRepo = InMemoryMenuRepository(initialItems: const []);

      // 1. Placed order 4 minutes ago (limit 3 min -> expired)
      final o1 = makeOrder(
        id: 'o1',
        status: OrderStatus.placed,
        enteredAt: baseTime.subtract(const Duration(minutes: 4)),
      );

      // 2. etaProposed order 6 minutes ago (limit 5 min -> expired)
      final o2 = makeOrder(
        id: 'o2',
        status: OrderStatus.etaProposed,
        enteredAt: baseTime.subtract(const Duration(minutes: 6)),
      );

      // 3. etaAgreed order 1 minute ago (limit 3 min -> NOT expired)
      final o3 = makeOrder(
        id: 'o3',
        status: OrderStatus.etaAgreed,
        enteredAt: baseTime.subtract(const Duration(minutes: 1)),
      );

      // 4. accepted order 10 minutes ago (limit 5 min -> expired)
      final o4 = makeOrder(
        id: 'o4',
        status: OrderStatus.accepted,
        paymentStatus: PaymentStatus.unpaid,
        enteredAt: baseTime.subtract(const Duration(minutes: 10)),
      );

      // 5. preparing order 1 hour ago (never expires)
      final o5 = makeOrder(
        id: 'o5',
        status: OrderStatus.preparing,
        enteredAt: baseTime.subtract(const Duration(hours: 1)),
      );

      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [o1, o2, o3, o4, o5],
        clock: () => baseTime,
      );

      var emissionCount = 0;
      final sub = repo.watchOrders().listen((_) {
        emissionCount++;
      });

      // Allow initial stream emission
      await Future<void>.delayed(Duration.zero);
      final initialEmissions = emissionCount;

      final cancelledCount = await repo.expireStaleOrders();

      // Expect exactly 3 cancelled: o1, o2, o4
      expect(cancelledCount, 3);

      // Emitted exactly once more
      expect(emissionCount, initialEmissions + 1);

      final current = repo.currentOrders;
      final o1Updated = current.firstWhere((o) => o.id == 'o1');
      final o2Updated = current.firstWhere((o) => o.id == 'o2');
      final o3Updated = current.firstWhere((o) => o.id == 'o3');
      final o4Updated = current.firstWhere((o) => o.id == 'o4');
      final o5Updated = current.firstWhere((o) => o.id == 'o5');

      expect(o1Updated.status, OrderStatus.cancelled);
      expect(o1Updated.cancelReason, CancelReason.vendorNoResponse);

      expect(o2Updated.status, OrderStatus.cancelled);
      expect(o2Updated.cancelReason, CancelReason.customerNoResponse);

      expect(o3Updated.status, OrderStatus.etaAgreed);

      expect(o4Updated.status, OrderStatus.cancelled);
      expect(o4Updated.cancelReason, CancelReason.paymentTimeout);

      expect(o5Updated.status, OrderStatus.preparing);

      await sub.cancel();
    });
  });
}
