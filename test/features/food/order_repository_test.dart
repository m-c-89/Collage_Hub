import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/features/food/data/feedback_repository.dart';
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
        'placeOrder computes totals from catalog prices even if the request carries different numbers',
        () async {
      // Catalog price for burger is 50. Total = 50 + delivery fee 5 = 55.
      const request = PlaceOrderRequest(
        clientRequestId: 'req-auth-1',
        customerId: 'cust-1',
        vendorId: 'canteen',
        lines: [('burger', 1)],
        locationId: 'aitr-b3-f2-r234',
        paymentMethod: PaymentMethod.card,
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
      expect(order.paymentStatus, PaymentStatus.paid);
      expect(order.estimatedReadyTime,
          DateTime(2026, 11, 21, 14, 30).add(const Duration(minutes: 15)));
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
          paymentMethod: PaymentMethod.upi,
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
            paymentMethod: PaymentMethod.upi,
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
            paymentMethod: PaymentMethod.upi,
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
            paymentMethod: PaymentMethod.upi,
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
            paymentMethod: PaymentMethod.upi,
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
            paymentMethod: PaymentMethod.upi,
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
        paymentMethod: PaymentMethod.upi,
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
        paymentMethod: PaymentMethod.cod,
        expectedTotal: 55,
      );

      final first = await orderRepo.placeOrder(request);
      final second = await orderRepo.placeOrder(request);

      expect(first.id, second.id);
      expect(orderRepo.currentOrders.length, 1);
      expect(first.paymentStatus, PaymentStatus.payOnDelivery);
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
          paymentMethod: PaymentMethod.upi,
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
      bool allowed,
      String description,
    })>[
      // Vendor happy path
      (
        initialStatus: OrderStatus.placed,
        nextStatus: OrderStatus.accepted,
        actor: UserRole.vendor,
        allowed: true,
        description: 'vendor can accept placed order',
      ),
      (
        initialStatus: OrderStatus.accepted,
        nextStatus: OrderStatus.preparing,
        actor: UserRole.vendor,
        allowed: true,
        description: 'vendor can start preparing accepted order',
      ),
      (
        initialStatus: OrderStatus.preparing,
        nextStatus: OrderStatus.readyForPickup,
        actor: UserRole.vendor,
        allowed: true,
        description: 'vendor can mark preparing order ready for pickup',
      ),
      // Customer restrictions
      (
        initialStatus: OrderStatus.placed,
        nextStatus: OrderStatus.accepted,
        actor: UserRole.customer,
        allowed: false,
        description: 'customer cannot accept order',
      ),
      (
        initialStatus: OrderStatus.outForDelivery,
        nextStatus: OrderStatus.delivered,
        actor: UserRole.customer,
        allowed: false,
        description: 'customer cannot mark delivered',
      ),
      // Customer cancellation
      (
        initialStatus: OrderStatus.placed,
        nextStatus: OrderStatus.cancelled,
        actor: UserRole.customer,
        allowed: true,
        description: 'customer can cancel from placed',
      ),
      (
        initialStatus: OrderStatus.accepted,
        nextStatus: OrderStatus.cancelled,
        actor: UserRole.customer,
        allowed: false,
        description: 'customer cannot cancel from accepted',
      ),
      (
        initialStatus: OrderStatus.preparing,
        nextStatus: OrderStatus.cancelled,
        actor: UserRole.customer,
        allowed: false,
        description: 'customer cannot cancel from preparing',
      ),
      // Delivered is terminal
      (
        initialStatus: OrderStatus.delivered,
        nextStatus: OrderStatus.cancelled,
        actor: UserRole.vendor,
        allowed: false,
        description: 'delivered is terminal (vendor cannot cancel)',
      ),
      (
        initialStatus: OrderStatus.delivered,
        nextStatus: OrderStatus.accepted,
        actor: UserRole.deliveryPartner,
        allowed: false,
        description: 'delivered is terminal (deliveryPartner cannot re-accept)',
      ),
    ];

    for (final tc in statusTransitionCases) {
      test(tc.description, () async {
        final testOrder = Order(
          id: 'ORD-261121-0001',
          clientRequestId: 'req-stat-${tc.description.hashCode}',
          customerId: 'cust-1',
          vendorId: 'canteen',
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
          locationId: testLocation.id,
          building: testLocation.building,
          block: testLocation.block,
          floor: testLocation.floor,
          room: testLocation.room,
          address: testLocation.address,
          subtotal: 50,
          deliveryFee: 5,
          taxAndServiceCharge: 0,
          grandTotal: 55,
          paymentMethod: PaymentMethod.upi,
          paymentStatus: PaymentStatus.paid,
          status: tc.initialStatus,
          placedAt: DateTime(2026, 11, 21, 14, 0),
          estimatedReadyTime: DateTime(2026, 11, 21, 14, 15),
          statusHistory: [(tc.initialStatus, DateTime(2026, 11, 21, 14, 0))],
        );

        final repo = InMemoryOrderRepository(
          menuRepository: menuRepo,
          initialOrders: [testOrder],
        );

        if (tc.allowed) {
          final updated =
              await repo.updateStatus(testOrder.id, tc.nextStatus, tc.actor);
          expect(updated.status, tc.nextStatus);
          expect(updated.statusHistory.last.$1, tc.nextStatus);
        } else {
          expect(
            () => repo.updateStatus(testOrder.id, tc.nextStatus, tc.actor),
            throwsStateError,
          );
        }
      });
    }
  });

  group('FeedbackRepository - validation and duplicate prevention (table-driven)',
      () {
    late InMemoryFeedbackRepository feedbackRepo;

    setUp(() {
      feedbackRepo = InMemoryFeedbackRepository();
    });

    const ratingCases = [
      (rating: 0, isValid: false, desc: 'rating 0 is rejected'),
      (rating: 1, isValid: true, desc: 'rating 1 is accepted'),
      (rating: 3, isValid: true, desc: 'rating 3 is accepted'),
      (rating: 5, isValid: true, desc: 'rating 5 is accepted'),
      (rating: 6, isValid: false, desc: 'rating 6 is rejected'),
    ];

    for (final rc in ratingCases) {
      test(rc.desc, () async {
        final feedback = OrderFeedback(
          orderId: 'ORD-rating-${rc.rating}',
          vendorId: 'canteen',
          itemIds: const ['burger'],
          rating: rc.rating,
          comment: 'Sample comment',
          at: DateTime(2026, 11, 21, 15, 0),
        );

        if (rc.isValid) {
          await feedbackRepo.submit(feedback);
          final saved = feedbackRepo.forOrder(feedback.orderId);
          expect(saved, isNotNull);
          expect(saved?.rating, rc.rating);
        } else {
          expect(
            () => feedbackRepo.submit(feedback),
            throwsArgumentError,
          );
        }
      });
    }

    test('FeedbackRepository rejects a second rating for the same order',
        () async {
      final feedback1 = OrderFeedback(
        orderId: 'ORD-dup-1',
        vendorId: 'canteen',
        itemIds: const ['burger'],
        rating: 4,
        at: DateTime(2026, 11, 21, 15, 0),
      );

      final feedback2 = OrderFeedback(
        orderId: 'ORD-dup-1',
        vendorId: 'canteen',
        itemIds: const ['burger'],
        rating: 5,
        at: DateTime(2026, 11, 21, 15, 5),
      );

      await feedbackRepo.submit(feedback1);

      expect(
        () => feedbackRepo.submit(feedback2),
        throwsStateError,
      );
    });
  });
}
