class CommunityPostModel {
  final int id;
  final int communityId;
  final int userId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final String? imageUrl;
  final String? communityName;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isPinned;
  final DateTime? createdAt;

  CommunityPostModel({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.imageUrl,
    this.communityName,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.isPinned,
    this.createdAt,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      communityId: (json['community_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      authorName: json['author_name'] as String? ?? 'Petualang',
      authorAvatar: json['author_avatar'] as String?,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      communityName: json['community_name'] as String?,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  CommunityPostModel copyWith({bool? isLiked, int? likeCount, int? commentCount}) {
    return CommunityPostModel(
      id: id,
      communityId: communityId,
      userId: userId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: content,
      imageUrl: imageUrl,
      communityName: communityName,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isPinned: isPinned,
      createdAt: createdAt,
    );
  }
}
