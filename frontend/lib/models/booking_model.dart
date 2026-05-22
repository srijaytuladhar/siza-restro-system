enum BookingStatus {
  ACTIVE,
  CLOSED,
}

class BookingModel {
  final int id;
  final int tableId;
  final String tableNumber;
  final String userId;
  final BookingStatus status;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.userId,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int,
      tableId: json['tableId'] as int,
      tableNumber: json['tableNumber'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      status: json['status'] == 'CLOSED' ? BookingStatus.CLOSED : BookingStatus.ACTIVE,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'userId': userId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
