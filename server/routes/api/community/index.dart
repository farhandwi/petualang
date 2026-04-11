import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET /api/community — list communities
/// POST /api/community — create community (auth required)
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);
  final payload = token != null ? JwtHelper.verifyToken(token) : null;
  final userId = payload?['sub'] as int?;

  if (context.request.method == HttpMethod.get) {
    final params = context.request.uri.queryParameters;
    final search = params['q'];
    final category = params['category'];
    final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
    final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

    final communities = await CommunityService.listCommunities(
      userId: userId,
      search: search,
      category: category,
      limit: limit,
      offset: offset,
    );
    return Response.json(body: {'success': true, 'data': communities});
  }

  if (context.request.method == HttpMethod.post) {
    if (userId == null) {
      return Response.json(
        statusCode: 401,
        body: {'success': false, 'message': 'Autentikasi diperlukan'},
      );
    }
    // TODO: create community endpoint (admin feature — skip for now)
    return Response.json(
      statusCode: 501,
      body: {'success': false, 'message': 'Belum tersedia'},
    );
  }

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}
