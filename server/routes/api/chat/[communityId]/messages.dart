import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/chat_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET /api/chat/[communityId]/messages — riwayat pesan
Future<Response> onRequest(RequestContext context, String communityId) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: 405, body: {'success': false, 'message': 'Method not allowed'});
  }

  final cid = int.tryParse(communityId);
  if (cid == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'ID tidak valid'});
  }

  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);
  final payload = token != null ? JwtHelper.verifyToken(token) : null;
  if (payload == null) {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Autentikasi diperlukan'});
  }

  final params = context.request.uri.queryParameters;
  final limit = int.tryParse(params['limit'] ?? '50') ?? 50;
  final beforeId = int.tryParse(params['before_id'] ?? '');

  final messages = await ChatService.getMessages(cid, limit: limit, beforeId: beforeId);
  return Response.json(body: {'success': true, 'data': messages});
}
