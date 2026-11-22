import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';

enum CartBanner { none, minOrder, selectLocation }

class PricingResult {
  final int subtotal;
  final int itemCount;
  final int deliveryFee;
  final int taxAndServiceCharge;
  final int grandTotal;
  final int shortfall;
  final bool meetsMinimum;
  final bool hasLocation;
  final bool canCheckout;
  final CartBanner banner;
  final DeliveryLocation? location;

  const PricingResult({
    required this.subtotal,
    required this.itemCount,
    required this.deliveryFee,
    required this.taxAndServiceCharge,
    required this.grandTotal,
    required this.shortfall,
    required this.meetsMinimum,
    required this.hasLocation,
    required this.canCheckout,
    required this.banner,
    required this.location,
  });
}

abstract final class CartPricing {
  static PricingResult compute({
    required int subtotal,
    required int itemCount,
    DeliveryLocation? location,
  }) {
    final isEmpty = itemCount == 0;
    final shortfall = isEmpty
        ? 0
        : (AppConfig.minOrderSubtotal - subtotal).clamp(0, AppConfig.minOrderSubtotal);
    final meetsMinimum = !isEmpty && subtotal >= AppConfig.minOrderSubtotal;
    final hasLocation = location != null;

    final deliveryFee = (meetsMinimum && location != null) ? location.fee : 0;
    final taxAndServiceCharge = isEmpty
        ? 0
        : ((subtotal * AppConfig.taxRate).round() + AppConfig.serviceCharge);
    final grandTotal = subtotal + deliveryFee + taxAndServiceCharge;
    final canCheckout = !isEmpty && meetsMinimum && hasLocation;

    final CartBanner banner;
    if (isEmpty) {
      banner = CartBanner.none;
    } else if (!meetsMinimum) {
      banner = CartBanner.minOrder;
    } else if (!hasLocation) {
      banner = CartBanner.selectLocation;
    } else {
      banner = CartBanner.none;
    }

    return PricingResult(
      subtotal: subtotal,
      itemCount: itemCount,
      deliveryFee: deliveryFee,
      taxAndServiceCharge: taxAndServiceCharge,
      grandTotal: isEmpty ? subtotal : grandTotal,
      shortfall: shortfall,
      meetsMinimum: meetsMinimum,
      hasLocation: hasLocation,
      canCheckout: canCheckout,
      banner: banner,
      location: location,
    );
  }
}
