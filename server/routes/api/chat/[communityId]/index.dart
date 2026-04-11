import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/chat_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET /api/chat/[communityId] — info conversation + unread count
Future<Response> onRequest(RequestContext context, String communityId) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

  final cid = int.tryParse(communityId);
  if (cid == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'ID tidak valid'});
  }

  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);
  final payload = token != null ? JwtHelper.verifyToken(token) : null;
  final userId = payload?['sub'] as int?;

  if (userId == null) {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Autentikasi diperlukan'});
  }

  final info = await ChatService.getConversationInfo(cid, userId);
  if (info == null) {
    return Response.json(statusCode: 404, body: {'success': false, 'message': 'Percakapan tidak ditemukan'});
  }

  return Response.json(body: {'success': true, 'data': info});
}
