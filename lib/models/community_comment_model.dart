class CommunityCommentModel {
  final int id;
  final int postId;
  final int userId;
  final int? parentId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final String? imageUrl;
  final int likeCount;
  final List<CommunityCommentModel> replies;
  final DateTime? createdAt;

  CommunityCommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.imageUrl,
    required this.likeCount,
    required this.replies,
    this.createdAt,
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    final repliesJson = json['replies'] as List<dynamic>? ?? [];
    return CommunityCommentModel(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      userId: json['user_id'] as int,
      parentId: json['parent_id'] as int?,
      authorName: json['author_name'] as String? ?? 'Unknown',
      authorAvatar: json['author_avatar'] as String?,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      likeCount: json['like_count'] as int? ?? 0,
      replies: repliesJson
          .map((r) => CommunityCommentModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
