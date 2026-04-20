import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  // Extract and verify JWT token
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
  final request = context.request;
  final queryParams = request.url.queryParameters;
  final query = queryParams['q'] ?? '';

  try {
    final conn = await Database.connection;
    // Search users by name, exclude self. Don't exclude blocked users here, frontend will show them as blocked.
    // Or we can just return if they are blocked. Let's return block status.
    final results = await conn.query(
      '''
      SELECT u.id, u.name, u.profile_picture, u.email, u.level,
             EXISTS (
                SELECT 1 FROM dm_blocks 
                WHERE (blocker_id = @uid AND blocked_id = u.id)
                   OR (blocker_id = u.id AND blocked_id = @uid)
             ) AS is_blocked
      FROM users u
      WHERE u.id != @uid AND u.is_active = true AND u.name ILIKE @query
      LIMIT 20
      ''',
      substitutionValues: {
        'uid': currentUserId,
        'query': '%$query%',
      },
    );

    final users = results.map((r) => {
      'id': r[0],
      'name': r[1],
      'profile_picture': r[2],
      'email': r[3],
      'level': r[4],
      'is_blocked': r[5],
    }).toList();

    return Response.json(body: {
      'success': true,
      'users': users,
    });
  } catch (e) {
    print('Search users error: \$e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Server error'},
    );
  }
}
