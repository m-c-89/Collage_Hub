import 'package:flutter_test/flutter_test.dart';

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/delivery/services/order_batching_engine.dart';
import 'package:college_canteen/features/food/models/order.dart';

Order createTestOrder({
  required String id,
  String building = 'AITR Building',
  String block = 'Block 3',
  int floor = 2,
  String room = 'Room 234',
  OrderModule module = OrderModule.food,
  String vendorName = 'College Canteen',
  OrderStatus status = OrderStatus.preparing,
  String? assignedPartnerId,
  DateTime? estimatedReadyTime,
}) {
  final now = DateTime(2026, 11, 22, 12, 0);
  return Order(
    id: id,
    clientRequestId: 'req-$id',
    customerId: 'cust-1',
    vendorId: 'vendor-1',
    vendorName: vendorName,
    module: module,
    items: const [
      OrderItem(
        itemId: 'item-1',
        name: 'Item 1',
        quantity: 1,
        unitPrice: 50,
        lineTotal: 50,
      ),
    ],
    locationId: 'loc-1',
    building: building,
    block: block,
    floor: floor,
    room: room,
    address: '$room, Floor $floor, $block, $building',
    subtotal: 50,
    deliveryFee: 5,
    taxAndServiceCharge: 0,
    grandTotal: 55,
    paymentStatus: PaymentStatus.paid,
    status: status,
    placedAt: now,
    statusHistory: [(status, now)],
    assignedPartnerId: assignedPartnerId,
    estimatedReadyTime: estimatedReadyTime,
  );
}

