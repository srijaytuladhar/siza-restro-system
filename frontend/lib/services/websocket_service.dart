import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/order_model.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';

class WebSocketService {
  StompClient? _stompClient;
  StreamController<OrderModel>? _orderController;
  StreamController<NotificationModel>? _notificationController;

  Stream<OrderModel> get orderStream => _orderController?.stream ?? const Stream.empty();
  Stream<NotificationModel> get notificationStream => _notificationController?.stream ?? const Stream.empty();

  void connect(int bookingId) {
    close();
    _orderController = StreamController<OrderModel>.broadcast();
    _notificationController = StreamController<NotificationModel>.broadcast();

    _stompClient = StompClient(
      config: StompConfig(
        url: Constants.wsUrl,
        onConnect: (StompFrame frame) {
          // Subscribe to booking order updates
          _stompClient?.subscribe(
            destination: '/topic/booking/$bookingId',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                try {
                  final decoded = jsonDecode(frame.body!) as Map<String, dynamic>;
                  final order = OrderModel.fromJson(decoded);
                  _orderController?.add(order);
                } catch (_) {}
              }
            },
          );

          // Subscribe to booking notifications
          _stompClient?.subscribe(
            destination: '/topic/booking/$bookingId/notifications',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                try {
                  final decoded = jsonDecode(frame.body!) as Map<String, dynamic>;
                  final notification = NotificationModel.fromJson(decoded);
                  _notificationController?.add(notification);
                } catch (_) {}
              }
            },
          );
        },
        onWebSocketError: (dynamic error) {
          _orderController?.addError(error);
          _notificationController?.addError(error);
        },
        onStompError: (StompFrame frame) {
          _orderController?.addError(frame);
          _notificationController?.addError(frame);
        },
      ),
    );

    _stompClient?.activate();
  }

  void close() {
    try {
      _stompClient?.deactivate();
    } catch (_) {}
    _stompClient = null;
    
    try {
      _orderController?.close();
    } catch (_) {}
    _orderController = null;

    try {
      _notificationController?.close();
    } catch (_) {}
    _notificationController = null;
  }
}
