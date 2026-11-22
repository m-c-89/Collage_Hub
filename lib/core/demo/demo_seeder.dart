import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/data/feedback_repository.dart';
import 'package:college_canteen/features/food/data/menu_data.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/domain/cart_pricing.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/models/feedback.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/models/order.dart';

abstract final class DemoSeeder {
  static void seed(
    InMemoryOrderRepository repo, {
    FeedbackRepository? feedbackRepo,
    DateTime Function()? clock,
  }) {
    if (!AppConfig.kDemoMode) return;

    final now = clock != null ? clock() : DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    MenuItem findItem(String id) =>
        canteenMenuItems.firstWhere((i) => i.id == id);

    final samosa = findItem('snack-1'); // 20
    final vegPuff = findItem('snack-2'); // 25
    final vadaPav = findItem('snack-3'); // 25
    final fries = findItem('snack-4'); // 50
    final sandwich = findItem('snack-5'); // 40
    final thali = findItem('meal-1'); // 90
    final paneerRoll = findItem('meal-2'); // 60
    final noodles = findItem('meal-3'); // 70

    final loc0 = kDeliveryLocations[0];
    final loc1 = kDeliveryLocations[1];
    final loc2 = kDeliveryLocations[2];

    Order buildOrder({
      required String id,
      required OrderStatus status,
      required List<(MenuItem, int)> lines,
      required DeliveryLocation location,
      required DateTime placedAt,
      PaymentMethod? paymentMethod,
      PaymentStatus paymentStatus = PaymentStatus.unpaid,
      int? proposedPrepMinutes,
      DateTime? paidAt,
      DateTime? estimatedReadyTime,
    }) {
      final orderItems = <OrderItem>[];
      var subtotal = 0;
      var totalQuantity = 0;

      for (final line in lines) {
        final item = line.$1;
        final qty = line.$2;
        final lineTotal = item.price * qty;
        subtotal += lineTotal;
        totalQuantity += qty;
        orderItems.add(
          OrderItem(
            itemId: item.id,
            name: item.name,
            quantity: qty,
            unitPrice: item.price,
            lineTotal: lineTotal,
          ),
        );
      }

      final pricing = CartPricing.compute(
        subtotal: subtotal,
        itemCount: totalQuantity,
        location: location,
      );

      final statusHistory = <(OrderStatus, DateTime)>[
        (OrderStatus.placed, placedAt),
      ];

      if (status == OrderStatus.etaProposed ||
          status == OrderStatus.etaAgreed ||
          status == OrderStatus.accepted ||
          status == OrderStatus.preparing ||
          status == OrderStatus.readyForPickup ||
          status == OrderStatus.outForDelivery ||
          status == OrderStatus.delivered) {
        statusHistory.add((
          OrderStatus.etaProposed,
          placedAt.add(const Duration(seconds: 30)),
        ));
      }

      if (status == OrderStatus.etaAgreed ||
          status == OrderStatus.accepted ||
          status == OrderStatus.preparing ||
          status == OrderStatus.readyForPickup ||
          status == OrderStatus.outForDelivery ||
          status == OrderStatus.delivered) {
        statusHistory.add((
          OrderStatus.etaAgreed,
          placedAt.add(const Duration(minutes: 1)),
        ));
      }

      if (status == OrderStatus.accepted ||
          status == OrderStatus.preparing ||
          status == OrderStatus.readyForPickup ||
          status == OrderStatus.outForDelivery ||
          status == OrderStatus.delivered) {
        statusHistory.add((
          OrderStatus.accepted,
          placedAt.add(const Duration(minutes: 1, seconds: 30)),
        ));
      }

      if (status == OrderStatus.preparing ||
          status == OrderStatus.readyForPickup ||
          status == OrderStatus.outForDelivery ||
          status == OrderStatus.delivered) {
        statusHistory.add((
          OrderStatus.preparing,
          placedAt.add(const Duration(minutes: 3)),
        ));
      }

      if (status == OrderStatus.readyForPickup ||
          status == OrderStatus.outForDelivery ||
          status == OrderStatus.delivered) {
        statusHistory.add((
          OrderStatus.readyForPickup,
          placedAt.add(const Duration(minutes: 15)),
        ));
      }

      if (status == OrderStatus.outForDelivery ||
          status == OrderStatus.delivered) {
        statusHistory.add((
          OrderStatus.outForDelivery,
          placedAt.add(const Duration(minutes: 18)),
        ));
      }

      if (status == OrderStatus.delivered) {
        statusHistory.add((
          OrderStatus.delivered,
          placedAt.add(const Duration(minutes: 28)),
        ));
      }

      return Order(
        id: id,
        clientRequestId: 'seed-$id',
        customerId: 'demo-customer',
        vendorId: AppConfig.defaultVendorId,
        vendorName: AppConfig.defaultVendorName,
        module: OrderModule.food,
        items: orderItems,
        locationId: location.id,
        building: location.building,
        block: location.block,
        floor: location.floor,
        room: location.room,
        address: location.address,
        subtotal: pricing.subtotal,
        deliveryFee: pricing.deliveryFee,
        taxAndServiceCharge: pricing.taxAndServiceCharge,
        grandTotal: pricing.grandTotal,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        status: status,
        placedAt: placedAt,
        estimatedReadyTime: estimatedReadyTime,
        statusHistory: statusHistory,
        assignedPartnerId:
            status == OrderStatus.delivered ? 'demo-partner' : null,
        proposedPrepMinutes: proposedPrepMinutes,
        paidAt: paidAt,
      );
    }

    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final todayPrefix = 'ORD-$yy$mm$dd-';

    final yyy = (yesterday.year % 100).toString().padLeft(2, '0');
    final ymm = yesterday.month.toString().padLeft(2, '0');
    final ydd = yesterday.day.toString().padLeft(2, '0');
    final yesterdayPrefix = 'ORD-$yyy$ymm$ydd-';

    final orders = <Order>[
      // 2 placed today (within 3 min timeout)
      buildOrder(
        id: '${todayPrefix}0001',
        status: OrderStatus.placed,
        lines: [(thali, 1)], // 90
        location: loc0,
        placedAt: now.subtract(const Duration(minutes: 1)),
      ),
      buildOrder(
        id: '${todayPrefix}0002',
        status: OrderStatus.placed,
        lines: [(paneerRoll, 1), (vadaPav, 1)], // 60 + 25 = 85
        location: loc1,
        placedAt: now.subtract(const Duration(minutes: 2)),
      ),

      // 1 etaProposed today (within 5 min timeout)
      buildOrder(
        id: '${todayPrefix}0003',
        status: OrderStatus.etaProposed,
        lines: [(samosa, 2), (vegPuff, 1)], // 40 + 25 = 65
        location: loc2,
        placedAt: now.subtract(const Duration(minutes: 2)),
        proposedPrepMinutes: 15,
      ),

      // 1 etaAgreed today (within 3 min timeout)
      buildOrder(
        id: '${todayPrefix}0004',
        status: OrderStatus.etaAgreed,
        lines: [(fries, 1), (sandwich, 1)], // 50 + 40 = 90
        location: loc1,
        placedAt: now.subtract(const Duration(minutes: 2)),
        proposedPrepMinutes: 20,
      ),

      // 1 accepted (unpaid) today (within 5 min payment window)
      buildOrder(
        id: '${todayPrefix}0005',
        status: OrderStatus.accepted,
        lines: [(noodles, 1), (samosa, 1)], // 70 + 20 = 90
        location: loc0,
        placedAt: now.subtract(const Duration(minutes: 3)),
        proposedPrepMinutes: 15,
      ),

      // 2 preparing today
      buildOrder(
        id: '${todayPrefix}0006',
        status: OrderStatus.preparing,
        lines: [(noodles, 1)], // 70
        location: loc0,
        placedAt: now.subtract(const Duration(minutes: 40)),
        paymentMethod: PaymentMethod.upi,
        paymentStatus: PaymentStatus.paid,
        paidAt: now.subtract(const Duration(minutes: 37)),
        proposedPrepMinutes: 15,
        estimatedReadyTime: now.subtract(const Duration(minutes: 22)),
      ),
      buildOrder(
        id: '${todayPrefix}0007',
        status: OrderStatus.preparing,
        lines: [(fries, 1), (sandwich, 1)], // 50 + 40 = 90
        location: loc1,
        placedAt: now.subtract(const Duration(minutes: 50)),
        paymentMethod: PaymentMethod.card,
        paymentStatus: PaymentStatus.paid,
        paidAt: now.subtract(const Duration(minutes: 47)),
        proposedPrepMinutes: 15,
        estimatedReadyTime: now.subtract(const Duration(minutes: 32)),
      ),

      // 8 delivered today
      buildOrder(
        id: '${todayPrefix}0008',
        status: OrderStatus.delivered,
        lines: [(thali, 2)], // 180
        location: loc0,
        placedAt: now.subtract(const Duration(hours: 2)),
        paymentMethod: PaymentMethod.upi,
        paymentStatus: PaymentStatus.paid,
        paidAt: now.subtract(const Duration(hours: 1, minutes: 57)),
        proposedPrepMinutes: 15,
        estimatedReadyTime: now.subtract(const Duration(hours: 1, minutes: 42)),
      ),
      buildOrder(
        id: '${todayPrefix}0009',
        status: OrderStatus.delivered,
        lines: [(paneerRoll, 2)], // 120
        location: loc1,
        placedAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        paymentMethod: PaymentMethod.upi,
        paymentStatus: PaymentStatus.paid,
        paidAt: now.subtract(const Duration(hours: 2, minutes: 27)),
        proposedPrepMinutes: 15,
        estimatedReadyTime: now.subtract(const Duration(hours: 2, minutes: 12)),
      ),
      buildOrder(
        id: '${todayPrefix}0010',
        status: OrderStatus.delivered,
        lines: [(samosa, 3)], // 60
        location: loc2,
        placedAt: now.subtract(const Duration(hours: 3)),
        paymentMethod: PaymentMethod.cod,
        paymentStatus: PaymentStatus.payOnDelivery,
        proposedPrepMinutes: 15,
        estimatedReadyTime: now.subtract(const Duration(hours: 2, minutes: 42)),
      ),
      buildOrder(
        id: '${todayPrefix}0011',
        status: OrderStatus.delivered,
        lines: [(vegPuff, 2), (vadaPav, 1)], // 50 + 25 = 75
        location: loc0,
        placedAt: now.subtract(const Duration(hours: 3, minutes: 30)),
        paymentMethod: PaymentMethod.card,
        paymentStatus: PaymentStatus.paid,
        paidAt: now.subtract(const Duration(hours: 3, minutes: 27)),
        proposedPrepMinutes: 15,
        estimatedReadyTime: now.subtract(const Duration(hours: 3, minutes: 12)),
      ),
      buildOrder(
        id: '${todayPrefix}0012',
        status: OrderStatus.delivered,
        lines: [(vadaPav, 2), (samosa, 1)], // 50 + 20 = 70
        location: loc1,
        placedAt: now.subtract(const Duration(hours: 4)),
        paymentMethod: PaymentMethod.upi,
        paymentStatus: PaymentStatus.paid,
        paidAt: now.subtract(const Duration(hours: 3, minutes: 57)),
        proposedPrepMinutes: 15,
        estimatedReadyTime: now.subtract(const Duration(hours: 3, minutes: 42)),
      ),
      buildOrder(
        id: '${todayPrefix}0013',
        status: OrderStatus.delivered,
        lines: [(fries, 1), (sandwich, 1)], // 50 + 40 = 90
        location: loc2,
        placedAt: now.subtract(const Duration(hours: 4, minutes: 30)),
        paymentMethod: PaymentMethod.upi,
        paymentStatus: PaymentStatus.paid,
        paidAt: now.subtract(const Duration(hours: 4, minutes: 27)),
        proposedPrepMinutes: 15,
        estimatedReadyTime: now.subtract(const Duration(hours: 4, minutes: 12)),
      ),
      buildOrder(
        id: '${todayPrefix}0014',
        status: OrderStatus.delivered,
        lines: [(noodles, 1), (samosa, 1)], // 70 + 20 = 90
        location: loc0,
        placedAt: now.subtract(const Duration(hours: 5)),
        paymentMethod: PaymentMethod.card,
        paymentStatus: PaymentStatus.paid,
        paidAt: now.subtract(const Duration(hours: 4, minutes: 57)),
        proposedPrepMinutes: 15,
        estimatedReadyTime: now.subtract(const Duration(hours: 4, minutes: 42)),
      ),
      buildOrder(
        id: '${todayPrefix}0015',
        status: OrderStatus.delivered,
        lines: [(thali, 1), (paneerRoll, 1)], // 90 + 60 = 150
        location: loc1,
        placedAt: now.subtract(const Duration(hours: 5, minutes: 30)),
        paymentMethod: PaymentMethod.cod,
        paymentStatus: PaymentStatus.payOnDelivery,
        proposedPrepMinutes: 15,
        estimatedReadyTime: now.subtract(const Duration(hours: 5, minutes: 12)),
      ),

      // 4 delivered yesterday
      buildOrder(
        id: '${yesterdayPrefix}0001',
        status: OrderStatus.delivered,
        lines: [(thali, 1)], // 90
        location: loc0,
        placedAt: yesterday.subtract(const Duration(hours: 2)),
        paymentMethod: PaymentMethod.upi,
        paymentStatus: PaymentStatus.paid,
        paidAt: yesterday.subtract(const Duration(hours: 1, minutes: 57)),
        proposedPrepMinutes: 15,
        estimatedReadyTime:
            yesterday.subtract(const Duration(hours: 1, minutes: 42)),
      ),
      buildOrder(
        id: '${yesterdayPrefix}0002',
        status: OrderStatus.delivered,
        lines: [(paneerRoll, 1), (vegPuff, 1)], // 60 + 25 = 85
        location: loc1,
        placedAt: yesterday.subtract(const Duration(hours: 3)),
        paymentMethod: PaymentMethod.card,
        paymentStatus: PaymentStatus.paid,
        paidAt: yesterday.subtract(const Duration(hours: 2, minutes: 57)),
        proposedPrepMinutes: 15,
        estimatedReadyTime:
            yesterday.subtract(const Duration(hours: 2, minutes: 42)),
      ),
      buildOrder(
        id: '${yesterdayPrefix}0003',
        status: OrderStatus.delivered,
        lines: [(noodles, 1)], // 70
        location: loc2,
        placedAt: yesterday.subtract(const Duration(hours: 4)),
        paymentMethod: PaymentMethod.upi,
        paymentStatus: PaymentStatus.paid,
        paidAt: yesterday.subtract(const Duration(hours: 3, minutes: 57)),
        proposedPrepMinutes: 15,
        estimatedReadyTime:
            yesterday.subtract(const Duration(hours: 3, minutes: 42)),
      ),
      buildOrder(
        id: '${yesterdayPrefix}0004',
        status: OrderStatus.delivered,
        lines: [(samosa, 3)], // 60
        location: loc0,
        placedAt: yesterday.subtract(const Duration(hours: 5)),
        paymentMethod: PaymentMethod.cod,
        paymentStatus: PaymentStatus.payOnDelivery,
        proposedPrepMinutes: 15,
        estimatedReadyTime:
            yesterday.subtract(const Duration(hours: 4, minutes: 42)),
      ),
    ];

    repo.seedOrders(orders);

    final demoFeedbacks = <OrderFeedback>[
      OrderFeedback(
        orderId: '${todayPrefix}0008',
        vendorId: AppConfig.defaultVendorId,
        itemIds: const ['meal-1'],
        rating: 2,
        comment: 'Thali was cold and rotis were dry',
        at: now.subtract(const Duration(hours: 1, minutes: 30)),
      ),
      OrderFeedback(
        orderId: '${todayPrefix}0009',
        vendorId: AppConfig.defaultVendorId,
        itemIds: const ['meal-2'],
        rating: 4,
        comment: 'Paneer roll was fresh and spicy',
        at: now.subtract(const Duration(hours: 2)),
      ),
      OrderFeedback(
        orderId: '${todayPrefix}0010',
        vendorId: AppConfig.defaultVendorId,
        itemIds: const ['snack-1'],
        rating: 5,
        comment: 'Crispy samosas, great chutney!',
        at: now.subtract(const Duration(hours: 2, minutes: 30)),
      ),
      OrderFeedback(
        orderId: '${todayPrefix}0011',
        vendorId: AppConfig.defaultVendorId,
        itemIds: const ['snack-2', 'snack-3'],
        rating: 4,
        comment: 'Puff pastry was flaky',
        at: now.subtract(const Duration(hours: 3)),
      ),
      OrderFeedback(
        orderId: '${todayPrefix}0012',
        vendorId: AppConfig.defaultVendorId,
        itemIds: const ['snack-3', 'snack-1'],
        rating: 5,
        comment: 'Hot and delicious samosas',
        at: now.subtract(const Duration(hours: 3, minutes: 30)),
      ),
      OrderFeedback(
        orderId: '${todayPrefix}0013',
        vendorId: AppConfig.defaultVendorId,
        itemIds: const ['snack-4', 'snack-5'],
        rating: 3,
        comment: 'Fries were a bit soggy',
        at: now.subtract(const Duration(hours: 4)),
      ),
      OrderFeedback(
        orderId: '${todayPrefix}0014',
        vendorId: AppConfig.defaultVendorId,
        itemIds: const ['meal-3', 'snack-1'],
        rating: 5,
        comment: 'Excellent samosa and noodles',
        at: now.subtract(const Duration(hours: 4, minutes: 30)),
      ),
      OrderFeedback(
        orderId: '${todayPrefix}0015',
        vendorId: AppConfig.defaultVendorId,
        itemIds: const ['meal-1', 'meal-2'],
        rating: 2,
        comment: 'Thali was bland',
        at: now.subtract(const Duration(hours: 5)),
      ),
      OrderFeedback(
        orderId: '${yesterdayPrefix}0001',
        vendorId: AppConfig.defaultVendorId,
        itemIds: const ['meal-1'],
        rating: 2,
        comment: 'Thali lacked taste and freshness',
        at: yesterday.subtract(const Duration(hours: 1, minutes: 30)),
      ),
      OrderFeedback(
        orderId: '${yesterdayPrefix}0002',
        vendorId: AppConfig.defaultVendorId,
        itemIds: const ['meal-2', 'snack-2'],
        rating: 4,
        comment: 'Good roll and puff',
        at: yesterday.subtract(const Duration(hours: 2, minutes: 30)),
      ),
      OrderFeedback(
        orderId: '${yesterdayPrefix}0003',
        vendorId: AppConfig.defaultVendorId,
        itemIds: const ['meal-3'],
        rating: 4,
        comment: 'Tasty noodles',
        at: yesterday.subtract(const Duration(hours: 3, minutes: 30)),
      ),
      OrderFeedback(
        orderId: '${yesterdayPrefix}0004',
        vendorId: AppConfig.defaultVendorId,
        itemIds: const ['snack-1'],
        rating: 5,
        comment: 'Best samosa on campus!',
        at: yesterday.subtract(const Duration(hours: 4, minutes: 30)),
      ),
    ];

    if (feedbackRepo != null) {
      for (final fb in demoFeedbacks) {
        try {
          feedbackRepo.submit(fb);
        } catch (_) {}
      }
    }
  }
}
