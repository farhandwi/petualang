import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';

/// GET /api/community/[id]/members
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

  final communityId = int.tryParse(id);
  if (communityId == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'ID tidak valid'});
  }

  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: 405, body: {'success': false, 'message': 'Method not allowed'});
  }

  final params = context.request.uri.queryParameters;
  final limit = int.tryParse(params['limit'] ?? '30') ?? 30;
  final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

  final members = await CommunityService.getMembersWithOnline(
    communityId,
    limit: limit,
    offset: offset,
  );
  return Response.json(body: {'success': true, 'data': members});
}
