import 'package:flutter_test/flutter_test.dart';

import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/features/delivery/services/delivery_formatters.dart';
import 'package:college_canteen/features/delivery/services/delivery_metrics.dart';
import 'package:college_canteen/features/delivery/services/delivery_validators.dart';
import 'package:college_canteen/features/delivery/services/trip_rules.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/models/order.dart';

Order createTestOrder({
  required String id,
  OrderStatus status = OrderStatus.preparing,
  String? assignedPartnerId,
  DateTime? placedAt,
  List<(OrderStatus, DateTime)>? statusHistory,
}) {
  final now = placedAt ?? DateTime(2026, 11, 22, 12, 0);
  return Order(
    id: id,
    clientRequestId: 'req-$id',
    customerId: 'cust-1',
    vendorId: 'canteen',
    vendorName: 'College Canteen',
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
    locationId: 'aitr-b3-f2-r234',
    building: 'AITR Building',
    block: 'Block 3',
    floor: 2,
    room: 'Room 234',
    address: 'Room 234, Floor 2, Block 3, AITR Building',
    subtotal: 40,
    deliveryFee: 5,
    taxAndServiceCharge: 0,
    grandTotal: 45,
    paymentStatus: PaymentStatus.paid,
    status: status,
    placedAt: now,
    statusHistory: statusHistory ?? [(status, now)],
    assignedPartnerId: assignedPartnerId,
    estimatedReadyTime: now.add(const Duration(minutes: 10)),
  );
}

