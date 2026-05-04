import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// POST /api/community/posts/[postId]/like — toggle like
Future<Response> onRequest(RequestContext context, String postId) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  final id = int.tryParse(postId);
  if (id == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Post ID tidak valid'},
    );
  }

  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);
  final payload = token != null ? JwtHelper.verifyToken(token) : null;
  final userId = payload?['sub'] as int?;
  if (userId == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Autentikasi diperlukan'},
    );
  }

  final result = await CommunityService.toggleLike(id, userId);
  return Response.json(body: {'success': true, 'data': result});
}
