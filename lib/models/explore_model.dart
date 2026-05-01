import 'mountain_model.dart';
import 'vendor_model.dart';

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
  final int viewCount;
  final int likesCount;
  final int commentsCount;
  final int shareCount;
  final DateTime createdAt;

  ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.imageUrl,
    this.author,
    this.viewCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.shareCount = 0,
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
      viewCount: json['view_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      shareCount: json['share_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ExploreDataResponse {
  final MountainModel? featuredMountain;
  final List<MountainModel> popularMountains;
  final List<OpenTripModel> heroCarousel;
  final List<OpenTripModel> upcomingTrips;
  final List<OpenTripModel> openTrips;
  final List<ArticleModel> articles;
  final List<VendorModel> topVendors;

  ExploreDataResponse({
    this.featuredMountain,
    required this.popularMountains,
    required this.heroCarousel,
    required this.upcomingTrips,
    required this.openTrips,
    required this.articles,
    required this.topVendors,
  });

  factory ExploreDataResponse.fromJson(Map<String, dynamic> json) {
    final featured = json['featured_mountain'] as Map<String, dynamic>?;
    final mounts = json['popular_mountains'] as List? ?? [];
    final hero = json['hero_carousel'] as List? ?? [];
    final upcoming = json['upcoming_trips'] as List? ?? [];
    final trips = json['open_trips'] as List? ?? [];
    final arts = json['articles'] as List? ?? [];
    final vendors = json['top_vendors'] as List? ?? [];

    List<OpenTripModel> parseTrips(List src) =>
        src.map((t) => OpenTripModel.fromJson(t as Map<String, dynamic>)).toList();

    return ExploreDataResponse(
      featuredMountain:
          featured != null ? MountainModel.fromJson(featured) : null,
      popularMountains: mounts.map((m) => MountainModel.fromJson(m as Map<String, dynamic>)).toList(),
      heroCarousel: parseTrips(hero),
      upcomingTrips: parseTrips(upcoming),
      openTrips: parseTrips(trips),
      articles: arts.map((a) => ArticleModel.fromJson(a as Map<String, dynamic>)).toList(),
      topVendors: vendors
          .map((v) => VendorModel.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
