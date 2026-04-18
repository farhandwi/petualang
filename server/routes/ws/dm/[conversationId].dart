import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:petualang_server/services/dm_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// WebSocket: ws://host:8080/ws/dm/[conversationId]?token=JWT
Future<Response> onRequest(RequestContext context, String conversationId) async {
  final handler = webSocketHandler((channel, protocol) async {
    final cid = int.tryParse(conversationId);
    if (cid == null) {
      channel.sink.add('{"type":"error","message":"Invalid conversation ID"}');
      await channel.sink.close();
      return;
    }

    // Authenticate via query param
    final token = context.request.uri.queryParameters['token'];
    if (token == null) {
      channel.sink.add('{"type":"error","message":"Token tidak ditemukan"}');
      await channel.sink.close();
      return;
    }

    final payload = JwtHelper.verifyToken(token);
    if (payload == null) {
      channel.sink.add('{"type":"error","message":"Token tidak valid"}');
      await channel.sink.close();
      return;
    }

    final userId = payload['sub'] as int;
    final userName = payload['name'] as String? ?? 'User';
    final userAvatar = payload['avatar'] as String?;

    await DmService.handleConnection(
      conversationId: cid,
      channel: channel,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
    );
  });

  return handler(context);
}
