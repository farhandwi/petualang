import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// GET /api/mitra/me/orders — list rental orders untuk toko mitra.
/// Query: status=all|pending|confirmed|active|completed|cancelled (default all)
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

  final auth = AuthGuard.requireRole(context, ['mitra']);
  if (!auth.isOk) return auth.errorResponse!;
  final mitraId = auth.info!.userId;

  final status = context.request.uri.queryParameters['status'] ?? 'all';

  try {
    final conn = await Database.connection;
    final filter = status == 'all' ? '' : 'AND r.status = @status';
    final results = await conn.query(
      '''
      SELECT DISTINCT r.id, r.rental_code, r.user_id, u.name AS customer_name,
             r.start_date, r.end_date, r.total_price, r.status,
             r.created_at, m.name AS mountain_name
      FROM rentals r
      JOIN rental_details d ON d.rental_id = r.id
      JOIN rental_items i ON i.id = d.item_id
      JOIN rental_vendors v ON v.id = i.vendor_id
      LEFT JOIN users u ON u.id = r.user_id
      LEFT JOIN mountains m ON m.id = r.mountain_id
      WHERE v.user_id = @mitraId $filter
      ORDER BY r.created_at DESC
      LIMIT 200
      ''',
      substitutionValues: status == 'all'
          ? {'mitraId': mitraId}
          : {'mitraId': mitraId, 'status': status},
    );

    final list = results.map((r) => {
      'id': r[0],
      'rental_code': r[1],
      'user_id': r[2],
      'customer_name': r[3],
      'start_date': (r[4] as DateTime?)?.toIso8601String(),
      'end_date': (r[5] as DateTime?)?.toIso8601String(),
      'total_price': _toDouble(r[6]),
      'status': r[7],
      'created_at': (r[8] as DateTime?)?.toIso8601String(),
      'mountain_name': r[9],
    }).toList();

    return Response.json(body: {'success': true, 'data': list});
  } catch (e) {
    print('Mitra orders list error: $e');
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
