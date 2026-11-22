import 'package:college_canteen/features/delivery/models/delivery_partner_profile.dart';
import 'package:college_canteen/features/vendor/models/vendor_profile.dart';

class CustomerProfile {
  final String id;
  final String fullName;
  final String mobileNumber;
  final bool isVendor;
  final VendorProfile? vendorProfile;
  final bool isDeliveryPartner;
  final DeliveryPartnerProfile? deliveryPartnerProfile;

  const CustomerProfile({
    this.id = 'default-customer',
    required this.fullName,
    required this.mobileNumber,
    this.isVendor = false,
    this.vendorProfile,
    this.isDeliveryPartner = false,
    this.deliveryPartnerProfile,
  });

  CustomerProfile copyWith({
    String? id,
    String? fullName,
    String? mobileNumber,
    bool? isVendor,
    VendorProfile? vendorProfile,
    bool? isDeliveryPartner,
    DeliveryPartnerProfile? deliveryPartnerProfile,
  }) {
    return CustomerProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      isVendor: isVendor ?? this.isVendor,
      vendorProfile: vendorProfile ?? this.vendorProfile,
      isDeliveryPartner: isDeliveryPartner ?? this.isDeliveryPartner,
      deliveryPartnerProfile:
          deliveryPartnerProfile ?? this.deliveryPartnerProfile,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          mobileNumber == other.mobileNumber &&
          isVendor == other.isVendor &&
          vendorProfile == other.vendorProfile &&
          isDeliveryPartner == other.isDeliveryPartner &&
          deliveryPartnerProfile == other.deliveryPartnerProfile;

  @override
  int get hashCode => Object.hash(
        id,
        fullName,
        mobileNumber,
        isVendor,
        vendorProfile,
        isDeliveryPartner,
        deliveryPartnerProfile,
      );

  @override
  String toString() {
    return 'CustomerProfile(id: $id, fullName: $fullName, mobileNumber: $mobileNumber, isVendor: $isVendor, vendorProfile: $vendorProfile, isDeliveryPartner: $isDeliveryPartner, deliveryPartnerProfile: $deliveryPartnerProfile)';
  }
}
