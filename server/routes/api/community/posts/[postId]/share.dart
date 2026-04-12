import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

Future<Response> onRequest(RequestContext context, String postId) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  // Middleware Auth using JwtHelper
  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);
  final authUser = token != null ? JwtHelper.verifyToken(token) : null;
  
  if (authUser == null) {
    return Response.json(statusCode: 401, body: {'success': false, 'error': 'Unauthorized'});
  }

  final id = int.tryParse(postId);
  if (id == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'error': 'Invalid post ID'});
  }

  try {
    final result = await CommunityService.incrementShareCount(id);
    return Response.json(body: {
      'success': true,
      'message': 'Share counted successfully',
      'data': {'share_count': result['share_count']},
    });
  } catch (e) {
    print('Failed to increment share: $e');
    return Response.json(
        statusCode: 500, body: {'error': 'Internal server error'});
  }
}
