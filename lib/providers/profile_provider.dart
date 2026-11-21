import 'package:flutter/foundation.dart';
import '../models/customer_profile.dart';

class ProfileProvider extends ChangeNotifier {
  CustomerProfile? _profile;

  CustomerProfile? get profile => _profile;

  bool get hasProfile => _profile != null;

  void save(CustomerProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void clear() {
    _profile = null;
    notifyListeners();
  }
}
