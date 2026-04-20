class ChatMessageModel {
  final int id;
  final int conversationId;
  final int? senderId;
  final String? senderName;
  final String? senderAvatar;
  final int senderLevel;
  final String type; // 'text' | 'image' | 'system'
  final String content;
  final String? imageUrl;
  final bool isDeleted;
  final bool isMe;
  final DateTime? createdAt;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.senderLevel = 1,
    required this.type,
    required this.content,
    this.imageUrl,
    required this.isDeleted,
    required this.isMe,
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final senderId = json['sender_id'] as int?;
    return ChatMessageModel(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      senderId: senderId,
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      senderLevel: json['sender_level'] as int? ?? 1,
      type: json['type'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      isMe: currentUserId != null && senderId == currentUserId,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Create an optimistic local message before server confirms
  factory ChatMessageModel.optimistic({
    required int tempId,
    required int conversationId,
    required int senderId,
    required String senderName,
    required String content,
    String type = 'text',
    String? imageUrl,
    String? senderAvatar,
    int senderLevel = 1,
  }) {
    return ChatMessageModel(
      id: tempId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      senderLevel: senderLevel,
      type: type,
      content: content,
      imageUrl: imageUrl,
      isDeleted: false,
      isMe: true,
      createdAt: DateTime.now(),
    );
  }
}
