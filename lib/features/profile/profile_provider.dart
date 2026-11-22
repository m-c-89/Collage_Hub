import 'package:flutter/foundation.dart';
import 'package:college_canteen/features/delivery/models/delivery_partner_profile.dart';
import 'package:college_canteen/features/profile/customer_profile.dart';
import 'package:college_canteen/features/vendor/models/vendor_profile.dart';

class ProfileProvider extends ChangeNotifier {
  CustomerProfile? _profile;
  bool _isVendor = false;
  VendorProfile? _vendorProfile;
  bool _isDeliveryPartner = false;
  DeliveryPartnerProfile? _deliveryPartnerProfile;

  CustomerProfile? get profile => _profile;

  bool get hasProfile => _profile != null;

  bool get isVendor => _profile?.isVendor ?? _isVendor;

  VendorProfile? get vendorProfile => _profile?.vendorProfile ?? _vendorProfile;

  bool get isDeliveryPartner =>
      _profile?.isDeliveryPartner ?? _isDeliveryPartner;

  DeliveryPartnerProfile? get deliveryPartnerProfile =>
      _profile?.deliveryPartnerProfile ?? _deliveryPartnerProfile;

  void save(CustomerProfile profile) {
    _profile = profile.copyWith(
      isVendor: profile.isVendor || _isVendor,
      vendorProfile: profile.vendorProfile ?? _vendorProfile,
      isDeliveryPartner: profile.isDeliveryPartner || _isDeliveryPartner,
      deliveryPartnerProfile:
          profile.deliveryPartnerProfile ?? _deliveryPartnerProfile,
    );
    _isVendor = _profile!.isVendor;
    _vendorProfile = _profile!.vendorProfile;
    _isDeliveryPartner = _profile!.isDeliveryPartner;
    _deliveryPartnerProfile = _profile!.deliveryPartnerProfile;
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

  void becomeDeliveryPartner(DeliveryPartnerProfile partner) {
    _isDeliveryPartner = true;
    _deliveryPartnerProfile = partner;
    if (_profile != null) {
      _profile = _profile!.copyWith(
        isDeliveryPartner: true,
        deliveryPartnerProfile: partner,
      );
    }
    notifyListeners();
  }

  void clear() {
    _profile = null;
    _isVendor = false;
    _vendorProfile = null;
    _isDeliveryPartner = false;
    _deliveryPartnerProfile = null;
    notifyListeners();
  }
}
