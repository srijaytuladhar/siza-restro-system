enum OrderStatus {
  PENDING,
  PREPARING,
  READY,
  SERVED,
}

class OrderItemModel {
  final int id;
  final int menuItemId;
  final String menuItemName;
  final double price;
  final int quantity;

  OrderItemModel({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int? ?? 0,
      menuItemId: json['menuItemId'] as int,
      menuItemName: json['menuItemName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'menuItemName': menuItemName,
      'price': price,
      'quantity': quantity,
    };
  }
}
class OrderModel {
  final int id;
  final int bookingId;
  final String tableNumber;
  final OrderStatus status;
  final double totalAmount;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final String paymentStatus;
  final String? paymentMethod;

  OrderModel({
    required this.id,
    required this.bookingId,
    required this.tableNumber,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
    required this.paymentStatus,
    this.paymentMethod,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<OrderItemModel> itemList = list.map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>)).toList();

    return OrderModel(
      id: json['id'] as int,
      bookingId: json['bookingId'] as int,
      tableNumber: json['tableNumber'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
      items: itemList,
      paymentStatus: json['paymentStatus'] as String? ?? 'PENDING',
      paymentMethod: json['paymentMethod'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'tableNumber': tableNumber,
      'status': status.name,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
    };
  }

  static OrderStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'WAITING':
      case 'ACCEPTED':
      case 'PENDING':
        return OrderStatus.PENDING;
      case 'PREPARING':
        return OrderStatus.PREPARING;
      case 'READY':
        return OrderStatus.READY;
      case 'SERVED':
        return OrderStatus.SERVED;
      default:
        return OrderStatus.PENDING;
    }
  }

  String get statusDisplay {
    switch (status) {
      case OrderStatus.PENDING:
        return 'Order Received';
      case OrderStatus.PREPARING:
        return 'Preparing in Kitchen';
      case OrderStatus.READY:
        return 'Ready to Serve';
      case OrderStatus.SERVED:
        return 'Served';
    }
  }
}
