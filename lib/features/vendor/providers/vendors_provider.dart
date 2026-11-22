import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:college_canteen/features/vendor/data/vendor_repository.dart';
import 'package:college_canteen/features/vendor/models/vendor_profile.dart';

class VendorsProvider extends ChangeNotifier {
  final VendorRepository _vendorRepository;
  StreamSubscription<List<VendorProfile>>? _subscription;
  Map<String, bool> _openStatus = const {};
  bool _disposed = false;

  VendorsProvider({required VendorRepository vendorRepository})
      : _vendorRepository = vendorRepository {
    _subscription = _vendorRepository.watchVendors().listen((vendors) {
      final map = <String, bool>{};
      for (final v in vendors) {
        map[v.vendorId] = v.isAcceptingOrders;
      }
      _openStatus = map;
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  bool isOpen(String vendorId) {
    if (_openStatus.containsKey(vendorId)) {
      return _openStatus[vendorId]!;
    }
    return _vendorRepository.isAcceptingOrders(vendorId);
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
