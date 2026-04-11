import 'mountain_model.dart';

class OpenTripModel {
  final int id;
  final int mountainId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final int maxParticipants;
  final int currentParticipants;
  final String status;
  final String? imageUrl;
  final DateTime createdAt;

  OpenTripModel({
    required this.id,
    required this.mountainId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.status,
    this.imageUrl,
    required this.createdAt,
  });

  factory OpenTripModel.fromJson(Map<String, dynamic> json) {
    return OpenTripModel(
      id: json['id'] as int,
      mountainId: json['mountain_id'] as int,
      title: json['title'] as String,
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      price: _parseDouble(json['price']),
      maxParticipants: json['max_participants'] as int,
      currentParticipants: json['current_participants'] as int,
      status: json['status'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ArticleModel {
  final int id;
  final String title;
  final String content;
  final String category;
  final String? imageUrl;
  final String? author;
  final DateTime createdAt;

  ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.imageUrl,
    this.author,
    required this.createdAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      imageUrl: json['image_url'] as String?,
      author: json['author'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ExploreDataResponse {
  final List<MountainModel> popularMountains;
  final List<OpenTripModel> openTrips;
  final List<ArticleModel> articles;

  ExploreDataResponse({
    required this.popularMountains,
    required this.openTrips,
    required this.articles,
  });

  factory ExploreDataResponse.fromJson(Map<String, dynamic> json) {
    final mounts = json['popular_mountains'] as List? ?? [];
    final trips = json['open_trips'] as List? ?? [];
    final arts = json['articles'] as List? ?? [];

    return ExploreDataResponse(
      popularMountains: mounts.map((m) => MountainModel.fromJson(m as Map<String, dynamic>)).toList(),
      openTrips: trips.map((t) => OpenTripModel.fromJson(t as Map<String, dynamic>)).toList(),
      articles: arts.map((a) => ArticleModel.fromJson(a as Map<String, dynamic>)).toList(),
    );
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
