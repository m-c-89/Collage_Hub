import 'package:flutter/foundation.dart';
import 'package:college_canteen/features/food/models/campus_location.dart';
import 'package:college_canteen/features/food/models/cart_item.dart';

class CheckoutProvider extends ChangeNotifier {
  CampusLocation? _selectedLocation;

  CampusLocation? get selectedLocation => _selectedLocation;

  bool get isLocationSelected => _selectedLocation != null;

  void selectLocation(CampusLocation? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void resetLocation() {
    _selectedLocation = null;
    notifyListeners();
  }

  /// FoodSubtotal = Σ(price × quantity)
  double calculateFoodSubtotal(List<CartItem> items) {
    return items.fold(
      0.0,
      (sum, item) => sum + (item.item.price * item.quantity),
    );
  }

  /// TotalQuantity = Σ(quantity)
  int calculateTotalQuantity(List<CartItem> items) {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// ZoneChargePerItem = 15 (Zone 1) or 20 (Zone 2)
  double calculateZoneChargePerItem([CampusLocation? location]) {
    final loc = location ?? _selectedLocation;
    return loc?.chargePerItem ?? 0.0;
  }

  /// ZoneExtraTotal = ZoneChargePerItem × TotalQuantity
  double calculateZoneExtraTotal(
    List<CartItem> items, [
    CampusLocation? location,
  ]) {
    if (items.isEmpty) return 0.0;
    final perItem = calculateZoneChargePerItem(location);
    final totalQty = calculateTotalQuantity(items);
    return perItem * totalQty;
  }

  /// TotalAmount = FoodSubtotal + ZoneExtraTotal
  /// (Returns 0.0 if cart is empty)
  double calculateTotalAmount(
    List<CartItem> items, [
    CampusLocation? location,
  ]) {
    if (items.isEmpty) return 0.0;
    final foodSubtotal = calculateFoodSubtotal(items);
    final zoneExtra = calculateZoneExtraTotal(items, location);
    return foodSubtotal + zoneExtra;
  }
}
