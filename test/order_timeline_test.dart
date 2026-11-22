import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/services/order_timeline.dart';

Order createTestOrder({
  required OrderStatus status,
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
    paymentMethod: PaymentMethod.upi,
    paymentStatus: PaymentStatus.paid,
    status: status,
    placedAt: now,
    estimatedReadyTime: now.add(const Duration(minutes: 15)),
    statusHistory: statusHistory ?? [(status, now)],
  );
}

void main() {
  group('order_timeline - buildTimeline', () {
    test('A placed order: step 1 reached and current, others not', () {
      final order = createTestOrder(status: OrderStatus.placed);
      final steps = buildTimeline(order);

      expect(steps.length, 6);

      // Step 1: Placed
      expect(steps[0].status, OrderStatus.placed);
      expect(steps[0].reached, isTrue);
      expect(steps[0].isCurrent, isTrue);

      // Steps 2-6: Others not reached and not current
      for (var i = 1; i < 6; i++) {
        expect(steps[i].reached, isFalse,
            reason: 'Step ${i + 1} (${steps[i].label}) should not be reached');
        expect(steps[i].isCurrent, isFalse,
            reason: 'Step ${i + 1} (${steps[i].label}) should not be current');
      }
    });

    test('An outForDelivery order: steps 1–5 reached, step 5 current', () {
      final order = createTestOrder(status: OrderStatus.outForDelivery);
      final steps = buildTimeline(order);

      expect(steps.length, 6);

      // Steps 1-5 reached
      for (var i = 0; i < 5; i++) {
        expect(steps[i].reached, isTrue,
            reason: 'Step ${i + 1} (${steps[i].label}) should be reached');
      }

      // Steps 1-4 not current
      for (var i = 0; i < 4; i++) {
        expect(steps[i].isCurrent, isFalse,
            reason: 'Step ${i + 1} (${steps[i].label}) should not be current');
      }

      // Step 5: outForDelivery is current
      expect(steps[4].status, OrderStatus.outForDelivery);
      expect(steps[4].isCurrent, isTrue);

      // Step 6: delivered is not reached and not current
      expect(steps[5].status, OrderStatus.delivered);
      expect(steps[5].reached, isFalse);
      expect(steps[5].isCurrent, isFalse);
    });

    test('A delivered order: all 6 reached, step 6 current', () {
      final order = createTestOrder(status: OrderStatus.delivered);
      final steps = buildTimeline(order);

      expect(steps.length, 6);

      // All 6 reached
      for (var i = 0; i < 6; i++) {
        expect(steps[i].reached, isTrue,
            reason: 'Step ${i + 1} (${steps[i].label}) should be reached');
      }

      // Steps 1-5 not current
      for (var i = 0; i < 5; i++) {
        expect(steps[i].isCurrent, isFalse,
            reason: 'Step ${i + 1} (${steps[i].label}) should not be current');
      }

      // Step 6: delivered is current
      expect(steps[5].status, OrderStatus.delivered);
      expect(steps[5].isCurrent, isTrue);
    });

    test('A cancelled order: empty list', () {
      final order = createTestOrder(status: OrderStatus.cancelled);
      final steps = buildTimeline(order);

      expect(steps, isEmpty);
    });

    test('Times map correctly from statusHistory', () {
      final t1 = DateTime(2026, 11, 22, 10, 0);
      final t2 = DateTime(2026, 11, 22, 10, 5);
      final t3 = DateTime(2026, 11, 22, 10, 15);

      final order = createTestOrder(
        status: OrderStatus.preparing,
        statusHistory: [
          (OrderStatus.placed, t1),
          (OrderStatus.accepted, t2),
          (OrderStatus.preparing, t3),
        ],
      );

      final steps = buildTimeline(order);

      expect(steps.length, 6);
      expect(steps[0].status, OrderStatus.placed);
      expect(steps[0].time, t1);

      expect(steps[1].status, OrderStatus.accepted);
      expect(steps[1].time, t2);

      expect(steps[2].status, OrderStatus.preparing);
      expect(steps[2].time, t3);

      expect(steps[3].status, OrderStatus.readyForPickup);
      expect(steps[3].time, isNull);

      expect(steps[4].status, OrderStatus.outForDelivery);
      expect(steps[4].time, isNull);

      expect(steps[5].status, OrderStatus.delivered);
      expect(steps[5].time, isNull);
    });
  });
}
