import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../models/dm_conversation_model.dart';
import '../models/dm_message_model.dart';

class DmApiService {
  static const _timeout = Duration(seconds: 15);

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<DMConversationModel>> fetchConversations(String token) async {
    final response = await http
        .get(Uri.parse(AppConfig.dmConversations()), headers: _headers(token))
        .timeout(_timeout);

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['conversations'] as List<dynamic>)
        .map((e) => DMConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int?> createOrGetConversation(String token, int targetUserId) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.dmConversations()),
            headers: _headers(token),
            body: json.encode({'target_user_id': targetUserId}),
          )
          .timeout(_timeout);

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return data['conversation_id'] as int;
      }
    } catch (_) {}
    return null;
  }

  Future<List<DMMessageModel>> fetchMessages(
    int conversationId,
    String token, {
    int limit = 50,
    int? beforeId,
    required int currentUserId,
  }) async {
    var url = '${AppConfig.dmMessages(conversationId)}?limit=$limit';
    if (beforeId != null) url += '&before_id=$beforeId';

    final response = await http
        .get(Uri.parse(url), headers: _headers(token))
        .timeout(_timeout);

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['messages'] as List<dynamic>)
        .map((e) => DMMessageModel.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId))
        .toList();
  }

  Future<List<dynamic>> searchUsers(String token, String query) async {
    final response = await http
        .get(Uri.parse(AppConfig.dmSearchUsers(query)), headers: _headers(token))
        .timeout(_timeout);

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return data['users'] as List<dynamic>;
  }

  Future<bool> toggleBlockUser(String token, int targetUserId) async {
    final response = await http
        .post(Uri.parse(AppConfig.dmBlock(targetUserId)), headers: _headers(token))
        .timeout(_timeout);

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['is_blocked'] as bool;
    }
    throw Exception('Failed to block/unblock user');
  }

  Future<String?> uploadImage(dynamic imageFile, String token) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.uploadImageEndpoint),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', (imageFile as File).path));
      final streamed = await request.send().timeout(_timeout);
      final body = await streamed.stream.bytesToString();
      final data = json.decode(body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return data['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  // ─── WebSocket ───────────────────────────────────────────────

  WebSocketChannel? connect(int conversationId, String token) {
    try {
      final uri = Uri.parse(AppConfig.dmWsUrl(conversationId, token));
      return WebSocketChannel.connect(uri);
    } catch (e) {
      print('DM WS connect error: $e');
      return null;
    }
  }
}
