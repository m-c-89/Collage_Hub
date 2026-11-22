import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';

class OrdersProvider extends ChangeNotifier {
  final OrderRepository _orderRepository;
  final ProfileProvider? _profileProvider;
  final String? _customerId;
  StreamSubscription<List<Order>>? _subscription;
  List<Order> _allOrders = [];
  bool _disposed = false;

  final Set<String> _inFlightOrderIds = <String>{};
  String? _lastError;

  OrdersProvider({
    required OrderRepository orderRepository,
    ProfileProvider? profileProvider,
    String? customerId,
  })  : _orderRepository = orderRepository,
        _profileProvider = profileProvider,
        _customerId = customerId {
    _allOrders = _orderRepository.currentOrders;
    _subscription = _orderRepository.watchOrders().listen(_onOrdersUpdated);
    _profileProvider?.addListener(_onProfileChanged);
  }

  void _onOrdersUpdated(List<Order> orders) {
    if (_disposed) return;
    _allOrders = orders;
    notifyListeners();
  }

  void _onProfileChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  String? get currentCustomerId => _customerId ?? _profileProvider?.profile?.id;

  String? get lastError => _lastError;

  void clearLastError() {
    _lastError = null;
  }

  bool isOrderInFlight(String orderId) => _inFlightOrderIds.contains(orderId);

  /// Exposes the current customer's orders newest-first.
  List<Order> get orders {
    final cId = currentCustomerId;
    final list = cId == null
        ? List<Order>.from(_allOrders)
        : _allOrders.where((o) => o.customerId == cId).toList();
    list.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return List.unmodifiable(list);
  }

  Future<Order?> cancelOrder(String orderId) async {
    if (_disposed || _inFlightOrderIds.contains(orderId)) return null;

    _inFlightOrderIds.add(orderId);
    if (!_disposed) notifyListeners();

    try {
      final customerId = currentCustomerId ?? 'guest';
      final order = await _orderRepository.updateStatus(
        orderId,
        OrderStatus.cancelled,
        UserRole.customer,
        actorId: customerId,
      );
      return order;
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
      return null;
    } finally {
      _inFlightOrderIds.remove(orderId);
      if (!_disposed) notifyListeners();
    }
  }

  Future<Order?> respondToEta(
    String orderId, {
    required bool agree,
  }) async {
    if (_disposed || _inFlightOrderIds.contains(orderId)) return null;

    _inFlightOrderIds.add(orderId);
    if (!_disposed) notifyListeners();

    try {
      final customerId = currentCustomerId ?? 'guest';
      final order = await _orderRepository.respondToEta(
        orderId,
        customerId,
        agree: agree,
      );
      return order;
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
      return null;
    } finally {
      _inFlightOrderIds.remove(orderId);
      if (!_disposed) notifyListeners();
    }
  }

  String _friendlyErrorMessage(Object error) {
    if (error is AppException) {
      return error.userMessage;
    }
    if (error is StateError) {
      return error.message;
    }
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Invalid request';
    }
    return 'Unable to update order. Please try again.';
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _profileProvider?.removeListener(_onProfileChanged);
    super.dispose();
  }
}
