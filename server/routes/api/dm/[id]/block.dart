import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/dm_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);

  if (token == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Unauthorized'},
    );
  }

  final payload = JwtHelper.verifyToken(token);
  if (payload == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Invalid token'},
    );
  }

  final currentUserId = payload['sub'] as int;
  final targetUserId = int.tryParse(id);
  if (targetUserId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Invalid user ID'},
    );
  }

  try {
    await DmService.toggleBlockUser(currentUserId, targetUserId);
    final isBlocked = await DmService.isUserBlockedBy(currentUserId, targetUserId);
    return Response.json(body: {
      'success': true,
      'is_blocked': isBlocked,
    });
  } catch (e) {
    print('Block user error: \$e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Server error'},
    );
  }
}
