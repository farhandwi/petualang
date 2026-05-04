import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// GET /api/admin/reports — list reports.
/// Query: status=pending|resolved|dismissed|all (default pending)
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

  final auth = AuthGuard.requireRole(context, ['admin']);
  if (!auth.isOk) return auth.errorResponse!;

  final status = context.request.uri.queryParameters['status'] ?? 'pending';

  try {
    final conn = await Database.connection;
    final whereClause = status == 'all' ? '' : 'WHERE r.status = @status';
    final results = await conn.query(
      '''
      SELECT r.id, r.reporter_id, u.name AS reporter_name,
             r.reason, r.post_id, r.comment_id, r.message_id,
             r.status, r.created_at,
             p.content AS post_content
      FROM reports r
      LEFT JOIN users u ON u.id = r.reporter_id
      LEFT JOIN community_posts p ON p.id = r.post_id
      $whereClause
      ORDER BY r.created_at DESC
      LIMIT 200
      ''',
      substitutionValues: status == 'all' ? {} : {'status': status},
    );

    final list = results.map((r) => {
      'id': r[0],
      'reporter_id': r[1],
      'reporter_name': r[2],
      'reason': r[3],
      'post_id': r[4],
      'comment_id': r[5],
      'message_id': r[6],
      'status': r[7],
      'created_at': (r[8] as DateTime?)?.toIso8601String(),
      'post_content': r[9],
    }).toList();

    return Response.json(body: {'success': true, 'data': list});
  } catch (e) {
    print('Admin reports list error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
