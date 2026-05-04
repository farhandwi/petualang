import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// GET /api/mitra/me/stats — statistik penjualan toko mitra.
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

  try {
    final conn = await Database.connection;

    final vendorRow = await conn.query(
      '''
      SELECT id, rating, review_count, is_open
      FROM rental_vendors WHERE user_id = @uid LIMIT 1
      ''',
      substitutionValues: {'uid': mitraId},
    );

    if (vendorRow.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Toko tidak ditemukan'},
      );
    }

    final vendorId = vendorRow.first[0] as int;
    final rating = _toDouble(vendorRow.first[1]);
    final reviewCount = vendorRow.first[2] as int? ?? 0;
    final isOpen = vendorRow.first[3] as bool? ?? false;

    final revenueRow = await conn.query(
      '''
      SELECT
        COUNT(DISTINCT r.id) AS total_orders,
        COALESCE(SUM(d.subtotal), 0) AS total_revenue,
        COUNT(DISTINCT r.id) FILTER (
          WHERE r.created_at >= date_trunc('month', NOW())
        ) AS orders_this_month,
        COALESCE(SUM(d.subtotal) FILTER (
          WHERE r.created_at >= date_trunc('month', NOW())
        ), 0) AS revenue_this_month
      FROM rentals r
      JOIN rental_details d ON d.rental_id = r.id
      JOIN rental_items i ON i.id = d.item_id
      WHERE i.vendor_id = @vid
      ''',
      substitutionValues: {'vid': vendorId},
    );

    final itemCountRow = await conn.query(
      'SELECT COUNT(*) FROM rental_items WHERE vendor_id = @vid',
      substitutionValues: {'vid': vendorId},
    );

    final topItemsRows = await conn.query(
      '''
      SELECT i.id, i.name, i.image_url, SUM(d.quantity) AS total_qty,
             COALESCE(SUM(d.subtotal), 0) AS revenue
      FROM rental_details d
      JOIN rental_items i ON i.id = d.item_id
      WHERE i.vendor_id = @vid
      GROUP BY i.id, i.name, i.image_url
      ORDER BY total_qty DESC NULLS LAST
      LIMIT 5
      ''',
      substitutionValues: {'vid': vendorId},
    );

    final rev = revenueRow.first;
    final topItems = topItemsRows.map((r) => {
      'id': r[0],
      'name': r[1],
      'image_url': r[2],
      'total_qty': r[3] ?? 0,
      'revenue': _toDouble(r[4]),
    }).toList();

    return Response.json(
      body: {
        'success': true,
        'data': {
          'vendor_id': vendorId,
          'is_open': isOpen,
          'rating': rating,
          'review_count': reviewCount,
          'total_items': itemCountRow.first[0] as int? ?? 0,
          'orders': {
            'total': rev[0] as int? ?? 0,
            'this_month': rev[2] as int? ?? 0,
          },
          'revenue': {
            'total': _toDouble(rev[1]),
            'this_month': _toDouble(rev[3]),
          },
          'top_items': topItems,
        },
      },
    );
  } catch (e) {
    print('Mitra stats error: $e');
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
