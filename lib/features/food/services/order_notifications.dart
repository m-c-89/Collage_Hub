import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/notifications/app_notification.dart';
import 'package:college_canteen/features/food/models/order.dart';

List<AppNotification> diffOrderNotifications(
  List<Order> before,
  List<Order> after,
  DateTime now,
) {
  final beforeMap = {for (final o in before) o.id: o};
  final notifications = <AppNotification>[];
  final seenIds = <String>{};

  void addNotification({
    required String orderId,
    required OrderStatus status,
    required RecipientType recipientType,
    required String recipientId,
    required String title,
    required String body,
  }) {
    final id = '${orderId}_${status.name}';
    if (seenIds.add(id)) {
      notifications.add(
        AppNotification(
          id: id,
          recipientType: recipientType,
          recipientId: recipientId,
          orderId: orderId,
          title: title,
          body: body,
          createdAt: now,
        ),
      );
    }
  }

  for (final afterOrder in after) {
    final beforeOrder = beforeMap[afterOrder.id];
    if (beforeOrder == null) {
      if (afterOrder.status == OrderStatus.placed) {
        addNotification(
          orderId: afterOrder.id,
          status: afterOrder.status,
          recipientType: RecipientType.vendor,
          recipientId: afterOrder.vendorId,
          title: 'New Order',
          body: 'New order request ${afterOrder.id}. Send the preparation time',
        );
      }
      continue;
    }

    if (beforeOrder.status == afterOrder.status) {
      continue;
    }

    final from = beforeOrder.status;
    final to = afterOrder.status;

    if (from == OrderStatus.placed && to == OrderStatus.etaProposed) {
      addNotification(
        orderId: afterOrder.id,
        status: to,
        recipientType: RecipientType.customer,
        recipientId: afterOrder.customerId,
        title: 'Time Proposed',
        body:
            '${afterOrder.vendorName}: ready ~${afterOrder.proposedPrepMinutes} min after you pay. Agree or decline',
      );
    } else if (from == OrderStatus.etaProposed && to == OrderStatus.etaAgreed) {
      addNotification(
        orderId: afterOrder.id,
        status: to,
        recipientType: RecipientType.vendor,
        recipientId: afterOrder.vendorId,
        title: 'Time Agreed',
        body:
            'Customer agreed to ${afterOrder.proposedPrepMinutes} min. Accept the order',
      );
    } else if (from == OrderStatus.etaProposed &&
        to == OrderStatus.cancelled &&
        afterOrder.cancelReason == CancelReason.customerDeclinedWait) {
      addNotification(
        orderId: afterOrder.id,
        status: to,
        recipientType: RecipientType.vendor,
        recipientId: afterOrder.vendorId,
        title: 'Order Cancelled',
        body: 'Customer declined the waiting time',
      );
    } else if ((from == OrderStatus.etaAgreed ||
            from == OrderStatus.etaProposed) &&
        to == OrderStatus.accepted) {
      addNotification(
        orderId: afterOrder.id,
        status: to,
        recipientType: RecipientType.customer,
        recipientId: afterOrder.customerId,
        title: 'Order Accepted',
        body:
            'Accepted! Pay within ${AppConfig.paymentWindowMinutes} min to start preparing',
      );
    } else if (from == OrderStatus.accepted && to == OrderStatus.preparing) {
      addNotification(
        orderId: afterOrder.id,
        status: to,
        recipientType: RecipientType.vendor,
        recipientId: afterOrder.vendorId,
        title: 'Order Preparing',
        body:
            'Payment received (or Cash on Delivery confirmed). Preparing ${afterOrder.id}, ready in ${afterOrder.proposedPrepMinutes ?? 0} min',
      );
    } else if (to == OrderStatus.cancelled) {
      final isVendorOrSystem = afterOrder.cancelReason ==
              CancelReason.vendorRejected ||
          afterOrder.cancelReason == CancelReason.vendorCancelled ||
          afterOrder.cancelReason == CancelReason.vendorNoResponse;

      if (isVendorOrSystem) {
        addNotification(
          orderId: afterOrder.id,
          status: to,
          recipientType: RecipientType.customer,
          recipientId: afterOrder.customerId,
          title: 'Order Cancelled',
          body: afterOrder.cancelReason?.label ?? 'Cancelled by kitchen',
        );
      } else {
        addNotification(
          orderId: afterOrder.id,
          status: to,
          recipientType: RecipientType.vendor,
          recipientId: afterOrder.vendorId,
          title: 'Order Cancelled',
          body: afterOrder.cancelReason?.label ?? 'Order cancelled',
        );
      }
    } else if (from == OrderStatus.preparing &&
        to == OrderStatus.readyForPickup) {
      addNotification(
        orderId: afterOrder.id,
        status: to,
        recipientType: RecipientType.customer,
        recipientId: afterOrder.customerId,
        title: 'Order Ready',
        body: 'Your order is ready; a delivery partner will pick it up',
      );
    } else if (from == OrderStatus.readyForPickup &&
        to == OrderStatus.outForDelivery) {
      addNotification(
        orderId: afterOrder.id,
        status: to,
        recipientType: RecipientType.customer,
        recipientId: afterOrder.customerId,
        title: 'Out for Delivery',
        body: 'Your order is on the way',
      );
    } else if (from == OrderStatus.outForDelivery &&
        to == OrderStatus.delivered) {
      addNotification(
        orderId: afterOrder.id,
        status: to,
        recipientType: RecipientType.customer,
        recipientId: afterOrder.customerId,
        title: 'Order Delivered',
        body: 'Delivered. Please rate your order',
      );
    }
  }

  return notifications;
}
