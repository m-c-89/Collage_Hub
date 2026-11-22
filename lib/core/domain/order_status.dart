import 'user_role.dart';

enum CancelReason {
  customerCancelled,
  customerDeclinedWait,
  customerNoResponse,
  vendorRejected,
  vendorCancelled,
  vendorNoResponse,
  paymentTimeout;

  String get label => switch (this) {
        CancelReason.customerCancelled => 'Order cancelled',
        CancelReason.customerDeclinedWait => 'You declined the waiting time',
        CancelReason.customerNoResponse => 'Customer did not respond in time',
        CancelReason.vendorRejected => 'Declined by kitchen',
        CancelReason.vendorCancelled => 'Cancelled by kitchen',
        CancelReason.vendorNoResponse => 'The kitchen did not respond in time',
        CancelReason.paymentTimeout => 'Payment window expired',
      };
}

enum OrderStatus {
  placed,
  etaProposed,
  etaAgreed,
  accepted,
  preparing,
  readyForPickup,
  outForDelivery,
  delivered,
  cancelled;

  String get label => switch (this) {
        OrderStatus.placed => 'Request sent',
        OrderStatus.etaProposed => 'Time Proposed',
        OrderStatus.etaAgreed => 'Time Agreed',
        OrderStatus.accepted => 'Accepted',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.readyForPickup => 'Ready for Pickup',
        OrderStatus.outForDelivery => 'Out for Delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;

  static bool isTransitionAllowed(
    OrderStatus from,
    OrderStatus to,
    UserRole actor,
  ) {
    return switch ((from, to, actor)) {
      (OrderStatus.placed, OrderStatus.etaProposed, UserRole.vendor) => true,
      (OrderStatus.placed, OrderStatus.cancelled, UserRole.customer) => true,
      (OrderStatus.placed, OrderStatus.cancelled, UserRole.vendor) => true,
      (OrderStatus.etaProposed, OrderStatus.etaAgreed, UserRole.customer) => true,
      (OrderStatus.etaProposed, OrderStatus.cancelled, UserRole.customer) => true,
      (OrderStatus.etaProposed, OrderStatus.cancelled, UserRole.vendor) => true,
      (OrderStatus.etaAgreed, OrderStatus.accepted, UserRole.vendor) => true,
      (OrderStatus.etaAgreed, OrderStatus.cancelled, UserRole.customer) => true,
      (OrderStatus.etaAgreed, OrderStatus.cancelled, UserRole.vendor) => true,
      (OrderStatus.accepted, OrderStatus.cancelled, UserRole.customer) => true,
      (OrderStatus.accepted, OrderStatus.cancelled, UserRole.vendor) => true,
      (OrderStatus.preparing, OrderStatus.readyForPickup, UserRole.vendor) => true,
      (OrderStatus.preparing, OrderStatus.cancelled, UserRole.vendor) => true,
      (OrderStatus.readyForPickup, OrderStatus.outForDelivery, UserRole.deliveryPartner) => true,
      (OrderStatus.outForDelivery, OrderStatus.delivered, UserRole.deliveryPartner) => true,
      _ => false,
    };
  }

  static bool isSystemTransitionAllowed(OrderStatus from, OrderStatus to) {
    return switch ((from, to)) {
      (OrderStatus.accepted, OrderStatus.preparing) => true,
      (OrderStatus.placed, OrderStatus.cancelled) => true,
      (OrderStatus.etaProposed, OrderStatus.cancelled) => true,
      (OrderStatus.etaAgreed, OrderStatus.cancelled) => true,
      (OrderStatus.accepted, OrderStatus.cancelled) => true,
      _ => false,
    };
  }
}
