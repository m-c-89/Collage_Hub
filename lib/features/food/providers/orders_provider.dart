import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';

class OrdersProvider extends ChangeNotifier {
  final OrderRepository _orderRepository;
  final ProfileProvider? _profileProvider;
  final String? _customerId;
  StreamSubscription<List<Order>>? _subscription;
  List<Order> _allOrders = [];

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
    _allOrders = orders;
    notifyListeners();
  }

  void _onProfileChanged() {
    notifyListeners();
  }

  String? get currentCustomerId => _customerId ?? _profileProvider?.profile?.id;

  /// Exposes the current customer's orders newest-first.
  List<Order> get orders {
    final cId = currentCustomerId;
    final list = cId == null
        ? List<Order>.from(_allOrders)
        : _allOrders.where((o) => o.customerId == cId).toList();
    list.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return List.unmodifiable(list);
  }

  Future<Order> cancelOrder(String orderId) async {
    final customerId = currentCustomerId ?? 'guest';
    return _orderRepository.updateStatus(
      orderId,
      OrderStatus.cancelled,
      UserRole.customer,
      actorId: customerId,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _profileProvider?.removeListener(_onProfileChanged);
    super.dispose();
  }
}
