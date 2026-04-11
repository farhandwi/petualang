import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../models/chat_message_model.dart';

class ChatService {
  static const _timeout = Duration(seconds: 15);

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ─── REST ────────────────────────────────────────────────────

  Future<List<ChatMessageModel>> fetchMessages(
    int communityId,
    String token, {
    int limit = 50,
    int? beforeId,
    required int currentUserId,
  }) async {
    var url = '${AppConfig.chatMessages(communityId)}?limit=$limit';
    if (beforeId != null) url += '&before_id=$beforeId';

    final response = await http
        .get(Uri.parse(url), headers: _headers(token))
        .timeout(_timeout);

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['data'] as List<dynamic>)
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId))
        .toList();
  }

  Future<void> markAsRead(int communityId, String token) async {
    try {
      await http
          .post(Uri.parse(AppConfig.chatRead(communityId)), headers: _headers(token))
          .timeout(_timeout);
    } catch (_) {}
  }

  // ─── WebSocket ───────────────────────────────────────────────

  WebSocketChannel? connect(int communityId, String token) {
    try {
      final uri = Uri.parse(AppConfig.chatWsUrl(communityId, token));
      return WebSocketChannel.connect(uri);
    } catch (e) {
      print('WS connect error: $e');
      return null;
    }
  }
}
