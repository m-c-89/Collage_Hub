import 'package:flutter_test/flutter_test.dart';

import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/delivery/models/delivery_order.dart';
import 'package:college_canteen/features/delivery/services/campus_layout.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/models/order.dart';

DeliveryOrder createTestDeliveryOrder({
  required String locationId,
  String orderId = 'test-ord-1',
  String block = 'Block 3',
  int floor = 2,
  String room = 'Room 234',
}) {
  final now = DateTime(2026, 11, 22, 12, 0);
  return DeliveryOrder(
    orderId: orderId,
    module: OrderModule.food,
    vendorName: 'College Canteen',
    locationId: locationId,
    building: 'AITR Building',
    block: block,
    floor: floor,
    room: room,
    address: '$room, Floor $floor, $block, AITR Building',
    windowStart: now,
    windowEnd: now.add(const Duration(minutes: 15)),
    itemsSummary: '1x Samosa',
    estimatedReadyTime: now,
    status: OrderStatus.outForDelivery,
  );
}

void main() {
  group('CampusLayout', () {
    test('the 4 seeded locations produce the expected blocks, floors and sorted rooms', () {
      final layout = CampusLayout.fromLocations(kDeliveryLocations);

      // Blocks are sorted
      expect(layout.blocks, ['Block 2', 'Block 3']);

      // Block 2 floors and rooms
      expect(layout.floorsFor('Block 2'), [1]);
      final b2f1Rooms = layout.roomsFor('Block 2', 1);
      expect(b2f1Rooms.length, 1);
      expect(b2f1Rooms.first.room, 'Room 120');
      expect(b2f1Rooms.first.locationId, 'aitr-b2-f1-r120');

      // Block 3 floors and rooms
      expect(layout.floorsFor('Block 3'), [1, 2, 3]);

      final b3f1Rooms = layout.roomsFor('Block 3', 1);
      expect(b3f1Rooms.length, 1);
      expect(b3f1Rooms.first.room, 'Room 136');
      expect(b3f1Rooms.first.locationId, 'aitr-b3-f1-r136');

      final b3f2Rooms = layout.roomsFor('Block 3', 2);
      expect(b3f2Rooms.length, 1);
      expect(b3f2Rooms.first.room, 'Room 234');
      expect(b3f2Rooms.first.locationId, 'aitr-b3-f2-r234');

      final b3f3Rooms = layout.roomsFor('Block 3', 3);
      expect(b3f3Rooms.length, 1);
      expect(b3f3Rooms.first.room, 'Room 316');
      expect(b3f3Rooms.first.locationId, 'aitr-b3-f3-r316');
    });

    test('adding a fifth location adds its room and a new block with no code changes', () {
      final fifthLocationNewBlock = const DeliveryLocation(
        id: 'aitr-b4-f1-r101',
        address: 'Room 101, Floor 1, Block 4, AITR Building',
        building: 'AITR Building',
        block: 'Block 4',
        floor: 1,
        room: 'Room 101',
      );

      final locationsWithNewBlock = [
        ...kDeliveryLocations,
        fifthLocationNewBlock,
      ];

      final layout = CampusLayout.fromLocations(locationsWithNewBlock);

      expect(layout.blocks, ['Block 2', 'Block 3', 'Block 4']);
      expect(layout.floorsFor('Block 4'), [1]);

      final b4f1Rooms = layout.roomsFor('Block 4', 1);
      expect(b4f1Rooms.length, 1);
      expect(b4f1Rooms.first.room, 'Room 101');
      expect(b4f1Rooms.first.locationId, 'aitr-b4-f1-r101');
    });

    test('adding a fifth location adds its room and a new floor to existing block with no code changes', () {
      final fifthLocationNewFloor = const DeliveryLocation(
        id: 'aitr-b2-f2-r210',
        address: 'Room 210, Floor 2, Block 2, AITR Building',
        building: 'AITR Building',
        block: 'Block 2',
        floor: 2,
        room: 'Room 210',
      );

      final locationsWithNewFloor = [
        ...kDeliveryLocations,
        fifthLocationNewFloor,
      ];

      final layout = CampusLayout.fromLocations(locationsWithNewFloor);

      expect(layout.blocks, ['Block 2', 'Block 3']);
      expect(layout.floorsFor('Block 2'), [1, 2]);

      final b2f2Rooms = layout.roomsFor('Block 2', 2);
      expect(b2f2Rooms.length, 1);
      expect(b2f2Rooms.first.room, 'Room 210');
      expect(b2f2Rooms.first.locationId, 'aitr-b2-f2-r210');
    });

    test('locationIdFor returns the id for a known order and null for an unknown location', () {
      final layout = CampusLayout.fromLocations(kDeliveryLocations);

      final knownOrder = createTestDeliveryOrder(
        locationId: 'aitr-b3-f2-r234',
        orderId: 'ord-known',
      );
      expect(layout.locationIdFor(knownOrder), 'aitr-b3-f2-r234');

      final unknownOrder = createTestDeliveryOrder(
        locationId: 'unknown-loc-999',
        orderId: 'ord-unknown',
      );
      expect(layout.locationIdFor(unknownOrder), isNull);
    });

    test('rooms in the same floor are sorted', () {
      final multipleRoomsOnFloor = [
        const DeliveryLocation(
          id: 'loc-z',
          address: 'Room 250, Floor 2, Block 1',
          building: 'Main',
          block: 'Block 1',
          floor: 2,
          room: 'Room 250',
        ),
        const DeliveryLocation(
          id: 'loc-a',
          address: 'Room 201, Floor 2, Block 1',
          building: 'Main',
          block: 'Block 1',
          floor: 2,
          room: 'Room 201',
        ),
        const DeliveryLocation(
          id: 'loc-m',
          address: 'Room 220, Floor 2, Block 1',
          building: 'Main',
          block: 'Block 1',
          floor: 2,
          room: 'Room 220',
        ),
      ];

      final layout = CampusLayout.fromLocations(multipleRoomsOnFloor);
      final rooms = layout.roomsFor('Block 1', 2);

      expect(rooms.map((r) => r.room).toList(), [
        'Room 201',
        'Room 220',
        'Room 250',
      ]);
      expect(rooms.map((r) => r.locationId).toList(), [
        'loc-a',
        'loc-m',
        'loc-z',
      ]);
    });
  });
}
