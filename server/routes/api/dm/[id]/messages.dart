import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/dm_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.get) {
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

  final conversationId = int.tryParse(id);
  if (conversationId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Invalid conversation ID'},
    );
  }

  final request = context.request;
  final queryParams = request.url.queryParameters;
  final limit = int.tryParse(queryParams['limit'] ?? '50') ?? 50;
  final beforeId = int.tryParse(queryParams['beforeId'] ?? '');

  try {
    final messages = await DmService.getMessages(conversationId, limit: limit, beforeId: beforeId);
    return Response.json(body: {
      'success': true,
      'messages': messages,
    });
  } catch (e) {
    print('Get DM messages error: \$e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Server error'},
    );
  }
}