void main() {
  final baseTime = DateTime(2026, 11, 22, 12, 0);

  group('OrderBatchingEngine - Gap and tolerance table tests', () {
    final gapCases = [
      (
        desc: 'Food + Stationery in the same block with 2-min gap batch together',
        gapMinutes: 2,
        expectedBatches: 1,
        expectedStopsCount: 2,
      ),
      (
        desc: 'Food + Stationery in the same block with 3-min gap batch together',
        gapMinutes: 3,
        expectedBatches: 1,
        expectedStopsCount: 2,
      ),
      (
        desc: 'Food + Stationery in the same block with 4-min gap do not batch together',
        gapMinutes: 4,
        expectedBatches: 2,
        expectedStopsCount: 1,
      ),
    ];

    for (final testCase in gapCases) {
      test(testCase.desc, () {
        final foodOrder = createTestOrder(
          id: 'food-001',
          module: OrderModule.food,
          vendorName: 'College Canteen',
          estimatedReadyTime: baseTime,
        );
        final statOrder = createTestOrder(
          id: 'stat-001',
          module: OrderModule.stationery,
          vendorName: 'Campus Stationery',
          estimatedReadyTime:
              baseTime.add(Duration(minutes: testCase.gapMinutes)),
        );

        final batches = OrderBatchingEngine.build(
          [foodOrder, statOrder],
          toleranceMinutes: 3,
        );

        expect(batches.length, testCase.expectedBatches);
        if (testCase.expectedBatches == 1) {
          expect(batches.first.stops.length, testCase.expectedStopsCount);
          expect(batches.first.pickupVendorNames, [
            'Campus Stationery',
            'College Canteen',
          ]);
        }
      });
    }

    test(
        'orders at 0, 2.5 and 5 min with tolerance 3 give batch 1 = {0, 2.5} and batch 2 = {5}',
        () {
      final o0 = createTestOrder(
        id: 'ord-0',
        estimatedReadyTime: baseTime,
      );
      final o2_5 = createTestOrder(
        id: 'ord-2.5',
        estimatedReadyTime: baseTime.add(const Duration(seconds: 150)),
      );
      final o5 = createTestOrder(
        id: 'ord-5',
        estimatedReadyTime: baseTime.add(const Duration(minutes: 5)),
      );

      final batches = OrderBatchingEngine.build(
        [o0, o2_5, o5],
        toleranceMinutes: 3,
      );

      expect(batches.length, 2);
      expect(batches[0].stops.map((s) => s.orderId).toSet(), {
        'ord-0',
        'ord-2.5',
      });
      expect(batches[1].stops.map((s) => s.orderId).toSet(), {'ord-5'});
    });
  });

  group('OrderBatchingEngine - Boundary and partition rules', () {
    test('different blocks never batch', () {
      final b1 = createTestOrder(
        id: 'b1-001',
        block: 'Block 1',
        estimatedReadyTime: baseTime,
      );
      final b2 = createTestOrder(
        id: 'b2-001',
        block: 'Block 2',
        estimatedReadyTime: baseTime,
      );

      final batches = OrderBatchingEngine.build([b1, b2]);
      expect(batches.length, 2);
      expect(batches[0].block, 'Block 1');
      expect(batches[1].block, 'Block 2');
    });

    test('different buildings never batch', () {
      final buildA = createTestOrder(
        id: 'bldgA-001',
        building: 'Building A',
        block: 'Block 1',
        estimatedReadyTime: baseTime,
      );
      final buildB = createTestOrder(
        id: 'bldgB-001',
        building: 'Building B',
        block: 'Block 1',
        estimatedReadyTime: baseTime,
      );

      final batches = OrderBatchingEngine.build([buildA, buildB]);
      expect(batches.length, 2);
    });

    test('stops sorted by floor then room', () {
      final s3 = createTestOrder(
        id: 'stop-3',
        floor: 3,
        room: 'Room 305',
        estimatedReadyTime: baseTime,
      );
      final s1b = createTestOrder(
        id: 'stop-1b',
        floor: 1,
        room: 'Room 120',
        estimatedReadyTime: baseTime,
      );
      final s1a = createTestOrder(
        id: 'stop-1a',
        floor: 1,
        room: 'Room 110',
        estimatedReadyTime: baseTime,
      );

      final batches = OrderBatchingEngine.build([s3, s1b, s1a]);
      expect(batches.length, 1);
      final stops = batches.first.stops;
      expect(stops[0].orderId, 'stop-1a');
      expect(stops[1].orderId, 'stop-1b');
      expect(stops[2].orderId, 'stop-3');
    });

    test('the 5th order spills to a second batch when maxBatchSize is 4', () {
      final orders = List.generate(
        5,
        (i) => createTestOrder(
          id: 'ord-$i',
          floor: i,
          estimatedReadyTime: baseTime.add(Duration(minutes: i % 2)),
        ),
      );

      final batches = OrderBatchingEngine.build(
        orders,
        toleranceMinutes: 3,
        maxBatchSize: 4,
      );

      expect(batches.length, 2);
      expect(batches[0].stops.length, 4);
      expect(batches[1].stops.length, 1);
    });

    test('excluded orders: assigned, wrong statuses, null ready time', () {
      final validPreparing = createTestOrder(
        id: 'valid-prep',
        status: OrderStatus.preparing,
        estimatedReadyTime: baseTime,
      );
      final validReady = createTestOrder(
        id: 'valid-ready',
        status: OrderStatus.readyForPickup,
        estimatedReadyTime: baseTime,
      );
      final assignedOrder = createTestOrder(
        id: 'assigned',
        assignedPartnerId: 'partner-99',
        status: OrderStatus.preparing,
        estimatedReadyTime: baseTime,
      );
      final nullReadyTime = createTestOrder(
        id: 'null-time',
        status: OrderStatus.preparing,
        estimatedReadyTime: null,
      );

      final invalidStatusOrders = [
        OrderStatus.placed,
        OrderStatus.etaProposed,
        OrderStatus.etaAgreed,
        OrderStatus.accepted,
        OrderStatus.outForDelivery,
        OrderStatus.delivered,
        OrderStatus.cancelled,
      ].map((st) => createTestOrder(
            id: 'invalid-${st.name}',
            status: st,
            estimatedReadyTime: baseTime,
          ));

      final allOrders = [
        validPreparing,
        validReady,
        assignedOrder,
        nullReadyTime,
        ...invalidStatusOrders,
      ];

      final batches = OrderBatchingEngine.build(allOrders);
      expect(batches.length, 1);
      expect(batches.first.stops.length, 2);
      expect(
        batches.first.stops.map((s) => s.orderId).toSet(),
        {'valid-prep', 'valid-ready'},
      );
    });

    test('the batch id is identical regardless of input order', () {
      final o1 = createTestOrder(
        id: 'order-1',
        estimatedReadyTime: baseTime,
      );
      final o2 = createTestOrder(
        id: 'order-2',
        estimatedReadyTime: baseTime,
      );

      final batchA = OrderBatchingEngine.build([o1, o2]).first;
      final batchB = OrderBatchingEngine.build([o2, o1]).first;

      expect(batchA.id, batchB.id);
    });
  });

  group('OrderBatchingEngine - nearbyOrders', () {
    test('ranks by same block first, then floor distance, then ready time', () {
      final sameBlockSameFloor = createTestOrder(
        id: 'sb-sf',
        block: 'Block 3',
        floor: 2,
        estimatedReadyTime: baseTime,
      );
      final sameBlockDist1 = createTestOrder(
        id: 'sb-d1',
        block: 'Block 3',
        floor: 1,
        estimatedReadyTime: baseTime,
      );
      final sameBlockDist2 = createTestOrder(
        id: 'sb-d2',
        block: 'Block 3',
        floor: 4,
        estimatedReadyTime: baseTime,
      );
      final diffBlockSameFloor = createTestOrder(
        id: 'db-sf',
        block: 'Block 1',
        floor: 2,
        estimatedReadyTime: baseTime,
      );
      final diffBuilding = createTestOrder(
        id: 'diff-bldg',
        building: 'Building Other',
        block: 'Block 3',
        floor: 2,
        estimatedReadyTime: baseTime,
      );

      final nearby = OrderBatchingEngine.nearbyOrders(
        orders: [
          diffBlockSameFloor,
          sameBlockDist2,
          diffBuilding,
          sameBlockSameFloor,
          sameBlockDist1,
        ],
        building: 'AITR Building',
        block: 'Block 3',
        floor: 2,
        limit: 10,
      );

      expect(nearby.length, 4); // diffBuilding excluded
      expect(nearby[0].orderId, 'sb-sf'); // same block, dist 0
      expect(nearby[1].orderId, 'sb-d1'); // same block, dist 1
      expect(nearby[2].orderId, 'sb-d2'); // same block, dist 2
      expect(nearby[3].orderId, 'db-sf'); // diff block
    });
  });
}
