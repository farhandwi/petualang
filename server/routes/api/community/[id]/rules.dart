import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET /api/community/[id]/rules — daftar aturan
/// PUT /api/community/[id]/rules — replace aturan (admin/moderator)
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

  final communityId = int.tryParse(id);
  if (communityId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID tidak valid'},
    );
  }

  if (context.request.method == HttpMethod.get) {
    final rules = await CommunityService.getRules(communityId);
    return Response.json(body: {'success': true, 'data': rules});
  }

  if (context.request.method == HttpMethod.put) {
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

    try {
      final raw = await context.request.body();
      final body = json.decode(raw) as Map<String, dynamic>;
      final rules = (body['rules'] as List?)?.cast<String>() ?? const <String>[];

      final ok = await CommunityService.setRules(communityId, userId, rules);
      if (!ok) {
        return Response.json(
          statusCode: 403,
          body: {'success': false, 'message': 'Hanya admin/moderator yang dapat mengubah aturan'},
        );
      }

      final updated = await CommunityService.getRules(communityId);
      return Response.json(body: {'success': true, 'data': updated});
    } catch (e) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Gagal menyimpan aturan: $e'},
      );
    }
  }

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}
