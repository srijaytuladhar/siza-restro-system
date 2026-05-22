import 'package:dio/dio.dart';
import '../models/booking_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';

class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: '${Constants.baseUrl}/api',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // TABLE / BOOKING API
  Future<BookingModel> scanAndBook(String qrCodeToken, String userId) async {
    try {
      final response = await _dio.post('/booking/scan', data: {
        'qrCodeToken': qrCodeToken,
        'userId': userId,
      });
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookingModel> getBooking(int bookingId) async {
    try {
      final response = await _dio.get('/booking/$bookingId');
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookingModel> closeBooking(int bookingId) async {
    try {
      final response = await _dio.put('/booking/$bookingId/close');
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // MENU API
  Future<List<MenuItemModel>> getMenu() async {
    try {
      final response = await _dio.get('/menu');
      final list = response.data as List? ?? [];
      return list.map((item) => MenuItemModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ORDER API
  Future<OrderModel> placeOrder(int bookingId, List<Map<String, dynamic>> items) async {
    try {
      final response = await _dio.post('/order', data: {
        'bookingId': bookingId,
        'items': items, // List of {menuItemId, quantity}
      });
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<OrderModel> getOrder(int orderId) async {
    try {
      final response = await _dio.get('/order/$orderId');
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<OrderModel>> getOrdersByBooking(int bookingId) async {
    try {
      final response = await _dio.get('/order/booking/$bookingId');
      final list = response.data as List? ?? [];
      return list.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // MOCK KITCHEN STATUS UPDATE
  Future<OrderModel> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await _dio.put('/order/$orderId/status', data: {
        'status': status,
      });
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PAYMENT API
  Future<PaymentModel> processPayment(int orderId, String paymentMethod, double amount) async {
    try {
      final response = await _dio.post('/payment', data: {
        'orderId': orderId,
        'paymentMethod': paymentMethod,
        'amount': amount,
      });
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PaymentModel> getPayment(int orderId) async {
    try {
      final response = await _dio.get('/payment/order/$orderId');
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // NOTIFICATION API
  Future<List<NotificationModel>> getNotifications(int bookingId) async {
    try {
      final response = await _dio.get('/notification/booking/$bookingId');
      final list = response.data as List? ?? [];
      return list.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    try {
      await _dio.put('/notification/$id/read');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null && error.response?.data != null) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      }
    }
    return error.message ?? 'Unknown connection error';
  }
}
