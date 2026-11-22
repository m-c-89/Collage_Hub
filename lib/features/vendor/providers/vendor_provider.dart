import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/features/food/data/feedback_repository.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/domain/cart_pricing.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/models/feedback.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/vendor/data/vendor_repository.dart';
import 'package:college_canteen/features/vendor/models/vendor_profile.dart';
import 'package:college_canteen/features/vendor/services/vendor_analytics.dart';
import 'package:college_canteen/features/vendor/services/vendor_suggestion_engine.dart';
import 'package:college_canteen/features/vendor/services/vendor_validators.dart';

class VendorProvider extends ChangeNotifier {
  final String vendorId;
  final OrderRepository _orders;
  final VendorRepository _vendors;
  final MenuRepository _menu;
  final FeedbackRepository _feedback;
  final DateTime Function() _now;

  StreamSubscription<List<Order>>? _ordersSub;
  StreamSubscription<List<VendorProfile>>? _vendorsSub;
  StreamSubscription<List<MenuItem>>? _menuSub;
  StreamSubscription<List<OrderFeedback>>? _feedbackSub;
  bool _disposed = false;

  VendorProfile? _profile;
  List<Order> _allOrders = const [];
  List<Order> _needsAction = const [];
  List<Order> _waiting = const [];
  List<Order> _inProgress = const [];
  List<Order> _completed = const [];

  List<MenuItem> _vendorItems = const [];
  List<OrderFeedback> _allFeedback = const [];
  List<Suggestion> _suggestions = const [];

  DateTime _lastAnalysisAt = DateTime.fromMillisecondsSinceEpoch(0);
  VendorAnalyticsResult? _cachedAnalytics;

  bool _isFirstOrdersEmission = true;
  final Set<String> _knownActionOrderKeys = <String>{};
  final Set<String> _seenActionKeys = <String>{};
  final Set<String> _seenOrderIds = <String>{};

  final Set<String> _inFlightOrderIds = <String>{};
  bool _isSettingAccepting = false;
  String? _lastError;

