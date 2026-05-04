class CommunityEventModel {
  final int id;
  final String title;
  final String? description;
  final String? location;
  final DateTime? eventDate;
  final String? imageUrl;
  final int? maxParticipants;
  final int currentParticipants;
  final String status;

  CommunityEventModel({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.eventDate,
    this.imageUrl,
    this.maxParticipants,
    this.currentParticipants = 0,
    this.status = 'open',
  });

  factory CommunityEventModel.fromJson(Map<String, dynamic> json) {
    return CommunityEventModel(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      eventDate: json['event_date'] != null
          ? DateTime.tryParse(json['event_date'] as String)
          : null,
      imageUrl: json['image_url'] as String?,
      maxParticipants: json['max_participants'] as int?,
      currentParticipants: json['current_participants'] as int? ?? 0,
      status: (json['status'] as String?) ?? 'open',
    );
  }
}
