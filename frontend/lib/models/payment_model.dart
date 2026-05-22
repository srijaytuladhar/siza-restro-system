enum PaymentMethod {
  CASH,
  DIGITAL_WALLET,
}

enum PaymentStatus {
  PENDING,
  PAID,
}

class PaymentModel {
  final int id;
  final int orderId;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final double amount;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.status,
    required this.amount,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int? ?? 0,
      orderId: json['orderId'] as int? ?? 0,
      paymentMethod: json['paymentMethod'] == 'DIGITAL_WALLET' ? PaymentMethod.DIGITAL_WALLET : PaymentMethod.CASH,
      status: json['status'] == 'PAID' ? PaymentStatus.PAID : PaymentStatus.PENDING,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
