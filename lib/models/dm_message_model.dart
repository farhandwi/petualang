class DMMessageModel {
  final int id;
  final int? senderId;
  final String? senderName;
  final String? senderAvatar;
  final String type; // 'text' | 'image' | 'system'
  final String content;
  final String? imageUrl;
  final bool isRead;
  final bool isMe;
  final DateTime? createdAt;
  final bool isError;

  DMMessageModel({
    required this.id,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    this.imageUrl,
    this.isRead = false,
    required this.isMe,
    this.createdAt,
    this.isError = false,
  });

  factory DMMessageModel.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final sId = json['senderId'] ?? json['sender_id'];
    return DMMessageModel(
      id: json['id'] as int? ?? 0,
      senderId: sId as int?,
      senderName: json['senderName'] ?? json['sender_name'] as String?,
      senderAvatar: json['senderAvatar'] ?? json['sender_avatar'] as String?,
      type: json['messageType'] ?? json['type'] as String? ?? 'text',
      content: json['content'] as String? ?? json['error'] as String? ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'] as String?,
      isRead: json['isRead'] ?? json['is_read'] as bool? ?? false,
      isMe: currentUserId != null && sId == currentUserId,
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.tryParse((json['createdAt'] ?? json['created_at']) as String)
          : null,
      isError: json['error'] != null || json['type'] == 'error',
    );
  }

  factory DMMessageModel.optimistic({
    required int tempId,
    required int senderId,
    required String senderName,
    required String content,
    String type = 'text',
    String? imageUrl,
    String? senderAvatar,
  }) {
    return DMMessageModel(
      id: tempId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: type,
      content: content,
      imageUrl: imageUrl,
      isRead: false,
      isMe: true,
      createdAt: DateTime.now(),
    );
  }
}
