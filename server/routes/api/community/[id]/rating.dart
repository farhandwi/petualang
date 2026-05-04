import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET  /api/community/[id]/rating — ambil rating user saat ini
/// POST /api/community/[id]/rating — beri/update rating (member only)
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

  if (userId == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Autentikasi diperlukan'},
    );
  }

  if (context.request.method == HttpMethod.get) {
    final stars = await CommunityService.getMyRating(communityId, userId);
    return Response.json(body: {'success': true, 'data': {'stars': stars}});
  }

  if (context.request.method == HttpMethod.post) {
    try {
      final raw = await context.request.body();
      final body = json.decode(raw) as Map<String, dynamic>;
      final stars = body['stars'] is int
          ? body['stars'] as int
          : int.tryParse('${body['stars']}') ?? 0;
      final review = body['review'] as String?;

      final result = await CommunityService.rateCommunity(
        communityId: communityId,
        userId: userId,
        stars: stars,
        review: review,
      );
      final code = result['success'] == true ? 200 : 400;
      return Response.json(statusCode: code, body: result);
    } catch (e) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Gagal menyimpan rating: $e'},
      );
    }
  }

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}
