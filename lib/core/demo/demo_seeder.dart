import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/data/menu_data.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/domain/cart_pricing.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/models/order.dart';

abstract final class DemoSeeder {
  static void seed(InMemoryOrderRepository repo, {DateTime Function()? clock}) {
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
      required PaymentMethod paymentMethod,
    }) {
      final orderItems = <OrderItem>[];
      var subtotal = 0;
      var totalQuantity = 0;
      var maxPrep = 0;

      for (final line in lines) {
        final item = line.$1;
        final qty = line.$2;
        final lineTotal = item.price * qty;
        subtotal += lineTotal;
        totalQuantity += qty;
        if (item.prepMaxMinutes > maxPrep) {
          maxPrep = item.prepMaxMinutes;
        }
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

      if (status == OrderStatus.preparing || status == OrderStatus.delivered) {
        statusHistory.add((
          OrderStatus.accepted,
          placedAt.add(const Duration(minutes: 2)),
        ));
        statusHistory.add((
          OrderStatus.preparing,
          placedAt.add(const Duration(minutes: 5)),
        ));
      }

      if (status == OrderStatus.delivered) {
        statusHistory.add((
          OrderStatus.readyForPickup,
          placedAt.add(const Duration(minutes: 15)),
        ));
        statusHistory.add((
          OrderStatus.outForDelivery,
          placedAt.add(const Duration(minutes: 18)),
        ));
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
        paymentStatus: paymentMethod == PaymentMethod.cod
            ? PaymentStatus.payOnDelivery
            : PaymentStatus.paid,
        status: status,
        placedAt: placedAt,
        estimatedReadyTime: placedAt.add(Duration(minutes: maxPrep)),
        statusHistory: statusHistory,
        assignedPartnerId:
            status == OrderStatus.delivered ? 'demo-partner' : null,
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
      // 3 placed today
      buildOrder(
        id: '${todayPrefix}0001',
        status: OrderStatus.placed,
        lines: [(thali, 1)], // 90
        location: loc0,
        placedAt: now.subtract(const Duration(minutes: 10)),
        paymentMethod: PaymentMethod.upi,
      ),
      buildOrder(
        id: '${todayPrefix}0002',
        status: OrderStatus.placed,
        lines: [(paneerRoll, 1), (vadaPav, 1)], // 60 + 25 = 85
        location: loc1,
        placedAt: now.subtract(const Duration(minutes: 25)),
        paymentMethod: PaymentMethod.card,
      ),
      buildOrder(
        id: '${todayPrefix}0003',
        status: OrderStatus.placed,
        lines: [(samosa, 2), (vegPuff, 1)], // 40 + 25 = 65
        location: loc2,
        placedAt: now.subtract(const Duration(minutes: 40)),
        paymentMethod: PaymentMethod.cod,
      ),

      // 2 preparing today
      buildOrder(
        id: '${todayPrefix}0004',
        status: OrderStatus.preparing,
        lines: [(noodles, 1)], // 70
        location: loc0,
        placedAt: now.subtract(const Duration(minutes: 55)),
        paymentMethod: PaymentMethod.upi,
      ),
      buildOrder(
        id: '${todayPrefix}0005',
        status: OrderStatus.preparing,
        lines: [(fries, 1), (sandwich, 1)], // 50 + 40 = 90
        location: loc1,
        placedAt: now.subtract(const Duration(minutes: 70)),
        paymentMethod: PaymentMethod.card,
      ),

      // 8 delivered today
      buildOrder(
        id: '${todayPrefix}0006',
        status: OrderStatus.delivered,
        lines: [(thali, 2)], // 180
        location: loc0,
        placedAt: now.subtract(const Duration(hours: 2)),
        paymentMethod: PaymentMethod.upi,
      ),
      buildOrder(
        id: '${todayPrefix}0007',
        status: OrderStatus.delivered,
        lines: [(paneerRoll, 2)], // 120
        location: loc1,
        placedAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        paymentMethod: PaymentMethod.upi,
      ),
      buildOrder(
        id: '${todayPrefix}0008',
        status: OrderStatus.delivered,
        lines: [(samosa, 3)], // 60
        location: loc2,
        placedAt: now.subtract(const Duration(hours: 3)),
        paymentMethod: PaymentMethod.cod,
      ),
      buildOrder(
        id: '${todayPrefix}0009',
        status: OrderStatus.delivered,
        lines: [(vegPuff, 2), (vadaPav, 1)], // 50 + 25 = 75
        location: loc0,
        placedAt: now.subtract(const Duration(hours: 3, minutes: 30)),
        paymentMethod: PaymentMethod.card,
      ),
      buildOrder(
        id: '${todayPrefix}0010',
        status: OrderStatus.delivered,
        lines: [(vadaPav, 2), (samosa, 1)], // 50 + 20 = 70
        location: loc1,
        placedAt: now.subtract(const Duration(hours: 4)),
        paymentMethod: PaymentMethod.upi,
      ),
      buildOrder(
        id: '${todayPrefix}0011',
        status: OrderStatus.delivered,
        lines: [(fries, 1), (sandwich, 1)], // 50 + 40 = 90
        location: loc2,
        placedAt: now.subtract(const Duration(hours: 4, minutes: 30)),
        paymentMethod: PaymentMethod.upi,
      ),
      buildOrder(
        id: '${todayPrefix}0012',
        status: OrderStatus.delivered,
        lines: [(noodles, 1), (samosa, 1)], // 70 + 20 = 90
        location: loc0,
        placedAt: now.subtract(const Duration(hours: 5)),
        paymentMethod: PaymentMethod.card,
      ),
      buildOrder(
        id: '${todayPrefix}0013',
        status: OrderStatus.delivered,
        lines: [(thali, 1), (paneerRoll, 1)], // 90 + 60 = 150
        location: loc1,
        placedAt: now.subtract(const Duration(hours: 5, minutes: 30)),
        paymentMethod: PaymentMethod.cod,
      ),

      // 4 delivered yesterday
      buildOrder(
        id: '${yesterdayPrefix}0001',
        status: OrderStatus.delivered,
        lines: [(thali, 1)], // 90
        location: loc0,
        placedAt: yesterday.subtract(const Duration(hours: 2)),
        paymentMethod: PaymentMethod.upi,
      ),
      buildOrder(
        id: '${yesterdayPrefix}0002',
        status: OrderStatus.delivered,
        lines: [(paneerRoll, 1), (vegPuff, 1)], // 60 + 25 = 85
        location: loc1,
        placedAt: yesterday.subtract(const Duration(hours: 3)),
        paymentMethod: PaymentMethod.card,
      ),
      buildOrder(
        id: '${yesterdayPrefix}0003',
        status: OrderStatus.delivered,
        lines: [(noodles, 1)], // 70
        location: loc2,
        placedAt: yesterday.subtract(const Duration(hours: 4)),
        paymentMethod: PaymentMethod.upi,
      ),
      buildOrder(
        id: '${yesterdayPrefix}0004',
        status: OrderStatus.delivered,
        lines: [(samosa, 3)], // 60
        location: loc0,
        placedAt: yesterday.subtract(const Duration(hours: 5)),
        paymentMethod: PaymentMethod.cod,
      ),
    ];

    repo.seedOrders(orders);
  }
}
