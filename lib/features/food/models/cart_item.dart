import 'package:college_canteen/features/food/models/food_item.dart';

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({
    required this.item,
    this.quantity = 1,
  });

  int get totalPrice => item.price * quantity;

  CartItem copyWith({
    MenuItem? item,
    int? quantity,
  }) {
    return CartItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }
}
