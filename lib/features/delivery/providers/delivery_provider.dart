import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/features/delivery/models/delivery_order.dart';
import 'package:college_canteen/features/delivery/services/delivery_metrics.dart';
import 'package:college_canteen/features/delivery/services/order_batching_engine.dart';
import 'package:college_canteen/features/delivery/services/trip_rules.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/models/order.dart';

class DeliveryProvider extends ChangeNotifier {
  final String partnerId;
  final OrderRepository _orders;
  final DateTime Function() _now;

  StreamSubscription<List<Order>>? _ordersSubscription;
  bool _isDisposed = false;

  bool _isOnline = true;
  List<Order> _rawOrders = const [];
  List<DeliveryBatch> _pendingBatches = const [];
  List<DeliveryOrder> _activeTrip = const [];
  List<DeliveryOrder> _pickupCandidates = const [];
  List<String> _tripPickupVendorNames = const [];
  DeliveryMetrics _metrics = const DeliveryMetrics(
    activeDeliveries: 0,
    deliveredToday: 0,
  );

  DeliveryBatch? _newBatchAlert;
  final Set<String> _seenBatchIds = <String>{};
  bool _hasReceivedFirstEmission = false;

  bool _isActionInProgress = false;
  String? _lastError;

  DeliveryProvider({
    required this.partnerId,
    required OrderRepository orders,
    DateTime Function()? now,
  })  : _orders = orders,
        _now = now ?? DateTime.now {
    _ordersSubscription = _orders.watchOrders().listen(_onOrdersUpdated);
  }

  bool get isOnline => _isOnline;
  List<DeliveryBatch> get pendingBatches => _pendingBatches;
  List<DeliveryOrder> get activeTrip => _activeTrip;
  List<DeliveryOrder> get pickupCandidates => _pickupCandidates;
  List<String> get tripPickupVendorNames => _tripPickupVendorNames;
  DeliveryMetrics get metrics => _metrics;
  DeliveryBatch? get newBatchAlert => _newBatchAlert;
  bool get isActionInProgress => _isActionInProgress;
  String? get lastError => _lastError;

  int get waitingForKitchenCount =>
      _pickupCandidates.where((o) => o.status == OrderStatus.preparing).length;

  bool get canConfirmPickup =>
      _pickupCandidates.isNotEmpty &&
      _pickupCandidates.every((o) => o.status == OrderStatus.readyForPickup);

  void setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    if (!_isOnline) {
      _pendingBatches = const [];
    } else {
      _pendingBatches = OrderBatchingEngine.build(_rawOrders);
    }
    _safeNotifyListeners();
  }

  void dismissAlert() {
    _newBatchAlert = null;
    _safeNotifyListeners();
  }

  void clearError() {
    _lastError = null;
    _safeNotifyListeners();
  }

  void _onOrdersUpdated(List<Order> orders) {
    _rawOrders = orders;
    _recompute(orders);
  }

  void _recompute(List<Order> orders) {
    final now = _now();

    final matchingOrders = orders.where((o) {
      if (o.assignedPartnerId != partnerId) return false;
      return o.status == OrderStatus.preparing ||
          o.status == OrderStatus.readyForPickup ||
          o.status == OrderStatus.outForDelivery;
    }).toList();

    final tripStops = matchingOrders.map(DeliveryOrder.fromOrder).toList();
    tripStops.sort((a, b) {
      final f = a.floor.compareTo(b.floor);
      if (f != 0) return f;
      final r = a.room.compareTo(b.room);
      if (r != 0) return r;
      return a.orderId.compareTo(b.orderId);
    });

    _activeTrip = List.unmodifiable(tripStops);
    _tripPickupVendorNames = List.unmodifiable(
      _activeTrip.map((o) => o.vendorName).toSet().toList()..sort(),
    );
    _pickupCandidates = List.unmodifiable(
      _activeTrip.where((o) =>
          o.status == OrderStatus.preparing ||
          o.status == OrderStatus.readyForPickup),
    );

    _metrics = DeliveryMetrics.compute(
      orders: orders,
      partnerId: partnerId,
      now: now,
    );

    if (!_hasReceivedFirstEmission) {
      _hasReceivedFirstEmission = true;
      final initialBatches = OrderBatchingEngine.build(orders);
      for (final b in initialBatches) {
        _seenBatchIds.add(b.id);
      }
      _pendingBatches = _isOnline ? initialBatches : const [];
    } else {
      if (_isOnline) {
        final currentBatches = OrderBatchingEngine.build(orders);
        _pendingBatches = currentBatches;

        DeliveryBatch? alertCandidate;
        for (final b in currentBatches) {
          if (!_seenBatchIds.contains(b.id)) {
            _seenBatchIds.add(b.id);
            alertCandidate ??= b;
          }
        }

        if (alertCandidate != null) {
          _newBatchAlert = alertCandidate;
          HapticFeedback.lightImpact();
        }
      } else {
        _pendingBatches = const [];
      }
    }

    _safeNotifyListeners();
  }

  Future<bool> acceptBatch(String batchId) async {
    final result = await _runAction(() async {
      final batchIndex = _pendingBatches.indexWhere((b) => b.id == batchId);
      final batch = batchIndex != -1 ? _pendingBatches[batchIndex] : null;
      if (batch == null) {
        throw const AppException('Batch not found');
      }
      if (!TripRules.canTakeOrders(
        activeCount: _activeTrip.length,
        adding: batch.stops.length,
      )) {
        throw const AppException('Trip limit reached');
      }
      final orderIds = batch.stops.map((s) => s.orderId).toList();
      await _orders.assignPartners(orderIds, partnerId);
      return true;
    }, 'Failed to accept batch');
    return result ?? false;
  }

  Future<bool> addOrderToActiveTrip(String orderId) async {
    final result = await _runAction(() async {
      if (!TripRules.canTakeOrders(
        activeCount: _activeTrip.length,
        adding: 1,
      )) {
        throw const AppException('Trip limit reached');
      }
      await _orders.assignPartner(orderId, partnerId);
      return true;
    }, 'Failed to add order to trip');
    return result ?? false;
  }

  Future<bool> confirmPickup() async {
    final result = await _runAction(() async {
      if (!canConfirmPickup) {
        throw const AppException('Cannot confirm pickup');
      }
      for (final candidate in _pickupCandidates) {
        await _orders.updateStatus(
          candidate.orderId,
          OrderStatus.outForDelivery,
          UserRole.deliveryPartner,
          actorId: partnerId,
        );
      }
      return true;
    }, 'Failed to confirm pickup');
    return result ?? false;
  }

  Future<bool> markDelivered(String orderId) async {
    final result = await _runAction(() async {
      await _orders.updateStatus(
        orderId,
        OrderStatus.delivered,
        UserRole.deliveryPartner,
        actorId: partnerId,
      );
      return true;
    }, 'Failed to mark order as delivered');
    return result ?? false;
  }

  Future<T?> _runAction<T>(
    Future<T> Function() action,
    String defaultErrorMessage,
  ) async {
    if (_isActionInProgress || _isDisposed) return null;
    _isActionInProgress = true;
    _lastError = null;
    _safeNotifyListeners();

    try {
      return await action();
    } on AppException catch (e) {
      _lastError = e.userMessage;
      return null;
    } catch (_) {
      _lastError = defaultErrorMessage;
      return null;
    } finally {
      _isActionInProgress = false;
      _safeNotifyListeners();
    }
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
