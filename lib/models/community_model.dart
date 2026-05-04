class CommunityModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? coverImageUrl;
  final String? iconImageUrl;
  final String? category;
  final String? location;
  final String privacy;
  final int memberCount;
  final int postCount;
  final int onlineCount;
  final int eventCount;
  final double rating;
  final int reviewCount;
  final bool isMember;
  final String? myRole;
  final int? createdBy;
  final DateTime? createdAt;

  bool isOwnedBy(int? userId) =>
      userId != null && createdBy != null && createdBy == userId;

  CommunityModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.coverImageUrl,
    this.iconImageUrl,
    this.category,
    this.location,
    required this.privacy,
    required this.memberCount,
    required this.postCount,
    this.onlineCount = 0,
    this.eventCount = 0,
    this.rating = 0,
    this.reviewCount = 0,
    required this.isMember,
    this.myRole,
    this.createdBy,
    this.createdAt,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    final ratingRaw = json['rating'];
    return CommunityModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      iconImageUrl: json['icon_image_url'] as String?,
      category: json['category'] as String?,
      location: json['location'] as String?,
      privacy: json['privacy'] as String? ?? 'public',
      memberCount: json['member_count'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
      onlineCount: json['online_count'] as int? ?? 0,
      eventCount: json['event_count'] as int? ?? 0,
      rating: ratingRaw is num
          ? ratingRaw.toDouble()
          : double.tryParse('${ratingRaw ?? 0}') ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      isMember: json['is_member'] as bool? ?? false,
      myRole: json['my_role'] as String?,
      createdBy: json['created_by'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'cover_image_url': coverImageUrl,
        'icon_image_url': iconImageUrl,
        'category': category,
        'location': location,
        'privacy': privacy,
        'member_count': memberCount,
        'post_count': postCount,
        'online_count': onlineCount,
        'event_count': eventCount,
        'rating': rating,
        'review_count': reviewCount,
        'is_member': isMember,
        'my_role': myRole,
        'created_by': createdBy,
        'created_at': createdAt?.toIso8601String(),
      };

  CommunityModel copyWith({
    bool? isMember,
    int? memberCount,
    int? onlineCount,
    int? eventCount,
    double? rating,
    int? reviewCount,
    String? myRole,
  }) {
    return CommunityModel(
      id: id,
      name: name,
      slug: slug,
      description: description,
      coverImageUrl: coverImageUrl,
      iconImageUrl: iconImageUrl,
      category: category,
      location: location,
      privacy: privacy,
      memberCount: memberCount ?? this.memberCount,
      postCount: postCount,
      onlineCount: onlineCount ?? this.onlineCount,
      eventCount: eventCount ?? this.eventCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isMember: isMember ?? this.isMember,
      myRole: myRole ?? this.myRole,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
