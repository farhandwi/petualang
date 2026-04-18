import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/dm_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.get && context.request.method != HttpMethod.post) {
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

  try {
    if (context.request.method == HttpMethod.get) {
      final conversations = await DmService.getUserConversations(currentUserId);
      return Response.json(body: {
        'success': true,
        'conversations': conversations,
      });
    } else if (context.request.method == HttpMethod.post) {
      // Create new conversation with a target user
      final body = await context.request.json() as Map<String, dynamic>;
      final targetUserId = body['target_user_id'] as int?;
      
      if (targetUserId == null) {
        return Response.json(
          statusCode: 400,
          body: {'success': false, 'message': 'target_user_id is required'},
        );
      }

      final conversationId = await DmService.getOrCreateConversation(currentUserId, targetUserId);
      return Response.json(body: {
        'success': true,
        'conversation_id': conversationId,
      });
    }
  } catch (e) {
    print('DM index error: \$e');
  }

  return Response.json(
    statusCode: 500,
    body: {'success': false, 'message': 'Server error'},
  );
}
