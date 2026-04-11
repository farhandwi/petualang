class TicketModel {
  final int id;
  final String bookingCode;
  final String status;
  final DateTime createdAt;

  TicketModel({
    required this.id,
    required this.bookingCode,
    required this.status,
    required this.createdAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as int,
      bookingCode: json['booking_code'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
