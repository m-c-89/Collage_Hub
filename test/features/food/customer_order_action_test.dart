import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/services/customer_order_action.dart';
import 'package:college_canteen/features/food/services/order_timeouts.dart';

Order createTestOrder({
  String id = 'ORD-261122-0001',
  String customerId = 'cust-1',
  String vendorId = 'canteen',
  String vendorName = 'College Canteen',
  OrderStatus status = OrderStatus.placed,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
  PaymentMethod? paymentMethod,
  int? proposedPrepMinutes,
  DateTime? placedAt,
  DateTime? estimatedReadyTime,
  CancelReason? cancelReason,
  List<(OrderStatus, DateTime)>? statusHistory,
}) {
  final t = placedAt ?? DateTime(2026, 11, 22, 12, 0);
  return Order(
    id: id,
    clientRequestId: 'req-$id',
    customerId: customerId,
    vendorId: vendorId,
    vendorName: vendorName,
    module: OrderModule.food,
    items: const [
      OrderItem(
        itemId: 'burger',
        name: 'Burger',
        quantity: 1,
        unitPrice: 50,
        lineTotal: 50,
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
    paymentStatus: paymentStatus,
    status: status,
    placedAt: t,
    estimatedReadyTime: estimatedReadyTime,
    statusHistory: statusHistory ?? [(status, t)],
    proposedPrepMinutes: proposedPrepMinutes,
    cancelReason: cancelReason,
  );
}

void main() {
  final now = DateTime(2026, 11, 22, 12, 1);

  group('customer_order_action - describe() per status', () {
    test('placed: waiting headline, cancel secondary, vendor-response deadline', () {
      final order = createTestOrder(status: OrderStatus.placed);
      final action = describe(order, now);

      expect(
        action.headline,
        'Waiting for College Canteen to confirm the preparation time',
      );
      expect(action.subtitle, '');
      expect(action.primary, CustomerPrimaryAction.none);
      expect(action.secondary, CustomerSecondaryAction.cancel);
      expect(action.deadline, OrderTimeouts.deadlineFor(order));
    });

    test(
        'etaProposed: headline, subtitle with travel buffer, agree primary, decline secondary, deadline',
        () {
      final order = createTestOrder(
        status: OrderStatus.etaProposed,
        proposedPrepMinutes: 15,
      );
      final action = describe(order, now);

      expect(
        action.headline,
        'College Canteen can have it ready about 15 min after you pay',
      );
      expect(
        action.subtitle,
        'At your room around ${15 + AppConfig.deliveryTravelBufferMinutes} min after payment',
      );
      expect(action.primary, CustomerPrimaryAction.agree);
      expect(action.secondary, CustomerSecondaryAction.decline);
      expect(action.deadline, OrderTimeouts.deadlineFor(order));
    });

    test('etaAgreed: waiting for vendor to accept, cancel secondary, deadline', () {
      final order = createTestOrder(
        status: OrderStatus.etaAgreed,
        proposedPrepMinutes: 15,
      );
      final action = describe(order, now);

      expect(action.headline, 'Waiting for College Canteen to accept');
      expect(action.subtitle, '');
      expect(action.primary, CustomerPrimaryAction.none);
      expect(action.secondary, CustomerSecondaryAction.cancel);
      expect(action.deadline, OrderTimeouts.deadlineFor(order));
    });

    test(
        'accepted and unpaid: pay now headline, pay primary, cancel secondary, payment deadline',
        () {
      final order = createTestOrder(
        status: OrderStatus.accepted,
        paymentStatus: PaymentStatus.unpaid,
      );
      final action = describe(order, now);

      expect(action.headline, 'Accepted! Pay now to start preparing');
      expect(action.subtitle, '');
      expect(action.primary, CustomerPrimaryAction.pay);
      expect(action.secondary, CustomerSecondaryAction.cancel);
      expect(action.deadline, OrderTimeouts.deadlineFor(order));
    });

    test('countdown deadline exists for placed, etaProposed, etaAgreed, and accepted', () {
      final t = DateTime(2026, 11, 22, 12, 0);

      final placedOrder =
          createTestOrder(status: OrderStatus.placed, placedAt: t);
      expect(describe(placedOrder, now).deadline, isNotNull);
      expect(
        describe(placedOrder, now).deadline,
        t.add(const Duration(minutes: AppConfig.vendorResponseTimeoutMinutes)),
      );

      final proposedOrder = createTestOrder(
        status: OrderStatus.etaProposed,
        placedAt: t,
        proposedPrepMinutes: 20,
      );
      expect(describe(proposedOrder, now).deadline, isNotNull);
      expect(
        describe(proposedOrder, now).deadline,
        t.add(const Duration(minutes: AppConfig.etaResponseTimeoutMinutes)),
      );

      final agreedOrder = createTestOrder(
        status: OrderStatus.etaAgreed,
        placedAt: t,
        proposedPrepMinutes: 20,
      );
      expect(describe(agreedOrder, now).deadline, isNotNull);
      expect(
        describe(agreedOrder, now).deadline,
        t.add(const Duration(minutes: AppConfig.vendorAcceptTimeoutMinutes)),
      );

      final acceptedOrder = createTestOrder(
        status: OrderStatus.accepted,
        placedAt: t,
        paymentStatus: PaymentStatus.unpaid,
      );
      expect(describe(acceptedOrder, now).deadline, isNotNull);
      expect(
        describe(acceptedOrder, now).deadline,
        t.add(const Duration(minutes: AppConfig.paymentWindowMinutes)),
      );
    });

    test('no actions for preparing, readyForPickup, outForDelivery, delivered', () {
      final readyTime = DateTime(2026, 11, 22, 12, 25);
      final preparingOrder = createTestOrder(
        status: OrderStatus.preparing,
        estimatedReadyTime: readyTime,
      );
      final prepAction = describe(preparingOrder, now);
      expect(prepAction.headline, 'Being prepared. Ready by 12:25');
      expect(prepAction.primary, CustomerPrimaryAction.none);
      expect(prepAction.secondary, CustomerSecondaryAction.none);
      expect(prepAction.deadline, isNull);

      final readyOrder = createTestOrder(status: OrderStatus.readyForPickup);
      final readyAction = describe(readyOrder, now);
      expect(readyAction.headline, isNotEmpty);
      expect(readyAction.primary, CustomerPrimaryAction.none);
      expect(readyAction.secondary, CustomerSecondaryAction.none);
      expect(readyAction.deadline, isNull);

      final outOrder = createTestOrder(status: OrderStatus.outForDelivery);
      final outAction = describe(outOrder, now);
      expect(outAction.headline, isNotEmpty);
      expect(outAction.primary, CustomerPrimaryAction.none);
      expect(outAction.secondary, CustomerSecondaryAction.none);
      expect(outAction.deadline, isNull);

      final deliveredOrder = createTestOrder(status: OrderStatus.delivered);
      final deliveredAction = describe(deliveredOrder, now);
      expect(deliveredAction.headline, isNotEmpty);
      expect(deliveredAction.primary, CustomerPrimaryAction.none);
      expect(deliveredAction.secondary, CustomerSecondaryAction.none);
      expect(deliveredAction.deadline, isNull);
    });

    test(
        'cancelled shows the reason label for each CancelReason and falls back to Cancelled',
        () {
      for (final reason in CancelReason.values) {
        final order = createTestOrder(
          status: OrderStatus.cancelled,
          cancelReason: reason,
        );
        final action = describe(order, now);

        expect(action.headline, 'Order cancelled');
        expect(action.subtitle, reason.label);
        expect(action.primary, CustomerPrimaryAction.none);
        expect(action.secondary, CustomerSecondaryAction.none);
        expect(action.deadline, isNull);
      }

      // Fallback when cancelReason is null
      final orderNullReason = createTestOrder(
        status: OrderStatus.cancelled,
        cancelReason: null,
      );
      final actionNull = describe(orderNullReason, now);
      expect(actionNull.headline, 'Order cancelled');
      expect(actionNull.subtitle, 'Cancelled');
      expect(actionNull.primary, CustomerPrimaryAction.none);
      expect(actionNull.secondary, CustomerSecondaryAction.none);
      expect(actionNull.deadline, isNull);
    });
  });
}
