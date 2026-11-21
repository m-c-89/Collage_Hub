import 'user_role.dart';

enum OrderStatus {
  placed,
  accepted,
  preparing,
  readyForPickup,
  outForDelivery,
  delivered,
  cancelled;

  String get label => switch (this) {
        OrderStatus.placed => 'Placed',
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
      (OrderStatus.placed, OrderStatus.accepted, UserRole.vendor) => true,
      (OrderStatus.placed, OrderStatus.cancelled, UserRole.customer) => true,
      (OrderStatus.placed, OrderStatus.cancelled, UserRole.vendor) => true,
      (OrderStatus.accepted, OrderStatus.preparing, UserRole.vendor) => true,
      (OrderStatus.accepted, OrderStatus.cancelled, UserRole.vendor) => true,
      (OrderStatus.preparing, OrderStatus.readyForPickup, UserRole.vendor) => true,
      (OrderStatus.preparing, OrderStatus.cancelled, UserRole.vendor) => true,
      (OrderStatus.readyForPickup, OrderStatus.outForDelivery, UserRole.deliveryPartner) => true,
      (OrderStatus.outForDelivery, OrderStatus.delivered, UserRole.deliveryPartner) => true,
      _ => false,
    };
  }
}
