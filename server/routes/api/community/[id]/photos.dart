import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';

/// GET /api/community/[id]/photos — galeri (image_url dari community_posts)
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  final communityId = int.tryParse(id);
  if (communityId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID tidak valid'},
    );
  }

  final params = context.request.uri.queryParameters;
  final limit = int.tryParse(params['limit'] ?? '60') ?? 60;
  final photos = await CommunityService.getPhotos(communityId, limit: limit);
  return Response.json(body: {'success': true, 'data': photos});
}
