import 'dart:convert';
import 'package:petualang_server/db/database.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DmService {
  static final Map<int, Set<_DmClient>> _rooms = {}; // Key: dm_conversation_id

  static Future<void> handleConnection({
    required int conversationId,
    required WebSocketChannel channel,
    required int userId,
    required String userName,
    required String? userAvatar,
  }) async {
    final client = _DmClient(
      channel: channel,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
    );

    _rooms.putIfAbsent(conversationId, () => {}).add(client);

    // Tell the client that they are connected
    client.channel.sink.add(json.encode({
      'type': 'system',
      'content': 'Connected to DM $conversationId',
    }));

    channel.stream.listen(
      (data) async {
        try {
          final msg = json.decode(data as String) as Map<String, dynamic>;
          final type = msg['type'] as String? ?? 'text';

          if (type == 'typing') {
            _broadcastToRoom(
              conversationId,
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
          
          if (type == 'read') {
             // User marked as read
             await markAsRead(conversationId, userId);
             _broadcastToRoom(
                conversationId,
                {
                  'type': 'read_receipt',
                  'userId': userId,
                },
                excludeUserId: userId,
             );
             return;
          }

          final content = (msg['content'] as String? ?? '').trim();
          final imageUrl = msg['imageUrl'] as String?;
          if (content.isEmpty && imageUrl == null) return;

          // Check block status before sending
          final isBlocked = await checkIfBlocked(conversationId, userId);
          if (isBlocked) {
             client.channel.sink.add(json.encode({
               'type': 'system',
               'error': 'Cannot send message. You have blocked or been blocked.',
             }));
             return;
          }

          // Save to DB
          final messageId = await _saveMessage(
            conversationId: conversationId,
            senderId: userId,
            type: imageUrl != null ? 'image' : 'text',
            content: content.isEmpty ? '' : content,
            imageUrl: imageUrl,
          );

          // Update conversation updated_at
          await updateConversationTimestamp(conversationId);

          // Broadcast
          _broadcastToRoom(
            conversationId,
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
              'isRead': false,
            },
            excludeUserId: null,
          );
        } catch (e) {
          print('DM message error: $e');
        }
      },
      onDone: () {
        _rooms[conversationId]?.remove(client);
        if (_rooms[conversationId]?.isEmpty ?? false) {
          _rooms.remove(conversationId);
        }
      },
      onError: (e) {
        _rooms[conversationId]?.remove(client);
      },
      cancelOnError: true,
    );
  }

  static void _broadcastToRoom(
    int conversationId,
    Map<String, dynamic> data, {
    required int? excludeUserId,
  }) {
    final encoded = json.encode(data);
    final clients = Set<_DmClient>.from(_rooms[conversationId] ?? {});
    for (final c in clients) {
      if (c.userId != excludeUserId) {
        try {
          c.channel.sink.add(encoded);
        } catch (_) {}
      }
    }
  }

  static Future<int> _saveMessage({
    required int conversationId,
    required int senderId,
    required String type,
    required String content,
    String? imageUrl,
  }) async {
    final conn = await Database.connection;
    final result = await conn.query(
      '''
      INSERT INTO dm_messages (dm_conversation_id, sender_id, type, content, image_url)
      VALUES (@conv, @sid, @type, @content, @img)
      RETURNING id
      ''',
      substitutionValues: {
        'conv': conversationId,
        'sid': senderId,
        'type': type,
        'content': content,
        'img': imageUrl,
      },
    );
    return result.first[0] as int;
  }

  static Future<void> updateConversationTimestamp(int conversationId) async {
    final conn = await Database.connection;
    await conn.execute(
       'UPDATE dm_conversations SET updated_at = NOW() WHERE id = @conv',
       substitutionValues: {'conv': conversationId},
    );
  }

  static Future<bool> checkIfBlocked(int conversationId, int senderId) async {
     final conn = await Database.connection;
     // Get users in this conv
     final convRes = await conn.query(
        'SELECT user1_id, user2_id FROM dm_conversations WHERE id = @cid',
        substitutionValues: {'cid': conversationId},
     );
     if (convRes.isEmpty) return true; // Invalid conv
     final u1 = convRes.first[0] as int;
     final u2 = convRes.first[1] as int;
     
     final otherUserId = (u1 == senderId) ? u2 : u1;

     // Check if sender blocked or is blocked by otherUser
     final blockRes = await conn.query('''
        SELECT 1 FROM dm_blocks 
        WHERE (blocker_id = @sid AND blocked_id = @oid)
           OR (blocker_id = @oid AND blocked_id = @sid)
        LIMIT 1
     ''', substitutionValues: {
        'sid': senderId,
        'oid': otherUserId,
     });

     return blockRes.isNotEmpty;
  }

  // REST helpers

  // Get or Create conversation
  static Future<int> getOrCreateConversation(int currentUserId, int targetUserId) async {
      final conn = await Database.connection;
      final u1 = currentUserId < targetUserId ? currentUserId : targetUserId;
      final u2 = currentUserId < targetUserId ? targetUserId : currentUserId;

      final res = await conn.query(
         'SELECT id FROM dm_conversations WHERE user1_id = @u1 AND user2_id = @u2',
         substitutionValues: {'u1': u1, 'u2': u2},
      );
      if (res.isNotEmpty) return res.first[0] as int;

      // Create new
      final insertRes = await conn.query(
         'INSERT INTO dm_conversations (user1_id, user2_id) VALUES (@u1, @u2) RETURNING id',
         substitutionValues: {'u1': u1, 'u2': u2},
      );
      return insertRes.first[0] as int;
  }

  static Future<List<Map<String, dynamic>>> getUserConversations(int userId) async {
      final conn = await Database.connection;
      final res = await conn.query('''
          SELECT c.id, c.updated_at,
                 u.id AS other_user_id, u.name as other_user_name, u.profile_picture as other_user_avatar,
                 m.content as last_message, m.type as last_message_type, m.created_at as last_message_time,
                 m.is_read as last_message_is_read, m.sender_id as last_message_sender,
                 (SELECT COUNT(*) FROM dm_messages um WHERE um.dm_conversation_id = c.id AND um.is_read = FALSE AND um.sender_id != @uid) as unread_count
          FROM dm_conversations c
          JOIN users u ON (u.id = CASE WHEN c.user1_id = @uid THEN c.user2_id ELSE c.user1_id END)
          LEFT JOIN LATERAL (
             SELECT content, type, created_at, is_read, sender_id 
             FROM dm_messages 
             WHERE dm_conversation_id = c.id 
             ORDER BY created_at DESC LIMIT 1
          ) m ON true
          WHERE c.user1_id = @uid OR c.user2_id = @uid
          ORDER BY c.updated_at DESC
      ''', substitutionValues: {'uid': userId});

      return res.map((r) => {
          'id': r[0],
          'updated_at': (r[1] as DateTime?)?.toIso8601String(),
          'other_user_id': r[2],
          'other_user_name': r[3],
          'other_user_avatar': r[4],
          'last_message': r[5],
          'last_message_type': r[6],
          'last_message_time': (r[7] as DateTime?)?.toIso8601String(),
          'last_message_is_read': r[8],
          'last_message_sender': r[9],
          'unread_count': r[10],
      }).toList();
  }

  static Future<List<Map<String, dynamic>>> getMessages(int conversationId, {int limit = 50, int? beforeId}) async {
      final conn = await Database.connection;
      final where = beforeId != null ? 'AND m.id < @beforeId' : '';
      final results = await conn.query('''
          SELECT m.id, m.sender_id, u.name, u.profile_picture, m.type, m.content, m.image_url, m.is_read, m.created_at
          FROM dm_messages m
          LEFT JOIN users u ON u.id = m.sender_id
          WHERE m.dm_conversation_id = @convId $where
          ORDER BY m.created_at DESC
          LIMIT @limit
      ''', substitutionValues: {
          'convId': conversationId,
          'limit': limit,
          if (beforeId != null) 'beforeId': beforeId,
      });

      return results.reversed.map((r) => {
          'id': r[0],
          'sender_id': r[1],
          'sender_name': r[2],
          'sender_avatar': r[3],
          'type': r[4],
          'content': r[5],
          'image_url': r[6],
          'is_read': r[7],
          'created_at': (r[8] as DateTime?)?.toIso8601String(),
      }).toList();
  }

  static Future<void> markAsRead(int conversationId, int userId) async {
       final conn = await Database.connection;
       await conn.execute('''
          UPDATE dm_messages 
          SET is_read = TRUE 
          WHERE dm_conversation_id = @cid AND sender_id != @uid AND is_read = FALSE
       ''', substitutionValues: {
          'cid': conversationId,
          'uid': userId,
       });
  }

  static Future<void> toggleBlockUser(int blockerId, int blockedId) async {
      final conn = await Database.connection;
      final check = await conn.query(
          'SELECT id FROM dm_blocks WHERE blocker_id = @bid AND blocked_id = @tid',
          substitutionValues: {'bid': blockerId, 'tid': blockedId}
      );

      if (check.isNotEmpty) {
          // Unblock
          await conn.execute(
             'DELETE FROM dm_blocks WHERE id = @id',
             substitutionValues: {'id': check.first[0]}
          );
      } else {
          // Block
          await conn.execute(
             'INSERT INTO dm_blocks (blocker_id, blocked_id) VALUES (@bid, @tid)',
             substitutionValues: {'bid': blockerId, 'tid': blockedId}
          );
      }
  }

  static Future<bool> isUserBlockedBy(int subjectId, int targetId) async {
      final conn = await Database.connection;
      final check = await conn.query(
          'SELECT id FROM dm_blocks WHERE blocker_id = @bid AND blocked_id = @tid',
          substitutionValues: {'bid': subjectId, 'tid': targetId}
      );
      return check.isNotEmpty;
  }
}

class _DmClient {
  final WebSocketChannel channel;
  final int userId;
  final String userName;
  final String? userAvatar;

  _DmClient({
    required this.channel,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  bool operator ==(Object other) =>
      other is _DmClient && other.userId == userId && other.channel == channel;

  @override
  int get hashCode => Object.hash(userId, channel);
}
