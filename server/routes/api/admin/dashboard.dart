import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// GET /api/admin/dashboard — ringkasan statistik untuk halaman admin.
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

  try {
    final conn = await Database.connection;

    final usersRow = await conn.query(
      '''
      SELECT
        COUNT(*) FILTER (WHERE role = 'user') AS total_user,
        COUNT(*) FILTER (WHERE role = 'mitra') AS total_mitra,
        COUNT(*) FILTER (WHERE role = 'admin') AS total_admin,
        COUNT(*) FILTER (WHERE verification_status = 'pending') AS pending_verifications,
        COUNT(*) FILTER (WHERE verification_status = 'verified') AS verified_users,
        COUNT(*) FILTER (WHERE is_active = false) AS inactive_users,
        COUNT(*) AS total_users
      FROM users
      ''',
    );

    final ticketsRow = await conn.query(
      '''
      SELECT
        COUNT(*) AS total_tickets,
        COALESCE(SUM(total_price), 0) AS revenue_tickets,
        COUNT(*) FILTER (
          WHERE created_at >= date_trunc('month', NOW())
        ) AS tickets_this_month
      FROM tickets
      ''',
    );

    final rentalsRow = await conn.query(
      '''
      SELECT
        COUNT(*) AS total_rentals,
        COALESCE(SUM(total_price), 0) AS revenue_rentals,
        COUNT(*) FILTER (
          WHERE created_at >= date_trunc('month', NOW())
        ) AS rentals_this_month
      FROM rentals
      ''',
    );

    final mountainsRow = await conn.query(
      'SELECT COUNT(*) AS total_mountains FROM mountains',
    );

    final reportsRow = await conn.query(
      "SELECT COUNT(*) AS pending_reports FROM reports WHERE status = 'pending'",
    );

    final u = usersRow.first;
    final t = ticketsRow.first;
    final r = rentalsRow.first;

    return Response.json(
      body: {
        'success': true,
        'data': {
          'users': {
            'total': u[6] as int? ?? 0,
            'user_count': u[0] as int? ?? 0,
            'mitra_count': u[1] as int? ?? 0,
            'admin_count': u[2] as int? ?? 0,
            'pending_verifications': u[3] as int? ?? 0,
            'verified': u[4] as int? ?? 0,
            'inactive': u[5] as int? ?? 0,
          },
          'tickets': {
            'total': t[0] as int? ?? 0,
            'revenue': _toDouble(t[1]),
            'this_month': t[2] as int? ?? 0,
          },
          'rentals': {
            'total': r[0] as int? ?? 0,
            'revenue': _toDouble(r[1]),
            'this_month': r[2] as int? ?? 0,
          },
          'mountains': mountainsRow.first[0] as int? ?? 0,
          'pending_reports': reportsRow.first[0] as int? ?? 0,
        },
      },
    );
  } catch (e) {
    print('Admin dashboard error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
