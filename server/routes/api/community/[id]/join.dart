import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// POST /api/community/[id]/join — join komunitas
/// DELETE /api/community/[id]/join — leave komunitas
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

  final communityId = int.tryParse(id);
  if (communityId == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'ID tidak valid'});
  }

  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);
  final payload = token != null ? JwtHelper.verifyToken(token) : null;
  final userId = payload?['sub'] as int?;

  if (userId == null) {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Autentikasi diperlukan'});
  }

  if (context.request.method == HttpMethod.post) {
    await CommunityService.joinCommunity(communityId, userId);
    return Response.json(body: {'success': true, 'message': 'Berhasil bergabung ke komunitas'});
  }

  if (context.request.method == HttpMethod.delete) {
    await CommunityService.leaveCommunity(communityId, userId);
    return Response.json(body: {'success': true, 'message': 'Berhasil keluar dari komunitas'});
  }

  return Response.json(statusCode: 405, body: {'success': false, 'message': 'Method not allowed'});
}
