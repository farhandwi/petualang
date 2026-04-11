import 'dart:convert';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/jwt_helper.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Singleton room manager: Map<communityId, Set<_ChatClient>>
class ChatService {
  static final Map<int, Set<_ChatClient>> _rooms = {};

  static Future<void> handleConnection({
    required int communityId,
    required WebSocketChannel channel,
    required int userId,
    required String userName,
    required String? userAvatar,
  }) async {
    final client = _ChatClient(
      channel: channel,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
    );

    // Join room
    _rooms.putIfAbsent(communityId, () => {}).add(client);

    // Send system message: user joined
    _broadcastToRoom(
      communityId,
      {
        'type': 'system',
        'content': '$userName bergabung ke chat',
        'userId': userId,
        'createdAt': DateTime.now().toIso8601String(),
      },
      excludeUserId: null,
    );

    // Listen for messages
    channel.stream.listen(
      (data) async {
        try {
          final msg = json.decode(data as String) as Map<String, dynamic>;
          final type = msg['type'] as String? ?? 'text';

          if (type == 'typing') {
            // Do not save typing to DB — just broadcast
            _broadcastToRoom(
              communityId,
              {
                'type': 'typing',
                'userId': userId,
                'userName': userName,
                'isTyping': msg['isTyping'] ?? false,
              },
              excludeUserId: userId,
            );
            return;
          }

          final content = (msg['content'] as String? ?? '').trim();
          final imageUrl = msg['imageUrl'] as String?;
          if (content.isEmpty && imageUrl == null) return;

          // Save to DB
          final messageId = await _saveMessage(
            communityId: communityId,
            senderId: userId,
            type: imageUrl != null ? 'image' : 'text',
            content: content.isEmpty ? '' : content,
            imageUrl: imageUrl,
          );

          // Broadcast to all in room
          _broadcastToRoom(
            communityId,
            {
              'type': 'message',
              'id': messageId,
              'senderId': userId,
              'senderName': userName,
              'senderAvatar': userAvatar,
              'messageType': imageUrl != null ? 'image' : 'text',
              'content': content,
              'imageUrl': imageUrl,
              'createdAt': DateTime.now().toIso8601String(),
            },
            excludeUserId: null,
          );
        } catch (e) {
          print('Chat message error: $e');
        }
      },
      onDone: () {
        _rooms[communityId]?.remove(client);
        if (_rooms[communityId]?.isEmpty ?? false) {
          _rooms.remove(communityId);
        }
      },
      onError: (e) {
        _rooms[communityId]?.remove(client);
      },
      cancelOnError: true,
    );
  }

  static void _broadcastToRoom(
    int communityId,
    Map<String, dynamic> data, {
    required int? excludeUserId,
  }) {
    final encoded = json.encode(data);
    final clients = Set<_ChatClient>.from(_rooms[communityId] ?? {});
    for (final c in clients) {
      if (c.userId != excludeUserId) {
        try {
          c.channel.sink.add(encoded);
        } catch (_) {}
      }
    }
  }

  static Future<int> _saveMessage({
    required int communityId,
    required int senderId,
    required String type,
    required String content,
    String? imageUrl,
  }) async {
    final conn = await Database.connection;
    // Get conversation id
    final convResult = await conn.query(
      'SELECT id FROM chat_conversations WHERE community_id = @cid',
      substitutionValues: {'cid': communityId},
    );
    if (convResult.isEmpty) return -1;
    final convId = convResult.first[0] as int;

    final result = await conn.query(
      '''
      INSERT INTO chat_messages (conversation_id, sender_id, type, content, image_url)
      VALUES (@conv, @sid, @type, @content, @img)
      RETURNING id
      ''',
      substitutionValues: {
        'conv': convId,
        'sid': senderId,
        'type': type,
        'content': content,
        'img': imageUrl,
      },
    );
    return result.first[0] as int;
  }

  // ─── REST helpers ────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getConversationInfo(
    int communityId,
    int userId,
  ) async {
    final conn = await Database.connection;
    final result = await conn.query(
      '''
      SELECT cc.id,
             (SELECT COUNT(*) FROM chat_messages cm WHERE cm.conversation_id = cc.id
              AND cm.created_at > COALESCE(
                (SELECT last_read_at FROM chat_read_status WHERE conversation_id = cc.id AND user_id = @uid),
                '1970-01-01'::timestamptz
              ) AND cm.sender_id != @uid) AS unread_count
      FROM chat_conversations cc
      WHERE cc.community_id = @cid
      ''',
      substitutionValues: {'cid': communityId, 'uid': userId},
    );
    if (result.isEmpty) return null;
    return {'conversation_id': result.first[0], 'unread_count': result.first[1]};
  }

  static Future<List<Map<String, dynamic>>> getMessages(
    int communityId, {
    int limit = 50,
    int? beforeId,
  }) async {
    final conn = await Database.connection;
    final convResult = await conn.query(
      'SELECT id FROM chat_conversations WHERE community_id = @cid',
      substitutionValues: {'cid': communityId},
    );
    if (convResult.isEmpty) return [];
    final convId = convResult.first[0] as int;

    final where = beforeId != null ? 'AND cm.id < @beforeId' : '';
    final results = await conn.query(
      '''
      SELECT cm.id, cm.conversation_id, cm.sender_id,
             u.name AS sender_name, u.profile_picture AS sender_avatar,
             cm.type, cm.content, cm.image_url, cm.is_deleted, cm.created_at
      FROM chat_messages cm
      LEFT JOIN users u ON u.id = cm.sender_id
      WHERE cm.conversation_id = @convId $where
      ORDER BY cm.created_at DESC
      LIMIT @limit
      ''',
      substitutionValues: {
        'convId': convId,
        'limit': limit,
        if (beforeId != null) 'beforeId': beforeId,
      },
    );

    return results.reversed
        .map((r) => {
              'id': r[0],
              'conversation_id': r[1],
              'sender_id': r[2],
              'sender_name': r[3],
              'sender_avatar': r[4],
              'type': r[5],
              'content': r[6],
              'image_url': r[7],
              'is_deleted': r[8],
              'created_at': (r[9] as DateTime?)?.toIso8601String(),
            })
        .toList();
  }

  static Future<void> markAsRead(int communityId, int userId) async {
    final conn = await Database.connection;
    final convResult = await conn.query(
      'SELECT id FROM chat_conversations WHERE community_id = @cid',
      substitutionValues: {'cid': communityId},
    );
    if (convResult.isEmpty) return;
    final convId = convResult.first[0] as int;

    await conn.execute(
      '''
      INSERT INTO chat_read_status (conversation_id, user_id, last_read_at)
      VALUES (@cid, @uid, NOW())
      ON CONFLICT (conversation_id, user_id)
      DO UPDATE SET last_read_at = NOW()
      ''',
      substitutionValues: {'cid': convId, 'uid': userId},
    );
  }
}

class _ChatClient {
  final WebSocketChannel channel;
  final int userId;
  final String userName;
  final String? userAvatar;

  _ChatClient({
    required this.channel,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  bool operator ==(Object other) =>
      other is _ChatClient && other.userId == userId && other.channel == channel;

  @override
  int get hashCode => Object.hash(userId, channel);
}
