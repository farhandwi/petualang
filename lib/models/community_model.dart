class CommunityModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? coverImageUrl;
  final String? iconImageUrl;
  final String? category;
  final String privacy;
  final int memberCount;
  final int postCount;
  final bool isMember;
  final DateTime? createdAt;

  CommunityModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.coverImageUrl,
    this.iconImageUrl,
    this.category,
    required this.privacy,
    required this.memberCount,
    required this.postCount,
    required this.isMember,
    this.createdAt,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      iconImageUrl: json['icon_image_url'] as String?,
      category: json['category'] as String?,
      privacy: json['privacy'] as String? ?? 'public',
      memberCount: json['member_count'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
      isMember: json['is_member'] as bool? ?? false,
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
        'privacy': privacy,
        'member_count': memberCount,
        'post_count': postCount,
        'is_member': isMember,
        'created_at': createdAt?.toIso8601String(),
      };

  CommunityModel copyWith({bool? isMember, int? memberCount}) {
    return CommunityModel(
      id: id,
      name: name,
      slug: slug,
      description: description,
      coverImageUrl: coverImageUrl,
      iconImageUrl: iconImageUrl,
      category: category,
      privacy: privacy,
      memberCount: memberCount ?? this.memberCount,
      postCount: postCount,
      isMember: isMember ?? this.isMember,
      createdAt: createdAt,
    );
  }
}
