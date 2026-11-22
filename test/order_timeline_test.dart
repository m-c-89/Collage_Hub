import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/services/order_timeline.dart';

Order createTestOrder({
  required OrderStatus status,
  PaymentMethod? paymentMethod = PaymentMethod.upi,
  List<(OrderStatus, DateTime)>? statusHistory,
}) {
  final now = DateTime(2026, 11, 22, 10, 0);
  return Order(
    id: 'ORD-261122-0001',
    clientRequestId: 'req-test-1',
    customerId: 'cust-1',
    vendorId: 'canteen',
    vendorName: 'College Canteen',
    module: OrderModule.food,
    items: const [
      OrderItem(
        itemId: 'samosa',
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
    address: 'Block 1, Floor 1, Room 101',
    subtotal: 50,
    deliveryFee: 5,
    taxAndServiceCharge: 0,
    grandTotal: 55,
    paymentMethod: paymentMethod,
    paymentStatus: PaymentStatus.paid,
    status: status,
    placedAt: now,
    estimatedReadyTime: now.add(const Duration(minutes: 15)),
    statusHistory: statusHistory ?? [(status, now)],
  );
}

void main() {
  group('order_timeline - buildTimeline', () {
    test('8 steps defined in correct order with standard and COD labels', () {
      final order = createTestOrder(status: OrderStatus.placed);
      final steps = buildTimeline(order);

      expect(steps.length, 8);
      expect(steps[0].label, 'Requested');
      expect(steps[0].status, OrderStatus.placed);
      expect(steps[1].label, 'Time confirmed');
      expect(steps[1].status, OrderStatus.etaProposed);
      expect(steps[2].label, 'You agreed');
      expect(steps[2].status, OrderStatus.etaAgreed);
      expect(steps[3].label, 'Accepted');
      expect(steps[3].status, OrderStatus.accepted);
      expect(steps[4].label, 'Paid & preparing');
      expect(steps[4].status, OrderStatus.preparing);
      expect(steps[5].label, 'Ready');
      expect(steps[5].status, OrderStatus.readyForPickup);
      expect(steps[6].label, 'Out for delivery');
      expect(steps[6].status, OrderStatus.outForDelivery);
      expect(steps[7].label, 'Delivered');
      expect(steps[7].status, OrderStatus.delivered);

      // COD preparing label
      final codOrder = createTestOrder(
        status: OrderStatus.preparing,
        paymentMethod: PaymentMethod.cod,
      );
      final codSteps = buildTimeline(codOrder);
      expect(codSteps[4].label, 'Confirmed & preparing');
    });

    test('a placed order has step 1 current, others not reached', () {
      final order = createTestOrder(status: OrderStatus.placed);
      final steps = buildTimeline(order);

      expect(steps.length, 8);
      expect(steps[0].reached, isTrue);
      expect(steps[0].isCurrent, isTrue);

      for (var i = 1; i < 8; i++) {
        expect(steps[i].reached, isFalse,
            reason: 'Step ${i + 1} (${steps[i].label}) should not be reached');
        expect(steps[i].isCurrent, isFalse,
            reason: 'Step ${i + 1} (${steps[i].label}) should not be current');
      }
    });

    test('etaProposed has steps 1–2 reached, step 2 current', () {
      final order = createTestOrder(status: OrderStatus.etaProposed);
      final steps = buildTimeline(order);

      expect(steps.length, 8);
      expect(steps[0].reached, isTrue);
      expect(steps[0].isCurrent, isFalse);

      expect(steps[1].reached, isTrue);
      expect(steps[1].isCurrent, isTrue);

      for (var i = 2; i < 8; i++) {
        expect(steps[i].reached, isFalse,
            reason: 'Step ${i + 1} (${steps[i].label}) should not be reached');
        expect(steps[i].isCurrent, isFalse,
            reason: 'Step ${i + 1} (${steps[i].label}) should not be current');
      }
    });

    test('accepted has steps 1–4 reached, step 4 current', () {
      final order = createTestOrder(status: OrderStatus.accepted);
      final steps = buildTimeline(order);

      expect(steps.length, 8);
      for (var i = 0; i < 4; i++) {
        expect(steps[i].reached, isTrue,
            reason: 'Step ${i + 1} (${steps[i].label}) should be reached');
      }
      expect(steps[0].isCurrent, isFalse);
      expect(steps[1].isCurrent, isFalse);
      expect(steps[2].isCurrent, isFalse);
      expect(steps[3].isCurrent, isTrue);

      for (var i = 4; i < 8; i++) {
        expect(steps[i].reached, isFalse,
            reason: 'Step ${i + 1} (${steps[i].label}) should not be reached');
        expect(steps[i].isCurrent, isFalse,
            reason: 'Step ${i + 1} (${steps[i].label}) should not be current');
      }
    });

    test('preparing has steps 1–5 reached, step 5 current', () {
      final order = createTestOrder(status: OrderStatus.preparing);
      final steps = buildTimeline(order);

      expect(steps.length, 8);
      for (var i = 0; i < 5; i++) {
        expect(steps[i].reached, isTrue,
            reason: 'Step ${i + 1} (${steps[i].label}) should be reached');
      }
      for (var i = 0; i < 4; i++) {
        expect(steps[i].isCurrent, isFalse);
      }
      expect(steps[4].isCurrent, isTrue);

      for (var i = 5; i < 8; i++) {
        expect(steps[i].reached, isFalse,
            reason: 'Step ${i + 1} (${steps[i].label}) should not be reached');
        expect(steps[i].isCurrent, isFalse,
            reason: 'Step ${i + 1} (${steps[i].label}) should not be current');
      }
    });

    test('delivered has all 8 reached, step 8 current', () {
      final order = createTestOrder(status: OrderStatus.delivered);
      final steps = buildTimeline(order);

      expect(steps.length, 8);
      for (var i = 0; i < 8; i++) {
        expect(steps[i].reached, isTrue,
            reason: 'Step ${i + 1} (${steps[i].label}) should be reached');
      }
      for (var i = 0; i < 7; i++) {
        expect(steps[i].isCurrent, isFalse);
      }
      expect(steps[7].isCurrent, isTrue);
    });

    test('cancelled is empty', () {
      final order = createTestOrder(status: OrderStatus.cancelled);
      final steps = buildTimeline(order);

      expect(steps, isEmpty);
    });

    test('times map correctly from statusHistory', () {
      final t1 = DateTime(2026, 11, 22, 10, 0);
      final t2 = DateTime(2026, 11, 22, 10, 2);
      final t3 = DateTime(2026, 11, 22, 10, 4);
      final t4 = DateTime(2026, 11, 22, 10, 5);
      final t5 = DateTime(2026, 11, 22, 10, 10);

      final order = createTestOrder(
        status: OrderStatus.preparing,
        statusHistory: [
          (OrderStatus.placed, t1),
          (OrderStatus.etaProposed, t2),
          (OrderStatus.etaAgreed, t3),
          (OrderStatus.accepted, t4),
          (OrderStatus.preparing, t5),
        ],
      );

      final steps = buildTimeline(order);

      expect(steps.length, 8);
      expect(steps[0].time, t1);
      expect(steps[1].time, t2);
      expect(steps[2].time, t3);
      expect(steps[3].time, t4);
      expect(steps[4].time, t5);
      expect(steps[5].time, isNull);
      expect(steps[6].time, isNull);
      expect(steps[7].time, isNull);
    });
  });
}
