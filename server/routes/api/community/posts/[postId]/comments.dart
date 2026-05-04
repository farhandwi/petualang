import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET  /api/community/posts/[postId]/comments — list komentar (nested)
/// POST /api/community/posts/[postId]/comments — buat komentar baru
Future<Response> onRequest(RequestContext context, String postId) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

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

  if (context.request.method == HttpMethod.get) {
    final comments = await CommunityService.getComments(id, userId: userId);
    return Response.json(body: {'success': true, 'data': comments});
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
      final content = (body['content'] as String?)?.trim() ?? '';
      if (content.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'success': false, 'message': 'Komentar tidak boleh kosong'},
        );
      }

      final created = await CommunityService.createComment(
        postId: id,
        userId: userId,
        content: content,
        parentId: body['parent_id'] as int?,
        imageUrl: body['image_url'] as String?,
      );
      return Response.json(statusCode: 201, body: {'success': true, 'data': created});
    } catch (e) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Gagal membuat komentar: $e'},
      );
    }
  }

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}
