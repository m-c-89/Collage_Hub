import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:college_canteen/features/food/data/menu_data.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/models/food_item.dart';

class MenuProvider extends ChangeNotifier {
  final MenuRepository _repository;
  StreamSubscription<List<MenuItem>>? _subscription;
  List<MenuItem> _items = [];
  String _selectedCategory = 'All';

  MenuProvider({required MenuRepository repository})
      : _repository = repository {
    final current = _repository.currentItems;
    _items = _filterAndSort(current.isNotEmpty ? current : canteenMenuItems);
    _subscription = _repository.watchItems().listen((items) {
      if (items.isNotEmpty) {
        _items = _filterAndSort(items);
        notifyListeners();
      }
    });
  }

  static List<MenuItem> _filterAndSort(List<MenuItem> items) {
    final foodOnly = items.where((i) => i.module == ItemModule.food).toList();
    foodOnly.sort((a, b) {
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;
      return 0;
    });
    return foodOnly;
  }

  List<MenuItem> get items => _items;

  String get selectedCategory => _selectedCategory;

  void selectCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  List<MenuItem> get filteredItems {
    if (_selectedCategory == 'All') {
      return _items;
    }
    return _items
        .where((item) => item.category.displayName == _selectedCategory)
        .toList();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
