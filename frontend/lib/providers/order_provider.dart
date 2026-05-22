import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import 'api_providers.dart';
import 'cart_provider.dart';
import 'notification_provider.dart';

class OrderState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? errorMessage;
  final bool orderSuccess;

  OrderState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.orderSuccess = false,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? errorMessage,
    bool? orderSuccess,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      orderSuccess: orderSuccess ?? this.orderSuccess,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final Ref _ref;
  StreamSubscription<OrderModel>? _wsSubscription;

  OrderNotifier(this._ref) : super(OrderState());

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  // Fetch all orders for active booking session
  Future<void> fetchOrders(int bookingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final list = await apiService.getOrdersByBooking(bookingId);
      // Sort orders by ID descending (newest on top)
      list.sort((a, b) => b.id.compareTo(a.id));
      state = state.copyWith(orders: list, isLoading: false);
      
      // Initialize WebSocket connection once orders are loaded
      _initWebSocketListener(bookingId);
      // Initialize notifications
      _ref.read(notificationProvider.notifier).fetchNotifications(bookingId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Submit cart order to backend
  Future<bool> placeCartOrder(int bookingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, orderSuccess: false);
    try {
      final cart = _ref.read(cartProvider);
      if (cart.items.isEmpty) {
        throw 'Your cart is empty';
      }

      final apiService = _ref.read(apiServiceProvider);
      final order = await apiService.placeOrder(bookingId, cart.toRequestJson);
      
      // Clear cart on successful order placement
      _ref.read(cartProvider.notifier).clearCart();
      
      // Prepend or add new order to state list
      final updatedOrders = List<OrderModel>.from(state.orders)..insert(0, order);
      state = state.copyWith(orders: updatedOrders, isLoading: false, orderSuccess: true);
      
      // Ensure WebSocket listener is active
      _initWebSocketListener(bookingId);
      _ref.read(notificationProvider.notifier).fetchNotifications(bookingId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Real-time status sync via WebSocket channel
  void _initWebSocketListener(int bookingId) {
    if (_wsSubscription != null) return; // Already listening

    final wsService = _ref.read(webSocketServiceProvider);
    
    try {
      wsService.connect(bookingId);
      final stream = wsService.orderStream;
      _wsSubscription = stream.listen(
        (updatedOrder) {
          // Verify that this order update belongs to our current active table booking
          if (updatedOrder.bookingId == bookingId) {
            _handleWebSocketUpdate(updatedOrder);
          }
        },
        onError: (err) {
          // Silently print error and attempt a reconnect if stream breaks
          _wsSubscription?.cancel();
          _wsSubscription = null;
          Future.delayed(const Duration(seconds: 5), () => _initWebSocketListener(bookingId));
        },
        onDone: () {
          _wsSubscription = null;
          Future.delayed(const Duration(seconds: 5), () => _initWebSocketListener(bookingId));
        },
      );
    } catch (_) {
      // Catch exceptions from connection failures
    }
  }

  void _handleWebSocketUpdate(OrderModel updatedOrder) {
    final updatedList = state.orders.map((order) {
      return order.id == updatedOrder.id ? updatedOrder : order;
    }).toList();

    // If order is new (not found in list), prepend it
    if (!updatedList.any((o) => o.id == updatedOrder.id)) {
      updatedList.insert(0, updatedOrder);
    }

    state = state.copyWith(orders: updatedList);
  }

  // Trigger administrative status update from the app (mock kitchen workflow)
  Future<void> mockKitchenStatusUpdate(int orderId, OrderStatus status) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.updateOrderStatus(orderId, status.name);
      // Note: The WebSocket broadcast will automatically update state, so we don't manually assign it here.
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update order status: $e');
    }
  }

  // Process payment for an order
  Future<bool> processOrderPayment(int orderId, String paymentMethod, double amount) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final payment = await apiService.processPayment(orderId, paymentMethod, amount);
      
      // Update the order payment status in our local state
      final updatedList = state.orders.map((order) {
        if (order.id == orderId) {
          return OrderModel(
            id: order.id,
            bookingId: order.bookingId,
            tableNumber: order.tableNumber,
            status: order.status,
            totalAmount: order.totalAmount,
            createdAt: order.createdAt,
            items: order.items,
            paymentStatus: payment.status.name, // PAID
            paymentMethod: payment.paymentMethod.name,
          );
        }
        return order;
      }).toList();
      
      state = state.copyWith(orders: updatedList, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearSuccess() {
    state = state.copyWith(orderSuccess: false);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier(ref);
});
