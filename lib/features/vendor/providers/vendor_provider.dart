import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/vendor/data/vendor_repository.dart';
import 'package:college_canteen/features/vendor/models/vendor_profile.dart';
import 'package:college_canteen/features/vendor/services/vendor_analytics.dart';

class VendorProvider extends ChangeNotifier {
  final String vendorId;
  final OrderRepository _orders;
  final VendorRepository _vendors;
  final DateTime Function() _now;

  StreamSubscription<List<Order>>? _ordersSub;
  StreamSubscription<List<VendorProfile>>? _vendorsSub;
  bool _disposed = false;

  VendorProfile? _profile;
  List<Order> _allOrders = const [];
  List<Order> _incoming = const [];
  List<Order> _inProgress = const [];
  List<Order> _completed = const [];

  DateTime _lastAnalysisAt = DateTime.fromMillisecondsSinceEpoch(0);
  VendorAnalyticsResult? _cachedAnalytics;

  bool _isFirstOrdersEmission = true;
  final Set<String> _knownPlacedOrderIds = <String>{};
  final Set<String> _seenOrderIds = <String>{};

  final Set<String> _inFlightOrderIds = <String>{};
  bool _isSettingAccepting = false;
  String? _lastError;

  VendorProvider({
    required this.vendorId,
    required OrderRepository orders,
    required VendorRepository vendors,
    DateTime Function()? now,
  })  : _orders = orders,
        _vendors = vendors,
        _now = now ?? DateTime.now {
    _profile = _vendors.byId(vendorId);
    _recomputeAnalytics();

    _ordersSub = _orders.watchOrders().listen((ordersList) {
      _allOrders = ordersList;
      _processOrders(ordersList);
      _recomputeAnalytics();
      notifyListeners();
    });

    _vendorsSub = _vendors.watchVendors().listen((vendorsList) {
      final updatedProfile = vendorsList
          .cast<VendorProfile?>()
          .firstWhere((v) => v?.vendorId == vendorId, orElse: () => null);

      if (updatedProfile != _profile) {
        _profile = updatedProfile;
        _recomputeAnalytics();
        notifyListeners();
      }
    });
  }

  VendorProfile? get profile => _profile;
  List<Order> get incoming => List.unmodifiable(_incoming);
  List<Order> get inProgress => List.unmodifiable(_inProgress);
  List<Order> get completed => List.unmodifiable(_completed);

  DateTime get lastAnalysisAt => _lastAnalysisAt;
  VendorAnalyticsResult get analytics =>
      _cachedAnalytics ?? _computeDefaultAnalytics();

  int get newOrderBadge =>
      _incoming.where((o) => !_seenOrderIds.contains(o.id)).length;

  bool isOrderInFlight(String orderId) => _inFlightOrderIds.contains(orderId);
  bool get isSettingAccepting => _isSettingAccepting;
  String? get lastError => _lastError;

  void markOrdersSeen() {
    var changed = false;
    for (final order in _incoming) {
      if (_seenOrderIds.add(order.id)) {
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void clearLastError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  Future<void> accept(String orderId) async {
    if (_inFlightOrderIds.contains(orderId)) return;
    _inFlightOrderIds.add(orderId);
    _lastError = null;
    notifyListeners();

    try {
      await _orders.updateStatus(orderId, OrderStatus.accepted, UserRole.vendor);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      _inFlightOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<void> reject(String orderId) async {
    if (_inFlightOrderIds.contains(orderId)) return;
    _inFlightOrderIds.add(orderId);
    _lastError = null;
    notifyListeners();

    try {
      await _orders.updateStatus(orderId, OrderStatus.cancelled, UserRole.vendor);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      _inFlightOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<void> startPreparing(String orderId) async {
    if (_inFlightOrderIds.contains(orderId)) return;
    _inFlightOrderIds.add(orderId);
    _lastError = null;
    notifyListeners();

    try {
      await _orders.updateStatus(
          orderId, OrderStatus.preparing, UserRole.vendor);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      _inFlightOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<void> markReady(String orderId) async {
    if (_inFlightOrderIds.contains(orderId)) return;
    _inFlightOrderIds.add(orderId);
    _lastError = null;
    notifyListeners();

    try {
      await _orders.updateStatus(
          orderId, OrderStatus.readyForPickup, UserRole.vendor);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      _inFlightOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<void> setAccepting(bool value) async {
    if (_isSettingAccepting) return;
    _isSettingAccepting = true;
    _lastError = null;
    notifyListeners();

    try {
      await _vendors.setAcceptingOrders(vendorId, value);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      _isSettingAccepting = false;
      notifyListeners();
    }
  }

  void _processOrders(List<Order> ordersList) {
    final vendorOrders =
        ordersList.where((o) => o.vendorId == vendorId).toList();

    _incoming = vendorOrders
        .where((o) => o.status == OrderStatus.placed)
        .toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    _inProgress = vendorOrders
        .where((o) =>
            o.status == OrderStatus.accepted ||
            o.status == OrderStatus.preparing ||
            o.status == OrderStatus.readyForPickup ||
            o.status == OrderStatus.outForDelivery)
        .toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    _completed = vendorOrders
        .where((o) =>
            o.status == OrderStatus.delivered ||
            o.status == OrderStatus.cancelled)
        .toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    if (_isFirstOrdersEmission) {
      _isFirstOrdersEmission = false;
      _knownPlacedOrderIds.addAll(_incoming.map((o) => o.id));
    } else {
      for (final order in _incoming) {
        if (!_knownPlacedOrderIds.contains(order.id)) {
          _knownPlacedOrderIds.add(order.id);
          try {
            HapticFeedback.lightImpact();
          } catch (_) {}
        }
      }
    }
  }

  void _recomputeAnalytics() {
    final threshold =
        _profile?.analyticsOrderThreshold ?? AppConfig.defaultAnalyticsBatchSize;
    _cachedAnalytics = VendorAnalytics.compute(
      orders: _allOrders,
      vendorId: vendorId,
      now: _now(),
      lastAnalysisAt: _lastAnalysisAt,
      threshold: threshold,
    );
  }

  VendorAnalyticsResult _computeDefaultAnalytics() {
    return VendorAnalytics.compute(
      orders: _allOrders,
      vendorId: vendorId,
      now: _now(),
      lastAnalysisAt: _lastAnalysisAt,
      threshold:
          _profile?.analyticsOrderThreshold ?? AppConfig.defaultAnalyticsBatchSize,
    );
  }

  String _friendlyErrorMessage(Object error) {
    if (error is AppException) return error.userMessage; 
     if (error is StateError) return error.message;
    return 'Something went wrong. Please try again.';
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
    _ordersSub?.cancel();
    _vendorsSub?.cancel();
    super.dispose();
  }
}
