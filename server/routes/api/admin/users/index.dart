import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// GET /api/admin/users — list semua user (filterable).
/// Query params: role=user|mitra|admin|all (default all),
///                active=true|false|all (default all),
///                q=search-term (cari di name/email)
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

  final qp = context.request.uri.queryParameters;
  final role = qp['role'] ?? 'all';
  final active = qp['active'] ?? 'all';
  final q = (qp['q'] ?? '').trim();

  final filters = <String>[];
  final substitutions = <String, dynamic>{};

  if (role != 'all') {
    filters.add('role = @role');
    substitutions['role'] = role;
  }
  if (active == 'true') {
    filters.add('is_active = TRUE');
  } else if (active == 'false') {
    filters.add('is_active = FALSE');
  }
  if (q.isNotEmpty) {
    filters.add('(name ILIKE @q OR email ILIKE @q)');
    substitutions['q'] = '%$q%';
  }

  final whereSql = filters.isEmpty ? '' : 'WHERE ${filters.join(' AND ')}';

  try {
    final conn = await Database.connection;
    final results = await conn.query(
      '''
      SELECT id, name, email, phone, profile_picture, is_active, role,
             verification_status, verified_at, level, exp, created_at
      FROM users
      $whereSql
      ORDER BY created_at DESC
      LIMIT 500
      ''',
      substitutionValues: substitutions,
    );

    final list = results.map((u) {
      return {
        'id': u[0],
        'name': u[1],
        'email': u[2],
        'phone': u[3],
        'profile_picture': u[4],
        'is_active': u[5],
        'role': u[6],
        'verification_status': u[7],
        'verified_at': (u[8] as DateTime?)?.toIso8601String(),
        'level': u[9] ?? 1,
        'exp': u[10] ?? 0,
        'created_at': (u[11] as DateTime?)?.toIso8601String(),
      };
    }).toList();

    return Response.json(body: {'success': true, 'data': list});
  } catch (e) {
    print('Admin users list error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
