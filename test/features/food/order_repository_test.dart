import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/models/order.dart';

void main() {
  final testLocation = kDeliveryLocations.first; // fee: 5

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
    const MenuItem(
      id: 'fries',
      name: 'Fries',
      price: 25,
      vendorId: 'canteen',
      vendorName: 'College Canteen',
      prepMinMinutes: 3,
      prepMaxMinutes: 8,
      isAvailable: true,
    ),
    const MenuItem(
      id: 'item-49',
      name: 'Special Snack',
      price: 49,
      vendorId: 'canteen',
      vendorName: 'College Canteen',
      isAvailable: true,
    ),
    const MenuItem(
      id: 'unavailable-soda',
      name: 'Unavailable Soda',
      price: 60,
      vendorId: 'canteen',
      vendorName: 'College Canteen',
      isAvailable: false,
    ),
    const MenuItem(
      id: 'notebook',
      name: 'Notebook',
      price: 60,
      vendorId: 'stationery',
      vendorName: 'Stationery Store',
      isAvailable: true,
    ),
  ];

  late InMemoryMenuRepository menuRepo;
  late InMemoryOrderRepository orderRepo;

  setUp(() {
    menuRepo = InMemoryMenuRepository(initialItems: List.of(itemCatalog));
    orderRepo = InMemoryOrderRepository(
      menuRepository: menuRepo,
      clock: () => DateTime(2026, 11, 21, 14, 30),
    );
  });

  group('OrderRepository - placeOrder calculations and catalog authority', () {
    test(
        'placeOrder computes totals from catalog prices, creates placed order with unpaid status and null ready time',
        () async {
      // Catalog price for burger is 50. Total = 50 + delivery fee 5 = 55.
      const request = PlaceOrderRequest(
        clientRequestId: 'req-auth-1',
        customerId: 'cust-1',
        vendorId: 'canteen',
        lines: [('burger', 1)],
        locationId: 'aitr-b3-f2-r234',
        expectedTotal: 55,
      );

      final order = await orderRepo.placeOrder(request);

      expect(order.subtotal, 50);
      expect(order.deliveryFee, 5);
      expect(order.taxAndServiceCharge, 0);
      expect(order.grandTotal, 55);
      expect(order.items.length, 1);
      expect(order.items.first.unitPrice, 50);
      expect(order.items.first.lineTotal, 50);
      expect(order.status, OrderStatus.placed);
      expect(order.paymentStatus, PaymentStatus.unpaid);
      expect(order.paymentMethod, isNull);
      expect(order.estimatedReadyTime, isNull);
    });
  });

  group('OrderRepository - subtotal minimum threshold (table-driven)', () {
    const cases = [
      (
        itemId: 'item-49',
        qty: 1,
        expectedSubtotal: 49,
        expectedTotal: 54,
        shouldPass: false,
        desc: 'subtotal 49 fails (< 50)',
      ),
      (
        itemId: 'burger',
        qty: 1,
        expectedSubtotal: 50,
        expectedTotal: 55,
        shouldPass: true,
        desc: 'subtotal 50 passes (>= 50)',
      ),
      (
        itemId: 'fries',
        qty: 1,
        expectedSubtotal: 25,
        expectedTotal: 30,
        shouldPass: false,
        desc: 'subtotal 25 fails (< 50)',
      ),
      (
        itemId: 'fries',
        qty: 2,
        expectedSubtotal: 50,
        expectedTotal: 55,
        shouldPass: true,
        desc: 'subtotal 25 x 2 = 50 passes (>= 50)',
      ),
    ];

    for (final c in cases) {
      test(c.desc, () async {
        final req = PlaceOrderRequest(
          clientRequestId: 'req-min-${c.itemId}-${c.qty}',
          customerId: 'cust-1',
          vendorId: 'canteen',
          lines: [(c.itemId, c.qty)],
          locationId: testLocation.id,
          expectedTotal: c.expectedTotal,
        );

        if (c.shouldPass) {
          final order = await orderRepo.placeOrder(req);
          expect(order.subtotal, c.expectedSubtotal);
        } else {
          expect(
            () => orderRepo.placeOrder(req),
            throwsA(isA<OrderValidationException>()),
          );
        }
      });
    }
  });

  group('OrderRepository - invalid requests rejection (table-driven)', () {
    final rejectionCases = <({
      String description,
      Future<void> Function() action,
    })>[
      (
        description: 'rejects no/unknown location',
        action: () async {
          const req = PlaceOrderRequest(
            clientRequestId: 'req-no-loc',
            customerId: 'cust-1',
            vendorId: 'canteen',
            lines: [('burger', 1)],
            locationId: 'non-existent-location',
            expectedTotal: 55,
          );
          await orderRepo.placeOrder(req);
        },
      ),
      (
        description: 'rejects unavailable item',
        action: () async {
          const req = PlaceOrderRequest(
            clientRequestId: 'req-unavail',
            customerId: 'cust-1',
            vendorId: 'canteen',
            lines: [('unavailable-soda', 1)],
            locationId: 'aitr-b3-f2-r234',
            expectedTotal: 65,
          );
          await orderRepo.placeOrder(req);
        },
      ),
      (
        description: 'rejects deleted item',
        action: () async {
          await menuRepo.delete('burger');
          const req = PlaceOrderRequest(
            clientRequestId: 'req-deleted',
            customerId: 'cust-1',
            vendorId: 'canteen',
            lines: [('burger', 1)],
            locationId: 'aitr-b3-f2-r234',
            expectedTotal: 55,
          );
          await orderRepo.placeOrder(req);
        },
      ),
      (
        description: 'rejects items from two vendors',
        action: () async {
          const req = PlaceOrderRequest(
            clientRequestId: 'req-multi-vendor',
            customerId: 'cust-1',
            vendorId: 'canteen',
            lines: [('burger', 1), ('notebook', 1)],
            locationId: 'aitr-b3-f2-r234',
            expectedTotal: 115,
          );
          await orderRepo.placeOrder(req);
        },
      ),
      (
        description: 'rejects closed vendor',
        action: () async {
          final closedRepo = InMemoryOrderRepository(
            menuRepository: menuRepo,
            isVendorOpen: (vendorId) => false,
          );
          const req = PlaceOrderRequest(
            clientRequestId: 'req-closed',
            customerId: 'cust-1',
            vendorId: 'canteen',
            lines: [('burger', 1)],
            locationId: 'aitr-b3-f2-r234',
            expectedTotal: 55,
          );
          await closedRepo.placeOrder(req);
        },
      ),
    ];

    for (final rc in rejectionCases) {
      test(rc.description, () async {
        expect(
          rc.action,
          throwsA(isA<OrderValidationException>()),
        );
      });
    }
  });

  group('OrderRepository - stale expectedTotal detection', () {
    test('throws PriceChangedException when expectedTotal is stale', () async {
      const request = PlaceOrderRequest(
        clientRequestId: 'req-stale-1',
        customerId: 'cust-1',
        vendorId: 'canteen',
        lines: [('burger', 1)], // price: 50 + 5 delivery = 55
        locationId: 'aitr-b3-f2-r234',
        expectedTotal: 45, // stale!
      );

      try {
        await orderRepo.placeOrder(request);
        fail('Should have thrown PriceChangedException');
      } on PriceChangedException catch (e) {
        expect(e.newTotal, 55);
      }
    });
  });

  group('OrderRepository - idempotency', () {
    test('idempotent on a repeated clientRequestId (one order only)', () async {
      const request = PlaceOrderRequest(
        clientRequestId: 'req-idem-123',
        customerId: 'cust-1',
        vendorId: 'canteen',
        lines: [('burger', 1)],
        locationId: 'aitr-b3-f2-r234',
        expectedTotal: 55,
      );

      final first = await orderRepo.placeOrder(request);
      final second = await orderRepo.placeOrder(request);

      expect(first.id, second.id);
      expect(orderRepo.currentOrders.length, 1);
      expect(first.status, OrderStatus.placed);
      expect(first.paymentStatus, PaymentStatus.unpaid);
    });
  });

  group('OrderRepository - order ID format and uniqueness', () {
    test('IDs match ^ORD-\\d{6}-\\d{4}\$ and are unique across 200 placements',
        () async {
      final idRegex = RegExp(r'^ORD-\d{6}-\d{4}$');
      final ids = <String>{};

      for (var i = 0; i < 200; i++) {
        final req = PlaceOrderRequest(
          clientRequestId: 'req-unique-$i',
          customerId: 'cust-1',
          vendorId: 'canteen',
          lines: [('burger', 1)],
          locationId: 'aitr-b3-f2-r234',
          expectedTotal: 55,
        );

        final order = await orderRepo.placeOrder(req);
        expect(order.id, matches(idRegex));
        ids.add(order.id);
      }

      expect(ids.length, 200);
      expect(orderRepo.currentOrders.length, 200);
    });
  });

  group('OrderRepository - updateStatus lifecycle and actor permissions', () {
    final statusTransitionCases = <({
      OrderStatus initialStatus,
      OrderStatus nextStatus,
      UserRole actor,
      String actorId,
      bool allowed,
      String description,
    })>[
      (
        initialStatus: OrderStatus.placed,
        nextStatus: OrderStatus.etaProposed,
        actor: UserRole.vendor,
        actorId: 'canteen',
        allowed: true,
        description: 'vendor can propose ETA on placed order',
      ),
      (
        initialStatus: OrderStatus.etaAgreed,
        nextStatus: OrderStatus.accepted,
        actor: UserRole.vendor,
        actorId: 'canteen',
        allowed: true,
        description: 'vendor can accept etaAgreed order',
      ),
      (
        initialStatus: OrderStatus.preparing,
        nextStatus: OrderStatus.readyForPickup,
        actor: UserRole.vendor,
        actorId: 'canteen',
        allowed: true,
        description: 'vendor can mark preparing order ready for pickup',
      ),
      (
        initialStatus: OrderStatus.placed,
        nextStatus: OrderStatus.accepted,
        actor: UserRole.vendor,
        actorId: 'canteen',
        allowed: false,
        description: 'vendor cannot accept directly from placed',
      ),
      (
        initialStatus: OrderStatus.placed,
        nextStatus: OrderStatus.etaProposed,
        actor: UserRole.customer,
        actorId: 'cust-1',
        allowed: false,
        description: 'customer cannot propose ETA',
      ),
      (
        initialStatus: OrderStatus.placed,
        nextStatus: OrderStatus.cancelled,
        actor: UserRole.customer,
        actorId: 'cust-1',
        allowed: true,
        description: 'customer can cancel from placed',
      ),
      (
        initialStatus: OrderStatus.accepted,
        nextStatus: OrderStatus.cancelled,
        actor: UserRole.customer,
        actorId: 'cust-1',
        allowed: true,
        description: 'customer can cancel from accepted',
      ),
      (
        initialStatus: OrderStatus.preparing,
        nextStatus: OrderStatus.cancelled,
        actor: UserRole.customer,
        actorId: 'cust-1',
        allowed: false,
        description: 'customer cannot cancel from preparing',
      ),
      (
        initialStatus: OrderStatus.delivered,
        nextStatus: OrderStatus.cancelled,
        actor: UserRole.vendor,
        actorId: 'canteen',
        allowed: false,
        description: 'cannot cancel delivered order',
      ),
    ];

    for (final tc in statusTransitionCases) {
      test(tc.description, () async {
        final order = Order(
          id: 'ORD-TEST-0001',
          clientRequestId: 'req-status-test',
          customerId: 'cust-1',
          vendorId: 'canteen',
          vendorName: 'College Canteen',
          module: OrderModule.food,
          items: const [],
          locationId: 'aitr-b3-f2-r234',
          building: 'B',
          block: '3',
          floor: 2,
          room: '234',
          address: 'Block 3, Floor 2, Room 234',
          subtotal: 50,
          deliveryFee: 5,
          taxAndServiceCharge: 0,
          grandTotal: 55,
          paymentStatus: PaymentStatus.unpaid,
          status: tc.initialStatus,
          placedAt: DateTime(2026, 11, 21, 14, 30),
          statusHistory: [(tc.initialStatus, DateTime(2026, 11, 21, 14, 30))],
        );

        final testRepo = InMemoryOrderRepository(
          menuRepository: menuRepo,
          initialOrders: [order],
        );

        if (tc.allowed) {
          final updated = await testRepo.updateStatus(
            order.id,
            tc.nextStatus,
            tc.actor,
            actorId: tc.actorId,
          );
          expect(updated.status, tc.nextStatus);
        } else {
          expect(
            () => testRepo.updateStatus(
              order.id,
              tc.nextStatus,
              tc.actor,
              actorId: tc.actorId,
            ),
            throwsStateError,
          );
        }
      });
    }
  });
}