void main() {
  group('OrderRepository - Partner Assignment', () {
    late InMemoryMenuRepository menuRepo;

    setUp(() {
      menuRepo = InMemoryMenuRepository(initialItems: const []);
    });

    test('assignPartners success sets partnerId and emits stream once', () async {
      final o1 = createTestOrder(id: 'ord-1', status: OrderStatus.preparing);
      final o2 = createTestOrder(id: 'ord-2', status: OrderStatus.readyForPickup);
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [o1, o2],
      );

      final streamUpdates = <List<Order>>[];
      final sub = repo.watchOrders().listen(streamUpdates.add);
      await Future<void>.delayed(Duration.zero);
      final updated = await repo.assignPartners(['ord-1', 'ord-2'], 'partner-1');

      expect(updated.length, 2);
      expect(updated[0].assignedPartnerId, 'partner-1');
      expect(updated[1].assignedPartnerId, 'partner-1');

      final current = repo.currentOrders;
      expect(current.firstWhere((o) => o.id == 'ord-1').assignedPartnerId, 'partner-1');
      expect(current.firstWhere((o) => o.id == 'ord-2').assignedPartnerId, 'partner-1');

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // Initial emission + 1 update emission
      expect(streamUpdates.length, 2);
    });

    test(
        'any already-assigned order throws "Order already taken" and NOTHING is assigned (atomic)',
        () async {
      final o1 = createTestOrder(id: 'ord-1', status: OrderStatus.preparing);
      final o2 = createTestOrder(
        id: 'ord-2',
        status: OrderStatus.preparing,
        assignedPartnerId: 'partner-other',
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [o1, o2],
      );

      expect(
        () => repo.assignPartners(['ord-1', 'ord-2'], 'partner-new'),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Order already taken',
          ),
        ),
      );

      // Verify o1 was NOT assigned
      expect(
        repo.currentOrders.firstWhere((o) => o.id == 'ord-1').assignedPartnerId,
        isNull,
      );
    });

    test('a wrong status is rejected with AppException', () async {
      final o1 = createTestOrder(id: 'ord-1', status: OrderStatus.placed);
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [o1],
      );

      expect(
        () => repo.assignPartners(['ord-1'], 'partner-1'),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'userMessage',
            'This order is not available for delivery',
          ),
        ),
      );
    });

    test('an empty list is rejected', () async {
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [],
      );

      expect(
        () => repo.assignPartners([], 'partner-1'),
        throwsA(isA<AppException>()),
      );
    });

    test('convenience assignPartner works', () async {
      final o1 = createTestOrder(id: 'ord-1', status: OrderStatus.preparing);
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [o1],
      );

      final updated = await repo.assignPartner('ord-1', 'partner-1');
      expect(updated.assignedPartnerId, 'partner-1');
    });

    test('a partner cannot update the status of an order assigned to another partner',
        () async {
      final o1 = createTestOrder(
        id: 'ord-1',
        status: OrderStatus.readyForPickup,
        assignedPartnerId: 'partner-1',
      );
      final repo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        initialOrders: [o1],
      );

      expect(
        () => repo.updateStatus(
          'ord-1',
          OrderStatus.outForDelivery,
          UserRole.deliveryPartner,
          actorId: 'partner-2',
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'userMessage',
            'This order is assigned to another partner',
          ),
        ),
      );
    });
  });

  group('Delivery Formatters', () {
    test('formatTimeWindow formats 12-hour windows with en-dash', () {
      final startSamePeriod = DateTime(2026, 11, 22, 12, 20);
      final endSamePeriod = DateTime(2026, 11, 22, 12, 25);
      expect(
        formatTimeWindow(startSamePeriod, endSamePeriod),
        '12:20 \u2013 12:25 PM',
      );

      final startDiffPeriod = DateTime(2026, 11, 22, 11, 55);
      final endDiffPeriod = DateTime(2026, 11, 22, 12, 0);
      expect(
        formatTimeWindow(startDiffPeriod, endDiffPeriod),
        '11:55 AM \u2013 12:00 PM',
      );
    });

    test('formatItemsSummary formats quantity and name', () {
      const items = [
        OrderItem(
          itemId: '1',
          name: 'Samosa',
          quantity: 2,
          unitPrice: 20,
          lineTotal: 40,
        ),
        OrderItem(
          itemId: '2',
          name: 'Notebook',
          quantity: 1,
          unitPrice: 50,
          lineTotal: 50,
        ),
      ];

      expect(formatItemsSummary(items), '2\u00D7 Samosa, 1\u00D7 Notebook');
    });
  });

  group('Delivery Validators', () {
    final phoneCases = [
      (input: '9876543210', isValid: true, desc: 'valid 10-digit mobile starting with 9'),
      (input: '8765432109', isValid: true, desc: 'valid 10-digit mobile starting with 8'),
      (input: '7654321098', isValid: true, desc: 'valid 10-digit mobile starting with 7'),
      (input: '6543210987', isValid: true, desc: 'valid 10-digit mobile starting with 6'),
      (input: '1234567890', isValid: false, desc: 'invalid phone starting with 1'),
      (input: '987654321', isValid: false, desc: 'too short (9 digits)'),
      (input: '98765432100', isValid: false, desc: 'too long (11 digits)'),
      (input: '', isValid: false, desc: 'empty string'),
      (input: null, isValid: false, desc: 'null phone'),
    ];

    for (final c in phoneCases) {
      test('validatePartnerPhone - ${c.desc}', () {
        final result = validatePartnerPhone(c.input);
        if (c.isValid) {
          expect(result, isNull);
        } else {
          expect(result, isNotNull);
        }
      });
    }

    final nameCases = [
      (input: 'Aarav', isValid: true, desc: 'normal name'),
      (input: 'Jo', isValid: true, desc: 'boundary min 2 chars'),
      (input: 'A' * 40, isValid: true, desc: 'boundary max 40 chars'),
      (input: 'A', isValid: false, desc: 'too short (1 char)'),
      (input: 'A' * 41, isValid: false, desc: 'too long (41 chars)'),
      (input: '   A   ', isValid: false, desc: '1 char after trim'),
      (input: '   Jo   ', isValid: true, desc: 'valid after trim'),
      (input: '', isValid: false, desc: 'empty string'),
      (input: null, isValid: false, desc: 'null name'),
    ];

    for (final c in nameCases) {
      test('validatePartnerName - ${c.desc}', () {
        final result = validatePartnerName(c.input);
        if (c.isValid) {
          expect(result, isNull);
        } else {
          expect(result, isNotNull);
        }
      });
    }
  });

  group('TripRules - canTakeOrders', () {
    test('at the limit (6) is allowed, over the limit is rejected', () {
      expect(canTakeOrders(activeCount: 4, adding: 2), isTrue);
      expect(canTakeOrders(activeCount: 5, adding: 1), isTrue);
      expect(canTakeOrders(activeCount: 0, adding: 6), isTrue);
      expect(canTakeOrders(activeCount: 4, adding: 3), isFalse);
      expect(canTakeOrders(activeCount: 6, adding: 1), isFalse);
    });
  });

  group('DeliveryMetrics', () {
    test("counts only this partner's orders and only today's deliveries", () {
      final today = DateTime(2026, 11, 22, 14, 0);
      final yesterday = DateTime(2026, 11, 21, 14, 0);

      final p1Prep = createTestOrder(
        id: 'p1-prep',
        status: OrderStatus.preparing,
        assignedPartnerId: 'partner-1',
      );
      final p1Ready = createTestOrder(
        id: 'p1-ready',
        status: OrderStatus.readyForPickup,
        assignedPartnerId: 'partner-1',
      );
      final p1Out = createTestOrder(
        id: 'p1-out',
        status: OrderStatus.outForDelivery,
        assignedPartnerId: 'partner-1',
      );
      final p1DeliveredToday = createTestOrder(
        id: 'p1-del-today',
        status: OrderStatus.delivered,
        assignedPartnerId: 'partner-1',
        statusHistory: [(OrderStatus.delivered, today)],
      );
      final p1DeliveredYesterday = createTestOrder(
        id: 'p1-del-yesterday',
        status: OrderStatus.delivered,
        assignedPartnerId: 'partner-1',
        statusHistory: [(OrderStatus.delivered, yesterday)],
      );

      // Other partner orders
      final p2Prep = createTestOrder(
        id: 'p2-prep',
        status: OrderStatus.preparing,
        assignedPartnerId: 'partner-2',
      );
      final p2DeliveredToday = createTestOrder(
        id: 'p2-del-today',
        status: OrderStatus.delivered,
        assignedPartnerId: 'partner-2',
        statusHistory: [(OrderStatus.delivered, today)],
      );

      // Unassigned order
      final unassignedPrep = createTestOrder(
        id: 'unassigned-prep',
        status: OrderStatus.preparing,
        assignedPartnerId: null,
      );

      final metrics = DeliveryMetrics.compute(
        orders: [
          p1Prep,
          p1Ready,
          p1Out,
          p1DeliveredToday,
          p1DeliveredYesterday,
          p2Prep,
          p2DeliveredToday,
          unassignedPrep,
        ],
        partnerId: 'partner-1',
        now: today,
      );

      expect(metrics.activeDeliveries, 3);
      expect(metrics.deliveredToday, 1);
    });
  });
}
