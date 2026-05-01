import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET /api/users/me/upcoming_bookings
/// Auth required. Return tickets user yang tanggalnya >= hari ini.
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

  final token = JwtHelper.extractToken(context.request.headers['Authorization']);
  if (token == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Token tidak ditemukan'},
    );
  }
  final payload = JwtHelper.verifyToken(token);
  if (payload == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Token tidak valid'},
    );
  }
  final userId = payload['sub'] as int;

  try {
    final conn = await Database.connection;
    final results = await conn.mappedResultsQuery('''
      SELECT
        t.id, t.booking_code, t.date, t.climbers_count, t.total_price, t.status, t.created_at,
        m.id AS mountain_id, m.name AS mountain_name, m.location AS mountain_location,
        m.image_url AS mountain_image, m.elevation AS mountain_elevation
      FROM tickets t
      LEFT JOIN mountains m ON m.id = t.mountain_id
      WHERE t.user_id = @uid
        AND t.date >= CURRENT_DATE
        AND t.status IN ('success', 'pending', 'confirmed')
      ORDER BY t.date ASC
      LIMIT 10
    ''', substitutionValues: {'uid': userId});

    final bookings = results.map((row) {
      final t = Map<String, dynamic>.from(row['t'] ?? row['tickets'] ?? {});
      final m = Map<String, dynamic>.from(row['m'] ?? row['mountains'] ?? {});
      if (t['date'] != null) t['date'] = t['date'].toIso8601String();
      if (t['created_at'] != null) t['created_at'] = t['created_at'].toIso8601String();
      t['mountain_id'] = m['mountain_id'] ?? m['id'];
      t['mountain_name'] = m['mountain_name'] ?? m['name'];
      t['mountain_location'] = m['mountain_location'] ?? m['location'];
      t['mountain_image'] = m['mountain_image'] ?? m['image_url'];
      t['mountain_elevation'] = m['mountain_elevation'] ?? m['elevation'];
      return t;
    }).toList();

    return Response.json(body: {
      'success': true,
      'data': bookings,
    });
  } catch (e) {
    print('Upcoming bookings error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Gagal memuat data'},
    );
  }
}
