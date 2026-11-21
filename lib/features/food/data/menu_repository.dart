import 'dart:async';
import 'package:college_canteen/features/food/data/menu_data.dart';
import 'package:college_canteen/features/food/models/food_item.dart';

abstract interface class MenuRepository {
  Stream<List<MenuItem>> watchItems();
  List<MenuItem> get currentItems;
  Future<void> upsert(MenuItem item);
  Future<void> delete(String id);
}

class InMemoryMenuRepository implements MenuRepository {
  final List<MenuItem> _items;
  final StreamController<List<MenuItem>> _controller =
      StreamController<List<MenuItem>>.broadcast();

  InMemoryMenuRepository({List<MenuItem>? initialItems})
      : _items = List<MenuItem>.from(initialItems ?? canteenMenuItems);

  @override
  List<MenuItem> get currentItems => List.unmodifiable(_items);

  @override
  Stream<List<MenuItem>> watchItems() async* {
    yield currentItems;
    yield* _controller.stream;
  }

  @override
  Future<void> upsert(MenuItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
    if (!_controller.isClosed) {
      _controller.add(currentItems);
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((i) => i.id == id);
    if (!_controller.isClosed) {
      _controller.add(currentItems);
    }
  }

  void dispose() {
    _controller.close();
  }
}
