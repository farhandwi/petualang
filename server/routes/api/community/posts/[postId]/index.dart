import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET    /api/community/posts/[postId] — detail post
/// DELETE /api/community/posts/[postId] — hapus post
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
    final post = await CommunityService.getPostById(id, userId: userId);
    if (post == null) {
      return Response.json(statusCode: 404, body: {'success': false, 'message': 'Post tidak ditemukan'});
    }
    return Response.json(body: {'success': true, 'data': post});
  }

  if (context.request.method == HttpMethod.delete) {
    if (userId == null) {
      return Response.json(statusCode: 401, body: {'success': false, 'message': 'Autentikasi diperlukan'});
    }
    final deleted = await CommunityService.deletePost(id, userId);
    if (!deleted) {
      return Response.json(statusCode: 403, body: {'success': false, 'message': 'Tidak diizinkan menghapus post ini'});
    }
    return Response.json(body: {'success': true, 'message': 'Post berhasil dihapus'});
  }

  return Response.json(statusCode: 405, body: {'success': false, 'message': 'Method not allowed'});
}
