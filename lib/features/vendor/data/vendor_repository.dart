import 'dart:async';

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/features/vendor/models/vendor_profile.dart';

abstract interface class VendorRepository {
  Stream<List<VendorProfile>> watchVendors();
  List<VendorProfile> get currentVendors;
  VendorProfile? byId(String id);
  bool isAcceptingOrders(String vendorId);
  Future<VendorProfile> register(VendorProfile p);
  Future<void> update(VendorProfile p);
  Future<void> setAcceptingOrders(String vendorId, bool value);
  Future<void> setAnalyticsThreshold(String vendorId, int value);
}

class InMemoryVendorRepository implements VendorRepository {
  final List<VendorProfile> _vendors;
  final StreamController<List<VendorProfile>> _controller =
      StreamController<List<VendorProfile>>.broadcast();

  static const VendorProfile defaultVendor = VendorProfile(
    vendorId: AppConfig.defaultVendorId,
    businessName: AppConfig.defaultVendorName,
    businessType: BusinessType.canteen,
    description: 'Campus Canteen',
    contactPhone: '9876543210',
    fssaiNumber: '12345678901234',
    analyticsOrderThreshold: AppConfig.defaultAnalyticsBatchSize,
    isAcceptingOrders: true,
  );

  InMemoryVendorRepository({List<VendorProfile>? initialVendors})
      : _vendors = List<VendorProfile>.from(
          (initialVendors != null && initialVendors.isNotEmpty)
              ? initialVendors
              : [defaultVendor],
        );

  @override
  List<VendorProfile> get currentVendors => List.unmodifiable(_vendors);

  @override
  Stream<List<VendorProfile>> watchVendors() async* {
    yield currentVendors;
    yield* _controller.stream;
  }

  @override
  VendorProfile? byId(String id) {
    final index = _vendors.indexWhere((v) => v.vendorId == id);
    return index >= 0 ? _vendors[index] : null;
  }

  @override
  bool isAcceptingOrders(String vendorId) {
    final vendor = byId(vendorId);
    if (vendor == null) {
      return false;
    }
    return vendor.isAcceptingOrders;
  }

  @override
  Future<VendorProfile> register(VendorProfile p) async {
    if (_vendors.any((v) => v.vendorId == p.vendorId)) {
      throw AppException('Vendor with ID "${p.vendorId}" already exists');
    }
    _vendors.add(p);
    if (!_controller.isClosed) {
      _controller.add(currentVendors);
    }
    return p;
  }

  @override
  Future<void> update(VendorProfile p) async {
    final index = _vendors.indexWhere((v) => v.vendorId == p.vendorId);
    if (index == -1) {
      throw AppException('Vendor with ID "${p.vendorId}" not found');
    }
    _vendors[index] = p;
    if (!_controller.isClosed) {
      _controller.add(currentVendors);
    }
  }

  @override
  Future<void> setAcceptingOrders(String vendorId, bool value) async {
    final index = _vendors.indexWhere((v) => v.vendorId == vendorId);
    if (index == -1) {
      throw AppException('Vendor with ID "$vendorId" not found');
    }
    _vendors[index] = _vendors[index].copyWith(isAcceptingOrders: value);
    if (!_controller.isClosed) {
      _controller.add(currentVendors);
    }
  }

  @override
  Future<void> setAnalyticsThreshold(String vendorId, int value) async {
    final index = _vendors.indexWhere((v) => v.vendorId == vendorId);
    if (index == -1) {
      throw AppException('Vendor with ID "$vendorId" not found');
    }
    final clamped = value.clamp(
      AppConfig.minAnalyticsBatchSize,
      AppConfig.maxAnalyticsBatchSize,
    );
    _vendors[index] =
        _vendors[index].copyWith(analyticsOrderThreshold: clamped);
    if (!_controller.isClosed) {
      _controller.add(currentVendors);
    }
  }

  void dispose() {
    _controller.close();
  }
}