  VendorProvider({
    required this.vendorId,
    required OrderRepository orders,
    required VendorRepository vendors,
    MenuRepository? menu,
    MenuRepository? menuRepository,
    FeedbackRepository? feedback,
    FeedbackRepository? feedbackRepository,
    DateTime Function()? now,
  })  : _orders = orders,
        _vendors = vendors,
        _menu = menu ?? menuRepository ?? InMemoryMenuRepository(),
        _feedback =
            feedback ?? feedbackRepository ?? InMemoryFeedbackRepository(),
        _now = now ?? DateTime.now {
    _profile = _vendors.byId(vendorId);
    _vendorItems = _menu.currentItems
        .where((i) => i.vendorId == vendorId)
        .toList();
    _recomputeAnalytics();

    _ordersSub = _orders.watchOrders().listen((ordersList) {
      _allOrders = ordersList;
      _processOrders(ordersList);
      _recomputeAnalytics();
      _checkAnalysisCycle();
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

    _menuSub = _menu.watchItems().listen((itemsList) {
      _vendorItems = itemsList
          .where((i) => i.vendorId == vendorId)
          .toList();
      notifyListeners();
    });

    _feedbackSub = _feedback.watchFeedback().listen((feedbackList) {
      _allFeedback = feedbackList;
      notifyListeners();
    });
  }

  VendorProfile? get profile => _profile;
  List<Order> get needsAction => List.unmodifiable(_needsAction);
  List<Order> get waiting => List.unmodifiable(_waiting);
  List<Order> get inProgress => List.unmodifiable(_inProgress);
  List<Order> get completed => List.unmodifiable(_completed);

  /// Backward-compatible alias for [needsAction]
  List<Order> get incoming => needsAction;

  List<MenuItem> get vendorItems => List.unmodifiable(_vendorItems);
  List<Suggestion> get suggestions => List.unmodifiable(_suggestions);

  DateTime get lastAnalysisAt => _lastAnalysisAt;
  VendorAnalyticsResult get analytics =>
      _cachedAnalytics ?? _computeDefaultAnalytics();

  int get newOrderBadge => _needsAction
      .where((o) => !_seenActionKeys.contains('${o.id}_${o.status.name}'))
      .length;

  bool isOrderInFlight(String orderId) => _inFlightOrderIds.contains(orderId);
  bool get isSettingAccepting => _isSettingAccepting;
  String? get lastError => _lastError;

  void markOrdersSeen() {
    var changed = false;
    for (final order in _needsAction) {
      if (_seenActionKeys.add('${order.id}_${order.status.name}')) {
        changed = true;
      }
      _seenOrderIds.add(order.id);
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

  Future<void> proposeEta(String orderId, int minutes) async {
    if (_inFlightOrderIds.contains(orderId)) return;
    _inFlightOrderIds.add(orderId);
    _lastError = null;
    notifyListeners();

    try {
      await _orders.proposeEta(orderId, vendorId, minutes);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      _inFlightOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<void> accept(String orderId) async {
    if (_inFlightOrderIds.contains(orderId)) return;
    _inFlightOrderIds.add(orderId);
    _lastError = null;
    notifyListeners();

    try {
      await _orders.updateStatus(
        orderId,
        OrderStatus.accepted,
        UserRole.vendor,
        actorId: vendorId,
      );
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
      await _orders.updateStatus(
        orderId,
        OrderStatus.cancelled,
        UserRole.vendor,
        actorId: vendorId,
        reason: CancelReason.vendorRejected,
      );
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      _inFlightOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String orderId) async {
    if (_inFlightOrderIds.contains(orderId)) return;
    _inFlightOrderIds.add(orderId);
    _lastError = null;
    notifyListeners();

    try {
      await _orders.updateStatus(
        orderId,
        OrderStatus.cancelled,
        UserRole.vendor,
        actorId: vendorId,
        reason: CancelReason.vendorCancelled,
      );
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
        orderId,
        OrderStatus.readyForPickup,
        UserRole.vendor,
        actorId: vendorId,
      );
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

  Future<void> setThreshold(int value) async {
    final clamped = clampThreshold(value);
    _lastError = null;
    notifyListeners();

    try {
      await _vendors.setAnalyticsThreshold(vendorId, clamped);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveItem(MenuItem item) async {
    _lastError = null;
    notifyListeners();

    try {
      await _menu.upsertAs(vendorId, item);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    _lastError = null;
    notifyListeners();

    try {
      await _menu.deleteAs(vendorId, id);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> setAvailability(MenuItem item, bool isAvailable) async {
    _lastError = null;
    notifyListeners();

    try {
      final updated = item.copyWith(isAvailable: isAvailable);
      await _menu.upsertAs(vendorId, updated);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> applyDiscount(MenuItem item, int newPrice) async {
    final error = validateDiscount(
      originalPrice: item.price,
      discountedPrice: newPrice,
    );
    if (error != null) {
      _lastError = error;
      notifyListeners();
      return;
    }
    _lastError = null;
    notifyListeners();

    try {
      final updated = item.copyWith(
        originalPrice: item.price,
        price: newPrice,
      );
      await _menu.upsertAs(vendorId, updated);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> removeDiscount(MenuItem item) async {
    if (item.originalPrice == null) return;
    _lastError = null;
    notifyListeners();

    try {
      final restoredPrice = item.originalPrice!;
      final updated = MenuItem(
        id: item.id,
        name: item.name,
        category: item.category,
        description: item.description,
        vendorId: item.vendorId,
        vendorName: item.vendorName,
        price: restoredPrice,
        originalPrice: null,
        rating: item.rating,
        ratingCount: item.ratingCount,
        prepMinMinutes: item.prepMinMinutes,
        prepMaxMinutes: item.prepMaxMinutes,
        isAvailable: item.isAvailable,
        customCustomerMessage: item.customCustomerMessage,
        module: item.module,
        imageUrl: item.imageUrl,
      );
      await _menu.upsertAs(vendorId, updated);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> setCustomMessage(MenuItem item, String? message) async {
    final error = validateCustomMessage(message);
    if (error != null) {
      _lastError = error;
      notifyListeners();
      return;
    }
    _lastError = null;
    notifyListeners();

    try {
      final trimmed = message?.trim();
      final updated = MenuItem(
        id: item.id,
        name: item.name,
        category: item.category,
        description: item.description,
        vendorId: item.vendorId,
        vendorName: item.vendorName,
        price: item.price,
        originalPrice: item.originalPrice,
        rating: item.rating,
        ratingCount: item.ratingCount,
        prepMinMinutes: item.prepMinMinutes,
        prepMaxMinutes: item.prepMaxMinutes,
        isAvailable: item.isAvailable,
        customCustomerMessage:
            (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        module: item.module,
        imageUrl: item.imageUrl,
      );
      await _menu.upsertAs(vendorId, updated);
    } catch (e) {
      _lastError = _friendlyErrorMessage(e);
    } finally {
      notifyListeners();
    }
  }

  void simulateCompletedOrders(int n) {
    if (!kDebugMode) return;
    if (n <= 0) return;

    if (_vendorItems.isEmpty) {
      _lastError = 'Add items to your menu first before simulating orders';
      notifyListeners();
      return;
    }

    final random = math.Random();
    final now = _now();
    final newOrders = <Order>[];

    for (var i = 0; i < n; i++) {
      final numItems = math.min(random.nextInt(2) + 1, _vendorItems.length);
      final shuffled = List<MenuItem>.from(_vendorItems)..shuffle(random);
      final pickedItems = shuffled.take(numItems).toList();

      final orderItems = <OrderItem>[];
      var subtotal = 0;
      var totalQuantity = 0;

      for (final item in pickedItems) {
        final qty = random.nextInt(2) + 1;
        final lineTotal = item.price * qty;
        subtotal += lineTotal;
        totalQuantity += qty;
        orderItems.add(
          OrderItem(
            itemId: item.id,
            name: item.name,
            quantity: qty,
            unitPrice: item.price,
            lineTotal: lineTotal,
          ),
        );
      }

      final location = kDeliveryLocations[i % kDeliveryLocations.length];
      final pricing = CartPricing.compute(
        subtotal: subtotal,
        itemCount: totalQuantity,
        location: location,
      );

      final orderDeliveredAt =
          now.subtract(Duration(seconds: (n - 1 - i) * 5));
      final placedAt = orderDeliveredAt.subtract(const Duration(minutes: 25));
      final etaProposedAt = placedAt.add(const Duration(seconds: 30));
      final etaAgreedAt = placedAt.add(const Duration(minutes: 1));
      final acceptedAt = placedAt.add(const Duration(minutes: 1, seconds: 30));
      final paidAt = placedAt.add(const Duration(minutes: 2));
      final preparingAt = placedAt.add(const Duration(minutes: 3));
      final readyForPickupAt = placedAt.add(const Duration(minutes: 15));
      final outForDeliveryAt = placedAt.add(const Duration(minutes: 18));

      final statusHistory = <(OrderStatus, DateTime)>[
        (OrderStatus.placed, placedAt),
        (OrderStatus.etaProposed, etaProposedAt),
        (OrderStatus.etaAgreed, etaAgreedAt),
        (OrderStatus.accepted, acceptedAt),
        (OrderStatus.preparing, preparingAt),
        (OrderStatus.readyForPickup, readyForPickupAt),
        (OrderStatus.outForDelivery, outForDeliveryAt),
        (OrderStatus.delivered, orderDeliveredAt),
      ];

      final timestamp = orderDeliveredAt.millisecondsSinceEpoch;
      final orderId = 'ORD-SIM-$timestamp-$i';

      newOrders.add(
        Order(
          id: orderId,
          clientRequestId: 'seed-sim-$timestamp-$i',
          customerId: 'sim-customer-$i',
          vendorId: vendorId,
          vendorName: _profile?.businessName ?? AppConfig.defaultVendorName,
          module: pickedItems.first.module == ItemModule.stationery
          ? OrderModule.stationery
          : OrderModule.food, 
          items: orderItems,
          locationId: location.id,
          building: location.building,
          block: location.block,
          floor: location.floor,
          room: location.room,
          address: location.address,
          subtotal: pricing.subtotal,
          deliveryFee: pricing.deliveryFee,
          taxAndServiceCharge: pricing.taxAndServiceCharge,
          grandTotal: pricing.grandTotal,
          paymentMethod:
              PaymentMethod.values[i % PaymentMethod.values.length],
          paymentStatus: PaymentStatus.paid,
          status: OrderStatus.delivered,
          placedAt: placedAt,
          estimatedReadyTime: readyForPickupAt,
          statusHistory: statusHistory,
          assignedPartnerId: 'demo-partner',
          proposedPrepMinutes: 15,
          paidAt: paidAt,
        ),
      );
    }

    _orders.seedOrders(newOrders);
  }

  void _checkAnalysisCycle() {
    final threshold =
        _profile?.analyticsOrderThreshold ?? AppConfig.defaultAnalyticsBatchSize;
    final currentAnalytics = _cachedAnalytics ?? _computeDefaultAnalytics();

    if (shouldRefreshAnalysis(
        currentAnalytics.completedSinceLastAnalysis, threshold)) {
      final deliveredOrdersInWindow = _allOrders.where((o) {
        if (o.vendorId != vendorId) return false;
        if (o.status != OrderStatus.delivered) return false;
        final delTime = o.timeOf(OrderStatus.delivered);
        return delTime != null && delTime.isAfter(_lastAnalysisAt);
      }).toList();

      final vendorFeedback =
          _allFeedback.where((f) => f.vendorId == vendorId).toList();

      _suggestions = VendorSuggestionEngine.generate(
        deliveredOrdersInWindow: deliveredOrdersInWindow,
        feedback: vendorFeedback,
        menu: _vendorItems,
      );
      _lastAnalysisAt = _now();
      _recomputeAnalytics();
    }
  }

  void _processOrders(List<Order> ordersList) {
    final vendorOrders =
        ordersList.where((o) => o.vendorId == vendorId).toList();

    _needsAction = vendorOrders
        .where((o) =>
            o.status == OrderStatus.placed ||
            o.status == OrderStatus.etaAgreed)
        .toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    _waiting = vendorOrders
        .where((o) =>
            o.status == OrderStatus.etaProposed ||
            (o.status == OrderStatus.accepted &&
                o.paymentStatus == PaymentStatus.unpaid))
        .toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    _inProgress = vendorOrders
        .where((o) =>
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
      _knownActionOrderKeys.addAll(
        _needsAction.map((o) => '${o.id}_${o.status.name}'),
      );
    } else {
      var hasNew = false;
      for (final order in _needsAction) {
        final key = '${order.id}_${order.status.name}';
        if (!_knownActionOrderKeys.contains(key)) {
          _knownActionOrderKeys.add(key);
          hasNew = true;
        }
      }
      if (hasNew) {
        try {
          HapticFeedback.lightImpact();
        } catch (_) {}
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
    _menuSub?.cancel();
    _feedbackSub?.cancel();
    super.dispose();
  }
}
