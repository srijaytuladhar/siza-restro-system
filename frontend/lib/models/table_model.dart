enum TableStatus {
  AVAILABLE,
  BOOKED,
}

class TableModel {
  final int id;
  final String tableNumber;
  final TableStatus status;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.status,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] as int,
      tableNumber: json['tableNumber'] as String? ?? '',
      status: json['status'] == 'BOOKED' ? TableStatus.BOOKED : TableStatus.AVAILABLE,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'status': status.name,
    };
  }
}
