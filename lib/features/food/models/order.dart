import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';

export 'package:college_canteen/features/food/models/feedback.dart';

enum PaymentMethod {
  upi,
  card,
  cod;

  String get label => switch (this) {
        PaymentMethod.upi => 'UPI',
        PaymentMethod.card => 'Card',
        PaymentMethod.cod => 'Cash on Delivery',
      };
}

enum PaymentStatus {
  unpaid,
  paid,
  payOnDelivery,
  refundPending;

  String get label => switch (this) {
        PaymentStatus.unpaid => 'Unpaid',
        PaymentStatus.paid => 'Paid',
        PaymentStatus.payOnDelivery => 'Pay on Delivery',
        PaymentStatus.refundPending => 'Refund Pending',
      };
}

enum OrderModule {
  food,
  stationery;

  String get label => switch (this) {
        OrderModule.food => 'Food',
        OrderModule.stationery => 'Stationery',
      };
}

class OrderItem {
  final String itemId;
  final String name;
  final int quantity;
  final int unitPrice;
  final int lineTotal;

  const OrderItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  OrderItem copyWith({
    String? itemId,
    String? name,
    int? quantity,
    int? unitPrice,
    int? lineTotal,
  }) {
    return OrderItem(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItem &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId &&
          name == other.name &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice &&
          lineTotal == other.lineTotal;

  @override
  int get hashCode =>
      Object.hash(itemId, name, quantity, unitPrice, lineTotal);

  @override
  String toString() =>
      'OrderItem(itemId: $itemId, name: $name, quantity: $quantity, unitPrice: $unitPrice, lineTotal: $lineTotal)';
}

class PlaceOrderRequest {
  final String clientRequestId;
  final String customerId;
  final String vendorId;
  final List<(String itemId, int quantity)> lines;
  final String locationId;
  final int expectedTotal;

  const PlaceOrderRequest({
    required this.clientRequestId,
    required this.customerId,
    required this.vendorId,
    required this.lines,
    required this.locationId,
    required this.expectedTotal,
  });

  PlaceOrderRequest copyWith({
    String? clientRequestId,
    String? customerId,
    String? vendorId,
    List<(String itemId, int quantity)>? lines,
    String? locationId,
    int? expectedTotal,
  }) {
    return PlaceOrderRequest(
      clientRequestId: clientRequestId ?? this.clientRequestId,
      customerId: customerId ?? this.customerId,
      vendorId: vendorId ?? this.vendorId,
      lines: lines ?? this.lines,
      locationId: locationId ?? this.locationId,
      expectedTotal: expectedTotal ?? this.expectedTotal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceOrderRequest &&
          runtimeType == other.runtimeType &&
          clientRequestId == other.clientRequestId &&
          customerId == other.customerId &&
          vendorId == other.vendorId &&
          locationId == other.locationId &&
          expectedTotal == other.expectedTotal;

  @override
  int get hashCode => Object.hash(
        clientRequestId,
        customerId,
        vendorId,
        locationId,
        expectedTotal,
      );

  @override
  String toString() =>
      'PlaceOrderRequest(clientRequestId: $clientRequestId, customerId: $customerId, vendorId: $vendorId, lines: $lines, locationId: $locationId, expectedTotal: $expectedTotal)';
}

class OrderQuote {
  final List<OrderItem> lines;
  final int subtotal;
  final int deliveryFee;
  final int taxAndServiceCharge;
  final int grandTotal;
  final String vendorId;
  final String vendorName;
  final DeliveryLocation location;

  const OrderQuote({
    required this.lines,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAndServiceCharge,
    required this.grandTotal,
    required this.vendorId,
    required this.vendorName,
    required this.location,
  });

  OrderQuote copyWith({
    List<OrderItem>? lines,
    int? subtotal,
    int? deliveryFee,
    int? taxAndServiceCharge,
    int? grandTotal,
    String? vendorId,
    String? vendorName,
    DeliveryLocation? location,
  }) {
    return OrderQuote(
      lines: lines ?? this.lines,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxAndServiceCharge:
          taxAndServiceCharge ?? this.taxAndServiceCharge,
      grandTotal: grandTotal ?? this.grandTotal,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      location: location ?? this.location,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderQuote &&
          runtimeType == other.runtimeType &&
          subtotal == other.subtotal &&
          deliveryFee == other.deliveryFee &&
          taxAndServiceCharge == other.taxAndServiceCharge &&
          grandTotal == other.grandTotal &&
          vendorId == other.vendorId &&
          vendorName == other.vendorName &&
          location == other.location;

  @override
  int get hashCode => Object.hash(
        subtotal,
        deliveryFee,
        taxAndServiceCharge,
        grandTotal,
        vendorId,
        vendorName,
        location,
      );

  @override
  String toString() =>
      'OrderQuote(vendorId: $vendorId, subtotal: $subtotal, grandTotal: $grandTotal, location: ${location.address})';
}

class Order {
  final String id;
  final String clientRequestId;
  final String customerId;
  final String vendorId;
  final String vendorName;
  final OrderModule module;
  final List<OrderItem> items;
  final String locationId;
  final String building;
  final String block;
  final int floor;
  final String room;
  final String address;
  final int subtotal;
  final int deliveryFee;
  final int taxAndServiceCharge;
  final int grandTotal;
  final PaymentMethod? paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus status;
  final DateTime placedAt;
  final DateTime? estimatedReadyTime;
  final List<(OrderStatus status, DateTime timestamp)> statusHistory;
  final String? assignedPartnerId;
  final int? proposedPrepMinutes;
  final DateTime? paidAt;
  final CancelReason? cancelReason;

  const Order({
    required this.id,
    required this.clientRequestId,
    required this.customerId,
    required this.vendorId,
    required this.vendorName,
    required this.module,
    required this.items,
    required this.locationId,
    required this.building,
    required this.block,
    required this.floor,
    required this.room,
    required this.address,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAndServiceCharge,
    required this.grandTotal,
    this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.placedAt,
    this.estimatedReadyTime,
    required this.statusHistory,
    this.assignedPartnerId,
    this.proposedPrepMinutes,
    this.paidAt,
    this.cancelReason,
  });

  DateTime? timeOf(OrderStatus s) {
    for (final entry in statusHistory) {
      if (entry.$1 == s) return entry.$2;
    }
    return null;
  }

  DateTime get stageEnteredAt =>
      statusHistory.isEmpty ? placedAt : statusHistory.last.$2;

  DateTime? get confirmedAt => timeOf(OrderStatus.preparing);

  bool get isConfirmed => confirmedAt != null;

  Order copyWith({
    String? id,
    String? clientRequestId,
    String? customerId,
    String? vendorId,
    String? vendorName,
    OrderModule? module,
    List<OrderItem>? items,
    String? locationId,
    String? building,
    String? block,
    int? floor,
    String? room,
    String? address,
    int? subtotal,
    int? deliveryFee,
    int? taxAndServiceCharge,
    int? grandTotal,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    OrderStatus? status,
    DateTime? placedAt,
    DateTime? estimatedReadyTime,
    List<(OrderStatus status, DateTime timestamp)>? statusHistory,
    String? assignedPartnerId,
    int? proposedPrepMinutes,
    DateTime? paidAt,
    CancelReason? cancelReason,
  }) {
    return Order(
      id: id ?? this.id,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      customerId: customerId ?? this.customerId,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      module: module ?? this.module,
      items: items ?? this.items,
      locationId: locationId ?? this.locationId,
      building: building ?? this.building,
      block: block ?? this.block,
      floor: floor ?? this.floor,
      room: room ?? this.room,
      address: address ?? this.address,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxAndServiceCharge:
          taxAndServiceCharge ?? this.taxAndServiceCharge,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      placedAt: placedAt ?? this.placedAt,
      estimatedReadyTime: estimatedReadyTime ?? this.estimatedReadyTime,
      statusHistory: statusHistory ?? this.statusHistory,
      assignedPartnerId: assignedPartnerId ?? this.assignedPartnerId,
      proposedPrepMinutes: proposedPrepMinutes ?? this.proposedPrepMinutes,
      paidAt: paidAt ?? this.paidAt,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Order(id: $id, customerId: $customerId, status: $status, grandTotal: $grandTotal)';
}

class OrderValidationException extends AppException {
  const OrderValidationException(
    super.userMessage, {
    super.cause,
    super.stackTrace,
  });
}

class PriceChangedException extends AppException {
  final int newTotal;

  PriceChangedException(
    this.newTotal, [
    String? message,
  ]) : super(
          message ??
              'The total price has changed to ₹$newTotal. Please review and place your order again.',
        );
}
