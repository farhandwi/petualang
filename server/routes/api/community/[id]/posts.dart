import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET  /api/community/[id]/posts — list posts (auth opsional, untuk is_liked)
/// POST /api/community/[id]/posts — create post (auth required, harus member)
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
    final params = context.request.uri.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
    final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

    final posts = await CommunityService.getPosts(
      communityId,
      userId: userId,
      limit: limit,
      offset: offset,
    );
    if (userId != null) {
      await CommunityService.touchLastSeen(communityId, userId);
    }
    return Response.json(body: {'success': true, 'data': posts});
  }

  if (context.request.method == HttpMethod.post) {
    if (userId == null) {
      return Response.json(
        statusCode: 401,
        body: {'success': false, 'message': 'Autentikasi diperlukan'},
      );
    }
    final isMem = await CommunityService.isMember(communityId, userId);
    if (!isMem) {
      return Response.json(
        statusCode: 403,
        body: {'success': false, 'message': 'Hanya anggota yang bisa membuat post'},
      );
    }

    try {
      final raw = await context.request.body();
      final body = json.decode(raw) as Map<String, dynamic>;
      final content = (body['content'] as String?)?.trim() ?? '';
      if (content.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'success': false, 'message': 'Konten tidak boleh kosong'},
        );
      }
      final imageUrl = body['image_url'] as String?;
      final created = await CommunityService.createPost(
        communityId: communityId,
        userId: userId,
        content: content,
        imageUrl: imageUrl,
      );
      final full = await CommunityService.getPostById(
        created['id'] as int,
        userId: userId,
      );
      await CommunityService.touchLastSeen(communityId, userId);
      return Response.json(statusCode: 201, body: {'success': true, 'data': full});
    } catch (e) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Gagal membuat post: $e'},
      );
    }
  }

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}
