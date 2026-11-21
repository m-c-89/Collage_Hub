import 'package:flutter/foundation.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';

class CheckoutProvider extends ChangeNotifier {
  DeliveryLocation? _selectedLocation;

  DeliveryLocation? get selectedLocation => _selectedLocation;

  bool get isLocationSelected => _selectedLocation != null;

  void selectLocation(DeliveryLocation? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void resetLocation() {
    _selectedLocation = null;
    notifyListeners();
  }
}
