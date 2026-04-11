import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET /api/community/feed — global feed dari komunitas yang diikuti
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

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

  final params = context.request.uri.queryParameters;
  final limit = int.tryParse(params['limit'] ?? '30') ?? 30;
  final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

  final posts = await CommunityService.getGlobalFeed(userId, limit: limit, offset: offset);
  return Response.json(body: {'success': true, 'data': posts});
}
