import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/delivery/models/delivery_order.dart';
import 'package:college_canteen/features/delivery/services/delivery_formatters.dart';
import 'package:college_canteen/features/delivery/widgets/delivery_notification_banner.dart';
import 'package:college_canteen/features/delivery/widgets/minimal_order_card.dart';
import 'package:college_canteen/features/delivery/widgets/trip_header.dart';
import 'package:college_canteen/features/food/models/order.dart';

void main() {
  final testOrder = DeliveryOrder(
    orderId: 'ord-101',
    module: OrderModule.food,
    vendorName: 'College Canteen',
    locationId: 'aitr-b3-f2-r234',
    building: 'AITR Building',
    block: 'Block 3',
    floor: 2,
    room: 'Room 234',
    address: 'Room 234, Floor 2, Block 3, AITR Building',
    windowStart: DateTime(2026, 11, 22, 12, 20),
    windowEnd: DateTime(2026, 11, 22, 12, 25),
    itemsSummary: '2× Samosa, 1× Cold Coffee',
    estimatedReadyTime: DateTime(2026, 11, 22, 12, 20),
    status: OrderStatus.outForDelivery,
  );

  group('Delivery Privacy & 3-Field Rule Tests', () {
    testWidgets(
        'MinimalOrderCard shows only 3 fields and contains no price or vendor name',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MinimalOrderCard(
              order: testOrder,
              stopNumber: 1,
            ),
          ),
        ),
      );

      // Asserts text contains address
      expect(
        find.textContaining('Room 234, Floor 2, Block 3, AITR Building'),
        findsOneWidget,
      );

      // Asserts text contains in-time window
      final expectedTimeWindow = formatTimeWindow(
        testOrder.windowStart,
        testOrder.windowEnd,
      );
      expect(find.textContaining(expectedTimeWindow), findsOneWidget);

      // Asserts text contains item summary
      expect(
        find.textContaining('2× Samosa, 1× Cold Coffee'),
        findsOneWidget,
      );

      // Asserts NO "₹"
      expect(find.textContaining('₹'), findsNothing);

      // Asserts NONE of the vendor name
      expect(find.textContaining(testOrder.vendorName), findsNothing);
    });

    testWidgets(
        'DeliveryNotificationBanner shows only 3 fields and contains no price or vendor name',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryNotificationBanner(
              order: testOrder,
            ),
          ),
        ),
      );

      // Asserts text contains address
      expect(
        find.textContaining('Room 234, Floor 2, Block 3, AITR Building'),
        findsOneWidget,
      );

      // Asserts text contains in-time window
      final expectedTimeWindow = formatTimeWindow(
        testOrder.windowStart,
        testOrder.windowEnd,
      );
      expect(find.textContaining(expectedTimeWindow), findsOneWidget);

      // Asserts text contains item summary
      expect(
        find.textContaining('2× Samosa, 1× Cold Coffee'),
        findsOneWidget,
      );

      // Asserts NO "₹"
      expect(find.textContaining('₹'), findsNothing);

      // Asserts NONE of the vendor name
      expect(find.textContaining(testOrder.vendorName), findsNothing);

      // Asserts action buttons are present
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('TripHeader shows "Collect from:" and the vendor name',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TripHeader(
              pickupVendorNames: ['College Canteen', 'Juice Center'],
              stopCount: 3,
              waitingForKitchenCount: 1,
            ),
          ),
        ),
      );

      // Asserts it shows "Collect from:" and the vendor names
      expect(find.textContaining('Collect from:'), findsOneWidget);
      expect(find.textContaining('College Canteen'), findsOneWidget);
      expect(find.textContaining('Juice Center'), findsOneWidget);
      expect(find.textContaining('3 stops'), findsOneWidget);
      expect(
        find.textContaining('Waiting for kitchen: 1 order(s) not ready yet'),
        findsOneWidget,
      );
    });
  });
}
