import 'package:flutter/foundation.dart';
import 'package:college_canteen/features/food/models/cart_item.dart';
import 'package:college_canteen/features/food/models/food_item.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  bool get isEmpty => _items.isEmpty;

  int get totalQuantity {
    return _items.values.fold(0, (sum, cartItem) => sum + cartItem.quantity);
  }

  int get subtotal {
    return _items.values.fold(
      0,
      (sum, cartItem) => sum + (cartItem.item.price * cartItem.quantity),
    );
  }

  int quantityOf(String itemId) {
    return _items[itemId]?.quantity ?? 0;
  }

  String? get currentVendorId =>
      _items.isEmpty ? null : _items.values.first.item.vendorId;

  String? get currentVendorName =>
      _items.isEmpty ? null : _items.values.first.item.vendorName;

  bool hasDifferentVendor(MenuItem item) {
    if (_items.isEmpty) return false;
    return _items.values.first.item.vendorId != item.vendorId;
  }

  bool add(MenuItem item, {bool replace = false}) {
    if (_items.isNotEmpty) {
      final activeVendorId = _items.values.first.item.vendorId;
      if (activeVendorId != item.vendorId) {
        if (replace) {
          _items.clear();
        } else {
          return false;
        }
      }
    }
    if (_items.containsKey(item.id)) {
      _items[item.id]!.quantity += 1;
    } else {
      _items[item.id] = CartItem(item: item, quantity: 1);
    }
    notifyListeners();
    return true;
  }

  void replaceWith(MenuItem item) {
    add(item, replace: true);
  }

  void increment(String id) {
    if (_items.containsKey(id)) {
      _items[id]!.quantity += 1;
      notifyListeners();
    }
  }

  void decrement(String id) {
    if (!_items.containsKey(id)) return;

    if (_items[id]!.quantity > 1) {
      _items[id]!.quantity -= 1;
    } else {
      _items.remove(id);
    }
    notifyListeners();
  }

  void remove(String id) {
    if (_items.containsKey(id)) {
      _items.remove(id);
      notifyListeners();
    }
  }

  void clear() {
    if (_items.isNotEmpty) {
      _items.clear();
      notifyListeners();
    }
  }

  List<String> syncWithCatalog(List<MenuItem> current) {
    if (_items.isEmpty) return const [];

    final catalogMap = {for (final item in current) item.id: item};
    final messages = <String>[];
    final toRemove = <String>[];
    var changed = false;

    for (final entry in _items.entries) {
      final id = entry.key;
      final cartItem = entry.value;
      final catalogItem = catalogMap[id];

      if (catalogItem == null) {
        toRemove.add(id);
        messages.add('${cartItem.item.name} is no longer available');
      } else if (!catalogItem.isAvailable) {
        toRemove.add(id);
        messages.add('${cartItem.item.name} is no longer available');
      } else if (catalogItem.price != cartItem.item.price) {
        _items[id] = cartItem.copyWith(item: catalogItem);
        messages.add(
          'Price of ${catalogItem.name} updated to ₹${catalogItem.price}',
        );
        changed = true;
      }
    }

    for (final id in toRemove) {
      _items.remove(id);
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }

    return messages;
  }
}
