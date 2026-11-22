import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/models/feedback.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/vendor/services/vendor_suggestion_engine.dart';

void main() {
  const itemSamosa = MenuItem(
    id: 'samosa',
    name: 'Samosa (2 pcs)',
    price: 20,
    isAvailable: true,
  );
  const itemPuff = MenuItem(
    id: 'puff',
    name: 'Veg Puff',
    price: 25,
    isAvailable: true,
  );
  const itemVada = MenuItem(
    id: 'vada',
    name: 'Vada Pav',
    price: 25,
    isAvailable: true,
  );
  const itemChai = MenuItem(
    id: 'chai',
    name: 'Masala Chai',
    price: 15,
    isAvailable: true,
  );
  const itemBrownie = MenuItem(
    id: 'brownie',
    name: 'Brownie',
    price: 50,
    isAvailable: true,
  );
  const itemUnavailable = MenuItem(
    id: 'seasonal',
    name: 'Seasonal Shake',
    price: 40,
    isAvailable: false,
  );

  final testMenu = [
    itemSamosa,
    itemPuff,
    itemVada,
    itemChai,
    itemBrownie,
    itemUnavailable,
  ];

  Order createDeliveredOrder({
    required String id,
    required List<OrderItem> items,
    required DateTime placedAt,
  }) {
    final subtotal = items.fold<int>(0, (sum, i) => sum + i.lineTotal);
    return Order(
      id: id,
      clientRequestId: 'req-$id',
      customerId: 'cust-1',
      vendorId: 'canteen',
      vendorName: 'College Canteen',
      module: OrderModule.food,
      items: items,
      locationId: kDeliveryLocations.first.id,
      building: 'Block 1',
      block: 'A',
      floor: 1,
      room: '101',
      address: 'Block 1, Floor 1, Room 101',
      subtotal: subtotal,
      deliveryFee: 5,
      taxAndServiceCharge: 0,
      grandTotal: subtotal + 5,
      paymentMethod: PaymentMethod.upi,
      paymentStatus: PaymentStatus.paid,
      status: OrderStatus.delivered,
      placedAt: placedAt,
      estimatedReadyTime: placedAt.add(const Duration(minutes: 15)),
      statusHistory: [
        (OrderStatus.placed, placedAt),
        (OrderStatus.delivered, placedAt.add(const Duration(minutes: 20))),
      ],
    );
  }

  group('VendorSuggestionEngine - bestsellers ranking', () {
    test('ranks top 3 items by quantity sold in window', () {
      final orders = [
        createDeliveredOrder(
          id: 'ord-1',
          placedAt: DateTime(2026, 11, 22, 10, 0),
          items: const [
            OrderItem(itemId: 'samosa', name: 'Samosa (2 pcs)', quantity: 10, unitPrice: 20, lineTotal: 200),
            OrderItem(itemId: 'puff', name: 'Veg Puff', quantity: 6, unitPrice: 25, lineTotal: 150),
          ],
        ),
        createDeliveredOrder(
          id: 'ord-2',
          placedAt: DateTime(2026, 11, 22, 11, 0),
          items: const [
            OrderItem(itemId: 'vada', name: 'Vada Pav', quantity: 4, unitPrice: 25, lineTotal: 100),
            OrderItem(itemId: 'chai', name: 'Masala Chai', quantity: 2, unitPrice: 15, lineTotal: 30),
          ],
        ),
      ];

      final suggestions = VendorSuggestionEngine.generate(
        deliveredOrdersInWindow: orders,
        feedback: const [],
        menu: testMenu,
      );

      final bestsellers = suggestions.where((s) => s.type == SuggestionType.bestsellers).toList();
      expect(bestsellers.length, 1);
      expect(bestsellers.first.title, 'Your bestsellers');
      expect(bestsellers.first.severity, 20);
      expect(bestsellers.first.detail, contains('Samosa (2 pcs) (10)'));
      expect(bestsellers.first.detail, contains('Veg Puff (6)'));
      expect(bestsellers.first.detail, contains('Vada Pav (4)'));
      expect(bestsellers.first.detail, isNot(contains('Masala Chai')));
    });
  });

  group('VendorSuggestionEngine - low rating threshold (table-driven)', () {
    const cases = [
      (
        ratings: [2, 3],
        avg: 2.5,
        flagged: false,
        desc: 'average 2.5 with 2 ratings is NOT flagged (< 3 reviews)',
      ),
      (
        ratings: [2, 3, 2],
        avg: 2.33,
        flagged: true,
        desc: 'average 2.33 with 3 ratings IS flagged (avg < 3.0 and >= 3 reviews)',
      ),
      (
        ratings: [3, 3, 3],
        avg: 3.0,
        flagged: false,
        desc: 'average 3.0 with 3 ratings is NOT flagged (must be strictly < 3.0)',
      ),
      (
        ratings: [1, 2, 2, 3],
        avg: 2.0,
        flagged: true,
        desc: 'average 2.0 with 4 ratings IS flagged',
      ),
    ];

    for (final c in cases) {
      test(c.desc, () {
        final feedbackList = [
          for (var i = 0; i < c.ratings.length; i++)
            OrderFeedback(
              orderId: 'ord-fb-$i',
              vendorId: 'canteen',
              itemIds: const ['samosa'],
              rating: c.ratings[i],
              at: DateTime(2026, 11, 22, 10, i),
            ),
        ];

        final suggestions = VendorSuggestionEngine.generate(
          deliveredOrdersInWindow: const [],
          feedback: feedbackList,
          menu: [itemSamosa],
        );

        final lowRated = suggestions.where((s) => s.type == SuggestionType.lowRated).toList();
        if (c.flagged) {
          expect(lowRated.length, 1);
          expect(lowRated.first.itemId, 'samosa');
          expect(lowRated.first.severity, 90);
        } else {
          expect(lowRated, isEmpty);
        }
      });
    }
  });

  group('VendorSuggestionEngine - praise threshold', () {
    test('praise generated at 4.6 with 3 ratings (>= 4.5 and >= 3 ratings)', () {
      final feedbackList = [
        OrderFeedback(
          orderId: 'ord-fb-1',
          vendorId: 'canteen',
          itemIds: const ['samosa'],
          rating: 5,
          at: DateTime(2026, 11, 22, 10, 0),
        ),
        OrderFeedback(
          orderId: 'ord-fb-2',
          vendorId: 'canteen',
          itemIds: const ['samosa'],
          rating: 5,
          at: DateTime(2026, 11, 22, 10, 5),
        ),
        OrderFeedback(
          orderId: 'ord-fb-3',
          vendorId: 'canteen',
          itemIds: const ['samosa'],
          rating: 4,
          at: DateTime(2026, 11, 22, 10, 10),
        ),
      ];

      final suggestions = VendorSuggestionEngine.generate(
        deliveredOrdersInWindow: const [],
        feedback: feedbackList,
        menu: [itemSamosa],
      );

      final praised = suggestions.where((s) => s.type == SuggestionType.praised).toList();
      expect(praised.length, 1);
      expect(praised.first.itemId, 'samosa');
      expect(praised.first.severity, 30);
    });
  });

  group('VendorSuggestionEngine - slow mover threshold (table-driven)', () {
    const cases = [
      (
        orderCount: 19,
        expectSlowMover: false,
        desc: '19 orders in window: no slow mover generated',
      ),
      (
        orderCount: 20,
        expectSlowMover: true,
        desc: '20 orders in window: slow mover generated for unsold available item',
      ),
    ];

    for (final c in cases) {
      test(c.desc, () {
        final orders = List.generate(
          c.orderCount,
          (i) => createDeliveredOrder(
            id: 'ord-$i',
            placedAt: DateTime(2026, 11, 22, 10, 0),
            items: const [
              OrderItem(itemId: 'samosa', name: 'Samosa (2 pcs)', quantity: 1, unitPrice: 20, lineTotal: 20),
            ],
          ),
        );

        final suggestions = VendorSuggestionEngine.generate(
          deliveredOrdersInWindow: orders,
          feedback: const [],
          menu: [itemSamosa, itemBrownie, itemUnavailable],
        );

        final slowMovers = suggestions.where((s) => s.type == SuggestionType.slowMover).toList();
        if (c.expectSlowMover) {
          expect(slowMovers.length, 1);
          expect(slowMovers.first.itemId, 'brownie');
          expect(slowMovers.first.severity, 60);
          expect(slowMovers.first.detail, 'Consider a discount or removing it');
        } else {
          expect(slowMovers, isEmpty);
        }
      });
    }
  });

  group('VendorSuggestionEngine - peak hour', () {
    test('identifies peak hour when window has >= 10 orders', () {
      final orders = <Order>[];
      // 6 orders at 14:xx
      for (var i = 0; i < 6; i++) {
        orders.add(createDeliveredOrder(
          id: 'ord-14-$i',
          placedAt: DateTime(2026, 11, 22, 14, i * 5),
          items: const [
            OrderItem(itemId: 'samosa', name: 'Samosa (2 pcs)', quantity: 1, unitPrice: 20, lineTotal: 20),
          ],
        ));
      }
      // 4 orders at 11:xx
      for (var i = 0; i < 4; i++) {
        orders.add(createDeliveredOrder(
          id: 'ord-11-$i',
          placedAt: DateTime(2026, 11, 22, 11, i * 5),
          items: const [
            OrderItem(itemId: 'samosa', name: 'Samosa (2 pcs)', quantity: 1, unitPrice: 20, lineTotal: 20),
          ],
        ));
      }

      final suggestions = VendorSuggestionEngine.generate(
        deliveredOrdersInWindow: orders,
        feedback: const [],
        menu: [itemSamosa],
      );

      final peakHours = suggestions.where((s) => s.type == SuggestionType.peakHour).toList();
      expect(peakHours.length, 1);
      expect(peakHours.first.severity, 40);
      expect(peakHours.first.detail, 'Prepare ahead before 14:00');
    });

    test('does NOT identify peak hour when window has < 10 orders', () {
      final orders = List.generate(
        9,
        (i) => createDeliveredOrder(
          id: 'ord-$i',
          placedAt: DateTime(2026, 11, 22, 14, i),
          items: const [
            OrderItem(itemId: 'samosa', name: 'Samosa (2 pcs)', quantity: 1, unitPrice: 20, lineTotal: 20),
          ],
        ),
      );

      final suggestions = VendorSuggestionEngine.generate(
        deliveredOrdersInWindow: orders,
        feedback: const [],
        menu: [itemSamosa],
      );

      expect(suggestions.where((s) => s.type == SuggestionType.peakHour), isEmpty);
    });
  });

  group('VendorSuggestionEngine - severity ordering', () {
    test('sorts suggestions by severity descending (90 -> 60 -> 40 -> 30 -> 20)', () {
      // 20 orders at 14:xx so slowMover (60) and peakHour (40) trigger
      final orders = List.generate(
        20,
        (i) => createDeliveredOrder(
          id: 'ord-$i',
          placedAt: DateTime(2026, 11, 22, 14, i),
         items: const [
            OrderItem(itemId: 'samosa', name: 'Samosa (2 pcs)', quantity: 1, unitPrice: 20, lineTotal: 20),
            OrderItem(itemId: 'puff', name: 'Veg Puff', quantity: 1, unitPrice: 25, lineTotal: 25),
            OrderItem(itemId: 'vada', name: 'Vada Pav', quantity: 1, unitPrice: 25, lineTotal: 25),
          ],
        ),
      );

      // Feedback for lowRated (90) on puff, praised (30) on vada
      final feedbackList = [
        OrderFeedback(orderId: 'f1', vendorId: 'canteen', itemIds: const ['puff'], rating: 2, at: DateTime(2026, 11, 22)),
        OrderFeedback(orderId: 'f2', vendorId: 'canteen', itemIds: const ['puff'], rating: 2, at: DateTime(2026, 11, 22)),
        OrderFeedback(orderId: 'f3', vendorId: 'canteen', itemIds: const ['puff'], rating: 2, at: DateTime(2026, 11, 22)),
        OrderFeedback(orderId: 'f4', vendorId: 'canteen', itemIds: const ['vada'], rating: 5, at: DateTime(2026, 11, 22)),
        OrderFeedback(orderId: 'f5', vendorId: 'canteen', itemIds: const ['vada'], rating: 5, at: DateTime(2026, 11, 22)),
        OrderFeedback(orderId: 'f6', vendorId: 'canteen', itemIds: const ['vada'], rating: 4, at: DateTime(2026, 11, 22)),
      ];

      final suggestions = VendorSuggestionEngine.generate(
        deliveredOrdersInWindow: orders,
        feedback: feedbackList,
        menu: [itemSamosa, itemPuff, itemVada, itemBrownie],
      );

      final severities = suggestions.map((s) => s.severity).toList();
      expect(severities, [90, 60, 40, 30, 20]);
      expect(suggestions[0].type, SuggestionType.lowRated);
      expect(suggestions[1].type, SuggestionType.slowMover);
      expect(suggestions[2].type, SuggestionType.peakHour);
      expect(suggestions[3].type, SuggestionType.praised);
      expect(suggestions[4].type, SuggestionType.bestsellers);
    });
  });
}
