import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/vendor/services/vendor_analytics.dart';

void main() {
  final now = DateTime(2026, 11, 22, 14, 0);

  Order createOrder({
    required String id,
    required String vendorId,
    required OrderStatus status,
    required DateTime placedAt,
    required int subtotal,
    int deliveryFee = 5,
    List<OrderItem>? items,
    DateTime? deliveredAt,
  }) {
    final statusHistory = <(OrderStatus, DateTime)>[(OrderStatus.placed, placedAt)];
    if (status == OrderStatus.delivered) {
      statusHistory.add((OrderStatus.delivered, deliveredAt ?? placedAt.add(const Duration(minutes: 15))));
    } else if (status == OrderStatus.cancelled) {
      statusHistory.add((OrderStatus.cancelled, placedAt.add(const Duration(minutes: 5))));
    }

    return Order(
      id: id,
      clientRequestId: 'req-$id',
      customerId: 'cust-1',
      vendorId: vendorId,
      vendorName: 'Vendor $vendorId',
      module: OrderModule.food,
      items: items ??
          [
            OrderItem(
              itemId: 'item-1',
              name: 'Generic Item',
              quantity: 1,
              unitPrice: subtotal,
              lineTotal: subtotal,
            ),
          ],
      locationId: kDeliveryLocations.first.id,
      building: 'B1',
      block: 'A',
      floor: 1,
      room: '101',
      address: 'Address 101',
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      taxAndServiceCharge: 0,
      grandTotal: subtotal + deliveryFee,
      paymentMethod: PaymentMethod.upi,
      paymentStatus: PaymentStatus.paid,
      status: status,
      placedAt: placedAt,
      estimatedReadyTime: placedAt.add(const Duration(minutes: 15)),
      statusHistory: statusHistory,
    );
  }

  group('VendorAnalytics.compute - filters and aggregations', () {
    test('excludes other vendors, other days and cancelled orders', () {
      final orders = [
        // Valid order today
        createOrder(
          id: 'o-today-1',
          vendorId: 'canteen',
          status: OrderStatus.placed,
          placedAt: DateTime(2026, 11, 22, 10, 0),
          subtotal: 100,
        ),
        // Other vendor (same day) -> excluded
        createOrder(
          id: 'o-other-vendor',
          vendorId: 'cafe',
          status: OrderStatus.placed,
          placedAt: DateTime(2026, 11, 22, 11, 0),
          subtotal: 200,
        ),
        // Yesterday's order -> excluded
        createOrder(
          id: 'o-yesterday',
          vendorId: 'canteen',
          status: OrderStatus.delivered,
          placedAt: DateTime(2026, 11, 21, 12, 0),
          subtotal: 150,
        ),
        // Cancelled today -> excluded from todaysOrders and todaysRevenue
        createOrder(
          id: 'o-cancelled',
          vendorId: 'canteen',
          status: OrderStatus.cancelled,
          placedAt: DateTime(2026, 11, 22, 9, 0),
          subtotal: 80,
        ),
      ];

      final result = VendorAnalytics.compute(
        orders: orders,
        vendorId: 'canteen',
        now: now,
        lastAnalysisAt: DateTime(2026, 11, 22, 8, 0),
        threshold: 60,
      );

      expect(result.todaysOrders, 1);
      expect(result.todaysRevenue, 100);
    });

    test('revenue = sum of subtotal (delivery fee ignored)', () {
      final orders = [
        createOrder(
          id: 'o-1',
          vendorId: 'canteen',
          status: OrderStatus.accepted,
          placedAt: DateTime(2026, 11, 22, 10, 0),
          subtotal: 120,
          deliveryFee: 25,
        ),
        createOrder(
          id: 'o-2',
          vendorId: 'canteen',
          status: OrderStatus.delivered,
          placedAt: DateTime(2026, 11, 22, 11, 0),
          subtotal: 80,
          deliveryFee: 15,
        ),
      ];

      final result = VendorAnalytics.compute(
        orders: orders,
        vendorId: 'canteen',
        now: now,
        lastAnalysisAt: DateTime(2026, 11, 22, 8, 0),
        threshold: 60,
      );

      expect(result.todaysRevenue, 200);
      expect(result.todaysOrders, 2);
    });

    test('average rounding (orders of ₹100 and ₹55 -> 78)', () {
      final orders = [
        createOrder(
          id: 'o-1',
          vendorId: 'canteen',
          status: OrderStatus.placed,
          placedAt: DateTime(2026, 11, 22, 10, 0),
          subtotal: 100,
        ),
        createOrder(
          id: 'o-2',
          vendorId: 'canteen',
          status: OrderStatus.placed,
          placedAt: DateTime(2026, 11, 22, 11, 0),
          subtotal: 55,
        ),
      ];

      final result = VendorAnalytics.compute(
        orders: orders,
        vendorId: 'canteen',
        now: now,
        lastAnalysisAt: DateTime(2026, 11, 22, 8, 0),
        threshold: 60,
      );

      // (100 + 55) / 2 = 77.5 -> round() = 78
      expect(result.todaysRevenue, 155);
      expect(result.todaysOrders, 2);
      expect(result.averageOrderValue, 78);
    });

    test('top item identifies item with highest total quantity across today\'s non-cancelled orders', () {
      final orders = [
        createOrder(
          id: 'o-1',
          vendorId: 'canteen',
          status: OrderStatus.placed,
          placedAt: DateTime(2026, 11, 22, 10, 0),
          subtotal: 70,
          items: const [
            OrderItem(itemId: 'samosa', name: 'Samosa (2 pcs)', quantity: 2, unitPrice: 20, lineTotal: 40),
            OrderItem(itemId: 'chai', name: 'Masala Chai', quantity: 2, unitPrice: 15, lineTotal: 30),
          ],
        ),
        createOrder(
          id: 'o-2',
          vendorId: 'canteen',
          status: OrderStatus.preparing,
          placedAt: DateTime(2026, 11, 22, 11, 0),
          subtotal: 75,
          items: const [
            OrderItem(itemId: 'samosa', name: 'Samosa (2 pcs)', quantity: 3, unitPrice: 20, lineTotal: 60),
            OrderItem(itemId: 'chai', name: 'Masala Chai', quantity: 1, unitPrice: 15, lineTotal: 15),
          ],
        ),
      ];

      final result = VendorAnalytics.compute(
        orders: orders,
        vendorId: 'canteen',
        now: now,
        lastAnalysisAt: DateTime(2026, 11, 22, 8, 0),
        threshold: 60,
      );

      // Samosa total quantity = 5, Chai total quantity = 3
      expect(result.topItemName, 'Samosa (2 pcs)');
      expect(result.topItemQuantity, 5);
    });

    test('completedSinceLastAnalysis respects lastAnalysisAt', () {
      final lastAnalysis = DateTime(2026, 11, 22, 12, 0);

      final orders = [
        // Delivered before lastAnalysisAt (11:30)
        createOrder(
          id: 'o-before',
          vendorId: 'canteen',
          status: OrderStatus.delivered,
          placedAt: DateTime(2026, 11, 22, 11, 0),
          deliveredAt: DateTime(2026, 11, 22, 11, 30),
          subtotal: 50,
        ),
        // Delivered after lastAnalysisAt (12:30)
        createOrder(
          id: 'o-after-1',
          vendorId: 'canteen',
          status: OrderStatus.delivered,
          placedAt: DateTime(2026, 11, 22, 12, 10),
          deliveredAt: DateTime(2026, 11, 22, 12, 30),
          subtotal: 60,
        ),
        // Delivered after lastAnalysisAt (13:15)
        createOrder(
          id: 'o-after-2',
          vendorId: 'canteen',
          status: OrderStatus.delivered,
          placedAt: DateTime(2026, 11, 22, 13, 0),
          deliveredAt: DateTime(2026, 11, 22, 13, 15),
          subtotal: 70,
        ),
        // Placed after lastAnalysisAt but not yet delivered
        createOrder(
          id: 'o-not-delivered',
          vendorId: 'canteen',
          status: OrderStatus.preparing,
          placedAt: DateTime(2026, 11, 22, 13, 30),
          subtotal: 80,
        ),
      ];

      final result = VendorAnalytics.compute(
        orders: orders,
        vendorId: 'canteen',
        now: now,
        lastAnalysisAt: lastAnalysis,
        threshold: 50,
      );

      expect(result.completedSinceLastAnalysis, 2);
      expect(result.threshold, 50);
      expect(result.progress, closeTo(2 / 50, 0.0001));
    });
  });

  group('shouldRefreshAnalysis (table-driven)', () {
    const cases = [
      (completed: 59, threshold: 60, expected: false, desc: '59 with threshold 60 -> false'),
      (completed: 60, threshold: 60, expected: true, desc: '60 with threshold 60 -> true'),
      (completed: 24, threshold: 25, expected: false, desc: '24 with threshold 25 -> false'),
      (completed: 25, threshold: 25, expected: true, desc: '25 with threshold 25 -> true'),
    ];

    for (final c in cases) {
      test(c.desc, () {
        expect(shouldRefreshAnalysis(c.completed, c.threshold), c.expected);
      });
    }
  });

  group('clampThreshold (table-driven)', () {
    const cases = [
      (input: 2, expected: 5, desc: '2 clamps to min 5'),
      (input: 900, expected: 500, desc: '900 clamps to max 500'),
      (input: 60, expected: 60, desc: '60 remains 60'),
    ];

    for (final c in cases) {
      test(c.desc, () {
        expect(clampThreshold(c.input), c.expected);
      });
    }
  });
}
