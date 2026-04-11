import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET  /api/community/posts/[postId]/comments — list komentar
/// POST /api/community/posts/[postId]/comments — tambah komentar
Future<Response> onRequest(RequestContext context, String postId) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

  final id = int.tryParse(postId);
  if (id == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'ID tidak valid'});
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
      return Response.json(statusCode: 401, body: {'success': false, 'message': 'Autentikasi diperlukan'});
    }
    final bodyString = await context.request.body();
    final body = json.decode(bodyString) as Map<String, dynamic>;
    final content = body['content'] as String?;
    final parentId = body['parent_id'] as int?;
    final imageUrl = body['image_url'] as String?;

    if (content == null || content.trim().isEmpty) {
      return Response.json(statusCode: 400, body: {'success': false, 'message': 'Komentar tidak boleh kosong'});
    }

    final result = await CommunityService.createComment(
      postId: id,
      userId: userId,
      content: content.trim(),
      parentId: parentId,
      imageUrl: imageUrl,
    );
    return Response.json(statusCode: 201, body: {'success': true, 'data': result});
  }

  return Response.json(statusCode: 405, body: {'success': false, 'message': 'Method not allowed'});
}
