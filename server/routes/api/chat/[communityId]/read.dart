import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/chat_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// POST /api/chat/[communityId]/read — mark messages as read
Future<Response> onRequest(RequestContext context, String communityId) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'success': false, 'message': 'Method not allowed'});
  }

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

  await ChatService.markAsRead(cid, userId);
  return Response.json(body: {'success': true, 'message': 'Pesan ditandai sudah dibaca'});
}
