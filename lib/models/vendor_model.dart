class VendorModel {
  final int id;
  final String name;
  final String address;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final String? imageUrl;
  final double? distance;
  final List<String> categories;

  VendorModel({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    this.imageUrl,
    this.distance,
    this.categories = const [],
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    // Defensive parsing — PostgreSQL may return int, String, or num
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final rawReviewCount = json['review_count'];
    final reviewCount = rawReviewCount is int
        ? rawReviewCount
        : int.tryParse(rawReviewCount?.toString() ?? '') ?? 0;

    // categories comes as List<dynamic> from JSON array
    List<String> categories = [];
    final rawCats = json['categories'];
    if (rawCats is List) {
      categories = rawCats
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    }

    return VendorModel(
      id: id,
      name: json['name']?.toString() ?? 'Unknown',
      address: json['address']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: reviewCount,
      isOpen: json['is_open'] as bool? ?? true,
      imageUrl: json['image_url']?.toString(),
      distance: (json['distance'] as num?)?.toDouble(),
      categories: categories,
    );
  }
}
