import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'api_providers.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? errorMessage;
  final NotificationModel? latestNotification;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
    this.latestNotification,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? errorMessage,
    NotificationModel? latestNotification,
    bool clearLatest = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      latestNotification: clearLatest ? null : (latestNotification ?? this.latestNotification),
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref _ref;
  StreamSubscription<NotificationModel>? _wsSubscription;

  NotificationNotifier(this._ref) : super(NotificationState());

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications(int bookingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final list = await apiService.getNotifications(bookingId);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(notifications: list, isLoading: false);
      
      _initWebSocketListener(bookingId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _initWebSocketListener(int bookingId) {
    if (_wsSubscription != null) return;

    final wsService = _ref.read(webSocketServiceProvider);
    final stream = wsService.notificationStream;
    
    _wsSubscription = stream.listen(
      (newNotification) {
        if (newNotification.bookingId == bookingId) {
          _handleNewNotification(newNotification);
        }
      },
      onError: (err) {
        _wsSubscription?.cancel();
        _wsSubscription = null;
        Future.delayed(const Duration(seconds: 5), () => _initWebSocketListener(bookingId));
      },
      onDone: () {
        _wsSubscription = null;
        Future.delayed(const Duration(seconds: 5), () => _initWebSocketListener(bookingId));
      },
    );
  }

  void _handleNewNotification(NotificationModel notification) {
    final updatedList = List<NotificationModel>.from(state.notifications);
    if (!updatedList.any((n) => n.id == notification.id)) {
      updatedList.insert(0, notification);
    }
    state = state.copyWith(
      notifications: updatedList,
      latestNotification: notification,
    );
  }

  Future<void> markAsRead(int id) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.markNotificationAsRead(id);
      
      final updatedList = state.notifications.map((n) {
        if (n.id == id) {
          return NotificationModel(
            id: n.id,
            bookingId: n.bookingId,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      
      state = state.copyWith(notifications: updatedList);
    } catch (_) {}
  }

  void clearLatestNotification() {
    state = state.copyWith(clearLatest: true);
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});
