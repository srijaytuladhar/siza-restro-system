import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';
import 'api_providers.dart';

class MenuState {
  final List<MenuItemModel> items;
  final bool isLoading;
  final String? errorMessage;

  MenuState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  MenuState copyWith({
    List<MenuItemModel>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MenuState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final Ref _ref;

  MenuNotifier(this._ref) : super(MenuState()) {
    fetchMenu();
  }

  Future<void> fetchMenu() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final menuItems = await apiService.getMenu();
      state = state.copyWith(items: menuItems, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  return MenuNotifier(ref);
});
