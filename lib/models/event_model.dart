class EventModel {
  final int id;
  final String title;
  final String? description;
  final String? location;
  final DateTime eventDate;
  final String? imageUrl;
  final int? organizerId;
  final String? organizerName;
  final String? organizerPicture;
  final int? maxParticipants;
  final int currentParticipants;
  final String status;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.eventDate,
    this.imageUrl,
    this.organizerId,
    this.organizerName,
    this.organizerPicture,
    this.maxParticipants,
    this.currentParticipants = 0,
    this.status = 'open',
    required this.createdAt,
  });

  /// Selisih hari dari sekarang ke event_date (negatif = sudah lewat).
  int get daysUntil {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    return eventDay.difference(today).inDays;
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String),
      imageUrl: json['image_url'] as String?,
      organizerId: json['organizer_id'] as int?,
      organizerName: json['organizer_name'] as String?,
      organizerPicture: json['organizer_picture'] as String?,
      maxParticipants: json['max_participants'] as int?,
      currentParticipants: json['current_participants'] as int? ?? 0,
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
