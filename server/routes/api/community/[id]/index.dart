import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET /api/community/[id] — detail komunitas
/// PUT /api/community/[id] — update info (owner / admin / moderator)
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

  final communityId = int.tryParse(id);
  if (communityId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID tidak valid'},
    );
  }

  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);
  final payload = token != null ? JwtHelper.verifyToken(token) : null;
  final userId = payload?['sub'] as int?;

  if (context.request.method == HttpMethod.get) {
    final community = await CommunityService.getCommunityById(communityId, userId: userId);
    if (community == null) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Komunitas tidak ditemukan'},
      );
    }
    return Response.json(body: {'success': true, 'data': community});
  }

  if (context.request.method == HttpMethod.put) {
    if (userId == null) {
      return Response.json(
        statusCode: 401,
        body: {'success': false, 'message': 'Autentikasi diperlukan'},
      );
    }
    try {
      final raw = await context.request.body();
      final body = json.decode(raw) as Map<String, dynamic>;

      final result = await CommunityService.updateCommunity(
        communityId: communityId,
        userId: userId,
        name: body['name'] as String?,
        description: body['description'] as String?,
        location: body['location'] as String?,
        category: body['category'] as String?,
        privacy: body['privacy'] as String?,
        coverImageUrl: body['cover_image_url'] as String?,
        iconImageUrl: body['icon_image_url'] as String?,
      );

      if (result['success'] != true) {
        return Response.json(
          statusCode: result['message'] == 'Komunitas tidak ditemukan' ? 404 : 403,
          body: result,
        );
      }

      final updated = await CommunityService.getCommunityById(communityId, userId: userId);
      return Response.json(body: {'success': true, 'data': updated});
    } catch (e) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Gagal mengubah komunitas: $e'},
      );
    }
  }

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}
