import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';

class CartItem {
  final MenuItemModel menuItem;
  final int quantity;

  CartItem({required this.menuItem, required this.quantity});

  CartItem copyWith({int? quantity}) {
    return CartItem(
      menuItem: menuItem,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  final Map<int, CartItem> items;

  CartState({this.items = const {}});

  double get totalAmount {
    double total = 0.0;
    items.forEach((_, item) {
      total += item.menuItem.price * item.quantity;
    });
    return total;
  }

  int get totalCount {
    int count = 0;
    items.forEach((_, item) {
      count += item.quantity;
    });
    return count;
  }

  List<Map<String, dynamic>> get toRequestJson {
    return items.values
        .map((item) => {
              'menuItemId': item.menuItem.id,
              'quantity': item.quantity,
            })
        .toList();
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addItem(MenuItemModel menuItem) {
    final existing = state.items[menuItem.id];
    final updatedMap = Map<int, CartItem>.from(state.items);
    if (existing != null) {
      updatedMap[menuItem.id] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      updatedMap[menuItem.id] = CartItem(menuItem: menuItem, quantity: 1);
    }
    state = CartState(items: updatedMap);
  }

  void removeItem(int menuItemId) {
    final existing = state.items[menuItemId];
    if (existing == null) return;

    final updatedMap = Map<int, CartItem>.from(state.items);
    if (existing.quantity > 1) {
      updatedMap[menuItemId] = existing.copyWith(quantity: existing.quantity - 1);
    } else {
      updatedMap.remove(menuItemId);
    }
    state = CartState(items: updatedMap);
  }

  void updateQuantity(int menuItemId, int quantity) {
    if (quantity <= 0) {
      final updatedMap = Map<int, CartItem>.from(state.items);
      updatedMap.remove(menuItemId);
      state = CartState(items: updatedMap);
      return;
    }

    final existing = state.items[menuItemId];
    if (existing == null) return;

    final updatedMap = Map<int, CartItem>.from(state.items);
    updatedMap[menuItemId] = existing.copyWith(quantity: quantity);
    state = CartState(items: updatedMap);
  }

  void clearCart() {
    state = CartState(items: const {});
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
