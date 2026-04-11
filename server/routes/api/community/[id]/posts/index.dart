import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET  /api/community/[id]/posts — list posts
/// POST /api/community/[id]/posts — create post
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

  final communityId = int.tryParse(id);
  print('DEBUG: Request for community ID: $id (parsed: $communityId) method: ${context.request.method}');
  if (communityId == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'ID tidak valid'});
  }

  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);
  final payload = token != null ? JwtHelper.verifyToken(token) : null;
  final userId = payload?['sub'] as int?;

  // ── GET ──
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
    print('DEBUG: Found ${posts.length} posts for community $communityId');
    return Response.json(body: {'success': true, 'data': posts});
  }

  // ── POST ──
  if (context.request.method == HttpMethod.post) {
    if (userId == null) {
      return Response.json(statusCode: 401, body: {'success': false, 'message': 'Autentikasi diperlukan'});
    }

    final isMember = await CommunityService.isMember(communityId, userId);
    if (!isMember) {
      return Response.json(statusCode: 403, body: {'success': false, 'message': 'Anda harus bergabung ke komunitas ini terlebih dahulu'});
    }

    final bodyString = await context.request.body();
    final body = json.decode(bodyString) as Map<String, dynamic>;
    final content = body['content'] as String?;
    final imageUrl = body['image_url'] as String?;

    if (content == null || content.trim().isEmpty) {
      return Response.json(statusCode: 400, body: {'success': false, 'message': 'Konten postingan tidak boleh kosong'});
    }

    final result = await CommunityService.createPost(
      communityId: communityId,
      userId: userId,
      content: content.trim(),
      imageUrl: imageUrl,
    );
    print('DEBUG: Post created successfully in DB: $result for community $communityId');
    return Response.json(statusCode: 201, body: {'success': true, 'data': result});
  }

  return Response.json(statusCode: 405, body: {'success': false, 'message': 'Method not allowed'});
}
