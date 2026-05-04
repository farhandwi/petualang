import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET /api/community — list communities
/// POST /api/community — create community (auth required, JSON body)
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
    final totalMembers = await CommunityService.getTotalMembersAcrossCommunities();
    return Response.json(body: {
      'success': true,
      'data': communities,
      'meta': {'total_members': totalMembers},
    });
  }

  if (context.request.method == HttpMethod.post) {
    if (userId == null) {
      return Response.json(
        statusCode: 401,
        body: {'success': false, 'message': 'Autentikasi diperlukan'},
      );
    }

    try {
      final raw = await context.request.body();
      final body = json.decode(raw) as Map<String, dynamic>;

      final name = (body['name'] as String?)?.trim();
      if (name == null || name.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'success': false, 'message': 'Nama komunitas wajib diisi'},
        );
      }

      final created = await CommunityService.createCommunity(
        userId: userId,
        name: name,
        description: body['description'] as String?,
        location: body['location'] as String?,
        category: body['category'] as String?,
        privacy: (body['privacy'] as String?) ?? 'public',
        coverImageUrl: body['cover_image_url'] as String?,
        iconImageUrl: body['icon_image_url'] as String?,
      );

      final detail = await CommunityService.getCommunityById(
        created['id'] as int,
        userId: userId,
      );

      return Response.json(
        statusCode: 201,
        body: {'success': true, 'data': detail},
      );
    } catch (e) {
      print('[POST /api/community] Error: $e');
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Gagal membuat komunitas: $e'},
      );
    }
  }

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}
