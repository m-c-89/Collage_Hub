import 'package:college_canteen/core/config/app_config.dart';

enum BusinessType {
  restaurant('Restaurant'),
  cafe('Cafe'),
  hotel('Hotel'),
  canteen('Canteen'),
  stationeryShop('Stationery Shop'),
  other('Other');

  final String label;
  const BusinessType(this.label);

  bool get fssaiRequired => switch (this) {
        BusinessType.restaurant ||
        BusinessType.cafe ||
        BusinessType.hotel ||
        BusinessType.canteen =>
          true,
        BusinessType.stationeryShop || BusinessType.other => false,
      };
}

class VendorProfile {
  final String vendorId;
  final String businessName;
  final BusinessType businessType;
  final String description;
  final String contactPhone;
  final String? fssaiNumber;
  final int analyticsOrderThreshold;
  final bool isAcceptingOrders;

  const VendorProfile({
    required this.vendorId,
    required this.businessName,
    required this.businessType,
    this.description = '',
    required this.contactPhone,
    this.fssaiNumber,
    this.analyticsOrderThreshold = AppConfig.defaultAnalyticsBatchSize,
    this.isAcceptingOrders = true,
  });

  VendorProfile copyWith({
    String? vendorId,
    String? businessName,
    BusinessType? businessType,
    String? description,
    String? contactPhone,
    String? fssaiNumber,
    int? analyticsOrderThreshold,
    bool? isAcceptingOrders,
  }) {
    return VendorProfile(
      vendorId: vendorId ?? this.vendorId,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      description: description ?? this.description,
      contactPhone: contactPhone ?? this.contactPhone,
      fssaiNumber: fssaiNumber ?? this.fssaiNumber,
      analyticsOrderThreshold:
          analyticsOrderThreshold ?? this.analyticsOrderThreshold,
      isAcceptingOrders: isAcceptingOrders ?? this.isAcceptingOrders,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorProfile &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          businessName == other.businessName &&
          businessType == other.businessType &&
          description == other.description &&
          contactPhone == other.contactPhone &&
          fssaiNumber == other.fssaiNumber &&
          analyticsOrderThreshold == other.analyticsOrderThreshold &&
          isAcceptingOrders == other.isAcceptingOrders;

  @override
  int get hashCode => Object.hash(
        vendorId,
        businessName,
        businessType,
        description,
        contactPhone,
        fssaiNumber,
        analyticsOrderThreshold,
        isAcceptingOrders,
      );

  @override
  String toString() =>
      'VendorProfile(vendorId: $vendorId, businessName: $businessName, businessType: $businessType, isAcceptingOrders: $isAcceptingOrders)';
}
