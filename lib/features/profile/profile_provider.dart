import 'package:flutter/foundation.dart';
import 'package:college_canteen/features/profile/customer_profile.dart';
import 'package:college_canteen/features/vendor/models/vendor_profile.dart';

class ProfileProvider extends ChangeNotifier {
  CustomerProfile? _profile;
  bool _isVendor = false;
  VendorProfile? _vendorProfile;

  CustomerProfile? get profile => _profile;

  bool get hasProfile => _profile != null;

  bool get isVendor => _profile?.isVendor ?? _isVendor;

  VendorProfile? get vendorProfile => _profile?.vendorProfile ?? _vendorProfile;

  void save(CustomerProfile profile) {
    _profile = profile.copyWith(
      isVendor: profile.isVendor || _isVendor,
      vendorProfile: profile.vendorProfile ?? _vendorProfile,
    );
    _isVendor = _profile!.isVendor;
    _vendorProfile = _profile!.vendorProfile;
    notifyListeners();
  }

  void becomeVendor(VendorProfile vendor) {
    _isVendor = true;
    _vendorProfile = vendor;
    if (_profile != null) {
      _profile = _profile!.copyWith(
        isVendor: true,
        vendorProfile: vendor,
      );
    }
    notifyListeners();
  }

  void clear() {
    _profile = null;
    _isVendor = false;
    _vendorProfile = null;
    notifyListeners();
  }
}
