import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';

/// GET /api/community/trending
/// Mengembalikan hingga 10 komunitas dengan postingan terbanyak dalam 24 jam terakhir.
/// Endpoint publik — tidak memerlukan autentikasi.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  final params = context.request.uri.queryParameters;
  final limit = (int.tryParse(params['limit'] ?? '10') ?? 10).clamp(1, 10);

  try {
    final communities = await CommunityService.getTopCommunitiesByPosts24h(
      limit: limit,
    );

    return Response.json(body: {
      'success': true,
      'data': communities,
      'meta': {
        'count': communities.length,
        'window_hours': 24,
      },
    });
  } catch (e) {
    print('[trending.dart] ERROR: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Gagal mengambil data trending'},
    );
  }
}
