/// User's upcoming booking (mountain ticket) untuk section Trip Mendatang di home.
class UpcomingBookingModel {
  final int id;
  final String bookingCode;
  final DateTime date;
  final int climbersCount;
  final double totalPrice;
  final String status;
  final int? mountainId;
  final String? mountainName;
  final String? mountainLocation;
  final String? mountainImage;
  final int? mountainElevation;

  UpcomingBookingModel({
    required this.id,
    required this.bookingCode,
    required this.date,
    required this.climbersCount,
    required this.totalPrice,
    required this.status,
    this.mountainId,
    this.mountainName,
    this.mountainLocation,
    this.mountainImage,
    this.mountainElevation,
  });

  int get daysUntil {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    return d.difference(today).inDays;
  }

  factory UpcomingBookingModel.fromJson(Map<String, dynamic> json) {
    return UpcomingBookingModel(
      id: json['id'] as int,
      bookingCode: json['booking_code'] as String,
      date: DateTime.parse(json['date'] as String),
      climbersCount: json['climbers_count'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
      mountainId: json['mountain_id'] as int?,
      mountainName: json['mountain_name'] as String?,
      mountainLocation: json['mountain_location'] as String?,
      mountainImage: json['mountain_image'] as String?,
      mountainElevation: json['mountain_elevation'] as int?,
    );
  }
}
