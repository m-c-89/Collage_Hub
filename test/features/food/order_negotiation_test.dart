import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/models/order.dart';

void main() {
  final itemCatalog = [
    const MenuItem(
      id: 'burger',
      name: 'Burger',
      price: 50,
      vendorId: 'canteen',
      vendorName: 'College Canteen',
      prepMinMinutes: 5,
      prepMaxMinutes: 15,
      isAvailable: true,
    ),
  ];

  late InMemoryMenuRepository menuRepo;

  setUp(() {
    menuRepo = InMemoryMenuRepository(initialItems: List.of(itemCatalog));
  });

  Order createTestOrder({
    String id = 'ORD-261122-0001',
    String customerId = 'cust-1',
    String vendorId = 'canteen',
    OrderStatus status = OrderStatus.placed,
    PaymentStatus paymentStatus = PaymentStatus.unpaid,
    PaymentMethod? paymentMethod,
    int? proposedPrepMinutes,
    DateTime? placedAt,
    DateTime? paidAt,
    List<(OrderStatus, DateTime)>? statusHistory,
  }) {
    final t = placedAt ?? DateTime(2026, 11, 22, 12, 0);
    return Order(
      id: id,
      clientRequestId: 'req-$id',
      customerId: customerId,
      vendorId: vendorId,
      vendorName: 'College Canteen',
      module: OrderModule.food,
      items: const [
        OrderItem(
          itemId: 'burger',
          name: 'Burger',
          quantity: 1,
          unitPrice: 50,
          lineTotal: 50,
        ),
      ],
      locationId: 'aitr-b3-f2-r234',
      building: 'Block 3',
      block: 'B',
      floor: 2,
      room: '234',
      address: 'Block 3, Floor 2, Room 234',
      subtotal: 50,
      deliveryFee: 5,
      taxAndServiceCharge: 0,
      grandTotal: 55,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      status: status,
      placedAt: t,
      statusHistory: statusHistory ?? [(status, t)],
      proposedPrepMinutes: proposedPrepMinutes,
      paidAt: paidAt,
    );
  }

  group('Order negotiation - proposeEta', () {
    test('vendor OK and sets etaProposed and proposedPrepMinutes', () async {
      final order = createTestOrder();
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
        clock: () => DateTime(2026, 11, 22, 12, 1),
      );

      final updated = await repo.proposeEta(order.id, 'canteen', 20);

      expect(updated.status, OrderStatus.etaProposed);
      expect(updated.proposedPrepMinutes, 20);
      expect(updated.statusHistory.last.$1, OrderStatus.etaProposed);
    });

    test('another vendor rejected', () async {
      final order = createTestOrder(vendorId: 'canteen');
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
      );

      expect(
        () => repo.proposeEta(order.id, 'other-vendor', 20),
        throwsStateError,
      );
    });

    test('4 and 121 rejected (out of min..max 5..120)', () async {
      final order = createTestOrder();
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
      );

      expect(
        () => repo.proposeEta(order.id, 'canteen', 4),
        throwsArgumentError,
      );
      expect(
        () => repo.proposeEta(order.id, 'canteen', 121),
        throwsArgumentError,
      );
    });

    test('5 and 120 OK (exact min and max boundary values)', () async {
      final order1 = createTestOrder(id: 'ORD-1');
      final order2 = createTestOrder(id: 'ORD-2');
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order1, order2],
      );

      final updated1 = await repo.proposeEta('ORD-1', 'canteen', 5);
      expect(updated1.proposedPrepMinutes, 5);

      final updated2 = await repo.proposeEta('ORD-2', 'canteen', 120);
      expect(updated2.proposedPrepMinutes, 120);
    });

    test('only from placed (wrong status rejected)', () async {
      final order = createTestOrder(status: OrderStatus.accepted);
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
      );

      expect(
        () => repo.proposeEta(order.id, 'canteen', 20),
        throwsStateError,
      );
    });
  });

  group('Order negotiation - respondToEta', () {
    test('agree -> etaAgreed', () async {
      final order = createTestOrder(
        status: OrderStatus.etaProposed,
        proposedPrepMinutes: 15,
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
      );

      final updated = await repo.respondToEta(
        order.id,
        'cust-1',
        agree: true,
      );

      expect(updated.status, OrderStatus.etaAgreed);
      expect(updated.statusHistory.last.$1, OrderStatus.etaAgreed);
    });

    test('decline -> cancelled with CancelReason.customerDeclinedWait',
        () async {
      final order = createTestOrder(
        status: OrderStatus.etaProposed,
        proposedPrepMinutes: 15,
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
      );

      final updated = await repo.respondToEta(
        order.id,
        'cust-1',
        agree: false,
      );

      expect(updated.status, OrderStatus.cancelled);
      expect(updated.cancelReason, CancelReason.customerDeclinedWait);
    });

    test('another customer rejected', () async {
      final order = createTestOrder(
        customerId: 'cust-1',
        status: OrderStatus.etaProposed,
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
      );

      expect(
        () => repo.respondToEta(order.id, 'other-cust', agree: true),
        throwsStateError,
      );
    });

    test('wrong status rejected', () async {
      final order = createTestOrder(status: OrderStatus.placed);
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
      );

      expect(
        () => repo.respondToEta(order.id, 'cust-1', agree: true),
        throwsStateError,
      );
    });

    test('with auto-accept flag injected, agree -> accepted', () async {
      final order = createTestOrder(
        status: OrderStatus.etaProposed,
        proposedPrepMinutes: 15,
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
        autoAcceptAfterCustomerAgrees: true,
      );

      final updated = await repo.respondToEta(
        order.id,
        'cust-1',
        agree: true,
      );

      expect(updated.status, OrderStatus.accepted);
      expect(updated.statusHistory.last.$1, OrderStatus.accepted);
    });
  });

  group('Order negotiation - vendor accepted transition', () {
    test('vendor accepted only from etaAgreed', () async {
      final order = createTestOrder(
        status: OrderStatus.etaAgreed,
        proposedPrepMinutes: 15,
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
      );

      final updated = await repo.updateStatus(
        order.id,
        OrderStatus.accepted,
        UserRole.vendor,
        actorId: 'canteen',
      );
      expect(updated.status, OrderStatus.accepted);
    });

    test('vendor accepted from placed or etaProposed -> StateError', () async {
      final placedOrder = createTestOrder(id: 'o-placed', status: OrderStatus.placed);
      final proposedOrder =
          createTestOrder(id: 'o-prop', status: OrderStatus.etaProposed);
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [placedOrder, proposedOrder],
      );

      expect(
        () => repo.updateStatus(
          placedOrder.id,
          OrderStatus.accepted,
          UserRole.vendor,
          actorId: 'canteen',
        ),
        throwsStateError,
      );
      expect(
        () => repo.updateStatus(
          proposedOrder.id,
          OrderStatus.accepted,
          UserRole.vendor,
          actorId: 'canteen',
        ),
        throwsStateError,
      );
    });
  });

  group('Order negotiation - payForOrder', () {
    test(
        'upi -> paid, preparing, estimatedReadyTime = paidAt + prep',
        () async {
      final payTime = DateTime(2026, 11, 22, 12, 10);
      final order = createTestOrder(
        status: OrderStatus.accepted,
        proposedPrepMinutes: 20,
        placedAt: DateTime(2026, 11, 22, 12, 8),
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
        clock: () => payTime,
      );

      final updated = await repo.payForOrder(
        order.id,
        'cust-1',
        PaymentMethod.upi,
        paymentReference: 'TXN-123',
      );

      expect(updated.status, OrderStatus.preparing);
      expect(updated.paymentStatus, PaymentStatus.paid);
      expect(updated.paymentMethod, PaymentMethod.upi);
      expect(updated.paidAt, payTime);
      expect(updated.estimatedReadyTime, payTime.add(const Duration(minutes: 20)));
    });

    test('cod -> payOnDelivery, preparing', () async {
      final payTime = DateTime(2026, 11, 22, 12, 10);
      final order = createTestOrder(
        status: OrderStatus.accepted,
        proposedPrepMinutes: 15,
        placedAt: DateTime(2026, 11, 22, 12, 8),
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
        clock: () => payTime,
      );

      final updated = await repo.payForOrder(
        order.id,
        'cust-1',
        PaymentMethod.cod,
      );

      expect(updated.status, OrderStatus.preparing);
      expect(updated.paymentStatus, PaymentStatus.payOnDelivery);
      expect(updated.paymentMethod, PaymentMethod.cod);
      expect(updated.paidAt, isNull);
      expect(updated.estimatedReadyTime, payTime.add(const Duration(minutes: 15)));
    });

    test('repeat call is idempotent (returns unchanged)', () async {
      final order = createTestOrder(
        status: OrderStatus.accepted,
        proposedPrepMinutes: 15,
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
        clock: () => DateTime(2026, 11, 22, 12, 2),
      );

      final first = await repo.payForOrder(
        order.id,
        'cust-1',
        PaymentMethod.upi,
      );
      final second = await repo.payForOrder(
        order.id,
        'cust-1',
        PaymentMethod.upi,
      );

      expect(first.status, OrderStatus.preparing);
      expect(second.status, OrderStatus.preparing);
      expect(second.paymentStatus, PaymentStatus.paid);
    });

    test('from etaAgreed rejected', () async {
      final order = createTestOrder(
        status: OrderStatus.etaAgreed,
        proposedPrepMinutes: 15,
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
      );

      expect(
        () => repo.payForOrder(order.id, 'cust-1', PaymentMethod.upi),
        throwsStateError,
      );
    });

    test('expired window -> cancelled with paymentTimeout and friendly error',
        () async {
      final acceptedTime = DateTime(2026, 11, 22, 12, 0);
      final order = createTestOrder(
        status: OrderStatus.accepted,
        proposedPrepMinutes: 15,
        statusHistory: [(OrderStatus.accepted, acceptedTime)],
      );
      // Payment window is 5 minutes. At 12:05:00 it is expired.
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
        clock: () => acceptedTime.add(const Duration(minutes: 5)),
      );

      expect(
        () => repo.payForOrder(order.id, 'cust-1', PaymentMethod.upi),
        throwsA(isA<OrderValidationException>()),
      );

      final cancelledOrder = repo.currentOrders.firstWhere((o) => o.id == order.id);
      expect(cancelledOrder.status, OrderStatus.cancelled);
      expect(cancelledOrder.cancelReason, CancelReason.paymentTimeout);
    });
  });

  group('Order negotiation - cancel rights & refunds', () {
    test(
        'customer cancels in placed/etaProposed/etaAgreed/accepted but not preparing',
        () async {
      for (final st in [
        OrderStatus.placed,
        OrderStatus.etaProposed,
        OrderStatus.etaAgreed,
        OrderStatus.accepted,
      ]) {
        final order = createTestOrder(status: st);
        final repo = InMemoryOrderRepository(
          menuRepository: menuRepo,
          initialOrders: [order],
        );
        final cancelled = await repo.updateStatus(
          order.id,
          OrderStatus.cancelled,
          UserRole.customer,
          actorId: 'cust-1',
        );
        expect(cancelled.status, OrderStatus.cancelled);
        expect(cancelled.cancelReason, CancelReason.customerCancelled);
      }

      // Customer cannot cancel preparing
      final preparingOrder = createTestOrder(status: OrderStatus.preparing);
      final repoPrep = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [preparingOrder],
      );
      expect(
        () => repoPrep.updateStatus(
          preparingOrder.id,
          OrderStatus.cancelled,
          UserRole.customer,
          actorId: 'cust-1',
        ),
        throwsStateError,
      );
    });

    test('vendor cancels preparing -> paid order becomes refundPending',
        () async {
      final order = createTestOrder(
        status: OrderStatus.preparing,
        paymentStatus: PaymentStatus.paid,
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
      );

      final cancelled = await repo.updateStatus(
        order.id,
        OrderStatus.cancelled,
        UserRole.vendor,
        actorId: 'canteen',
      );

      expect(cancelled.status, OrderStatus.cancelled);
      expect(cancelled.paymentStatus, PaymentStatus.refundPending);
      expect(cancelled.cancelReason, CancelReason.vendorCancelled);
    });

    test('vendor cancels preparing -> COD order stays payOnDelivery',
        () async {
      final order = createTestOrder(
        status: OrderStatus.preparing,
        paymentStatus: PaymentStatus.payOnDelivery,
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
      );

      final cancelled = await repo.updateStatus(
        order.id,
        OrderStatus.cancelled,
        UserRole.vendor,
        actorId: 'canteen',
      );

      expect(cancelled.status, OrderStatus.cancelled);
      expect(cancelled.paymentStatus, PaymentStatus.payOnDelivery);
    });

    test('ownership: another vendor or customer id is rejected', () async {
      final order = createTestOrder(
        customerId: 'cust-1',
        vendorId: 'canteen',
        status: OrderStatus.placed,
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [order],
      );

      // Wrong customer
      expect(
        () => repo.updateStatus(
          order.id,
          OrderStatus.cancelled,
          UserRole.customer,
          actorId: 'wrong-customer',
        ),
        throwsStateError,
      );

      // Wrong vendor
      expect(
        () => repo.updateStatus(
          order.id,
          OrderStatus.cancelled,
          UserRole.vendor,
          actorId: 'wrong-vendor',
        ),
        throwsStateError,
      );
    });
  });
}
