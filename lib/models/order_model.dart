class OrderModel {
  final String type; // 'ticket' or 'rental'
  final int id;
  final String code;
  final String title;
  final double totalPrice;
  final String status;
  final DateTime? date;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  OrderModel({
    required this.type,
    required this.id,
    required this.code,
    required this.title,
    required this.totalPrice,
    required this.status,
    this.date,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      type: json['type'] ?? '',
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  // Helper method for display
  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'success':
      case 'confirmed':
        return 'Selesai';
      case 'pending':
        return 'Pending';
      case 'cancelled':
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'active':
      case 'aktif':
        return 'Aktif';
      default:
        // Use backend status but capitalize first letter
        if (status.isEmpty) return 'Aktif';
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  String get mappedTabStatus {
    switch (status.toLowerCase()) {
      case 'success':
      case 'confirmed':
        return 'Selesai';
      case 'pending':
        return 'Pending';
      case 'cancelled':
      case 'dibatalkan':
      case 'failed':
        return 'Dibatalkan';
      default:
        return 'Aktif'; // Default active if unmapped
    }
  }
}
