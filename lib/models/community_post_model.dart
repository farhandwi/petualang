class CommunityPostModel {
  final int id;
  final int communityId;
  final int userId;
  final String authorName;
  final String? authorAvatar;
  final int authorLevel;
  final String content;
  final String? imageUrl;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isPinned;
  final bool isLiked;
  final String? communityName;
  final DateTime? createdAt;

  CommunityPostModel({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.authorName,
    this.authorAvatar,
    this.authorLevel = 1,
    required this.content,
    this.imageUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isPinned = false,
    this.isLiked = false,
    this.communityName,
    this.createdAt,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id'] as int,
      communityId: json['community_id'] as int,
      userId: json['user_id'] as int,
      authorName: (json['author_name'] as String?) ?? '',
      authorAvatar: json['author_avatar'] as String?,
      authorLevel: json['author_level'] as int? ?? 1,
      content: (json['content'] as String?) ?? '',
      imageUrl: json['image_url'] as String?,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      shareCount: json['share_count'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      isLiked: json['is_liked'] as bool? ?? false,
      communityName: json['community_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  CommunityPostModel copyWith({
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isLiked,
  }) {
    return CommunityPostModel(
      id: id,
      communityId: communityId,
      userId: userId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorLevel: authorLevel,
      content: content,
      imageUrl: imageUrl,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isPinned: isPinned,
      isLiked: isLiked ?? this.isLiked,
      communityName: communityName,
      createdAt: createdAt,
    );
  }
}
