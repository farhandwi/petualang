class DMConversationModel {
  final int id;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final int otherUserLevel;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageTime;
  final bool lastMessageIsRead;
  final int? lastMessageSender;
  final int unreadCount;
  final DateTime? updatedAt;

  DMConversationModel({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.otherUserLevel = 1,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageTime,
    this.lastMessageIsRead = true,
    this.lastMessageSender,
    this.unreadCount = 0,
    this.updatedAt,
  });

  factory DMConversationModel.fromJson(Map<String, dynamic> json) {
    return DMConversationModel(
      id: json['id'] as int,
      otherUserId: json['other_user_id'] as int,
      otherUserName: json['other_user_name'] as String,
      otherUserAvatar: json['other_user_avatar'] as String?,
      otherUserLevel: json['other_user_level'] as int? ?? 1,
      lastMessage: json['last_message'] as String?,
      lastMessageType: json['last_message_type'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.tryParse(json['last_message_time'] as String)
          : null,
      lastMessageIsRead: json['last_message_is_read'] as bool? ?? true,
      lastMessageSender: json['last_message_sender'] as int?,
      unreadCount: json['unread_count'] as int? ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
