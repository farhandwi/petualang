import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// PATCH /api/mitra/me/orders/[id] — update status order milik toko mitra.
/// Body: `{ "status": "confirmed"|"active"|"completed"|"cancelled" }`
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  final auth = AuthGuard.requireRole(context, ['mitra']);
  if (!auth.isOk) return auth.errorResponse!;
  final mitraId = auth.info!.userId;

  final orderId = int.tryParse(id);
  if (orderId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID order tidak valid'},
    );
  }

  if (context.request.method == HttpMethod.get) return _detail(orderId, mitraId);
  if (context.request.method == HttpMethod.patch) return _updateStatus(context, orderId, mitraId);

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}

Future<bool> _verifyOwnership(int orderId, int mitraId) async {
  final conn = await Database.connection;
  final result = await conn.query(
    '''
    SELECT 1 FROM rentals r
    JOIN rental_details d ON d.rental_id = r.id
    JOIN rental_items i ON i.id = d.item_id
    JOIN rental_vendors v ON v.id = i.vendor_id
    WHERE r.id = @rid AND v.user_id = @mitraId
    LIMIT 1
    ''',
    substitutionValues: {'rid': orderId, 'mitraId': mitraId},
  );
  return result.isNotEmpty;
}

Future<Response> _detail(int orderId, int mitraId) async {
  final isOwner = await _verifyOwnership(orderId, mitraId);
  if (!isOwner) {
    return Response.json(
      statusCode: 403,
      body: {'success': false, 'message': 'Order ini bukan milik toko Anda'},
    );
  }

  try {
    final conn = await Database.connection;
    final orderRows = await conn.query(
      '''
      SELECT r.id, r.rental_code, r.user_id, u.name AS customer_name, u.phone,
             r.start_date, r.end_date, r.total_price, r.status, r.created_at,
             m.name AS mountain_name
      FROM rentals r
      LEFT JOIN users u ON u.id = r.user_id
      LEFT JOIN mountains m ON m.id = r.mountain_id
      WHERE r.id = @id
      ''',
      substitutionValues: {'id': orderId},
    );

    final detailRows = await conn.query(
      '''
      SELECT d.item_id, i.name, d.quantity, d.price_per_day, d.subtotal
      FROM rental_details d
      JOIN rental_items i ON i.id = d.item_id
      JOIN rental_vendors v ON v.id = i.vendor_id
      WHERE d.rental_id = @id AND v.user_id = @mitraId
      ''',
      substitutionValues: {'id': orderId, 'mitraId': mitraId},
    );

    final r = orderRows.first;
    final items = detailRows.map((d) => {
      'item_id': d[0],
      'name': d[1],
      'quantity': d[2],
      'price_per_day': _toDouble(d[3]),
      'subtotal': _toDouble(d[4]),
    }).toList();

    return Response.json(
      body: {
        'success': true,
        'data': {
          'id': r[0],
          'rental_code': r[1],
          'user_id': r[2],
          'customer_name': r[3],
          'customer_phone': r[4],
          'start_date': (r[5] as DateTime?)?.toIso8601String(),
          'end_date': (r[6] as DateTime?)?.toIso8601String(),
          'total_price': _toDouble(r[7]),
          'status': r[8],
          'created_at': (r[9] as DateTime?)?.toIso8601String(),
          'mountain_name': r[10],
          'items': items,
        },
      },
    );
  } catch (e) {
    print('Mitra order detail error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

Future<Response> _updateStatus(RequestContext context, int orderId, int mitraId) async {
  final isOwner = await _verifyOwnership(orderId, mitraId);
  if (!isOwner) {
    return Response.json(
      statusCode: 403,
      body: {'success': false, 'message': 'Order ini bukan milik toko Anda'},
    );
  }

  try {
    final body = json.decode(await context.request.body()) as Map<String, dynamic>;
    final status = (body['status'] as String?)?.trim();

    const allowed = ['confirmed', 'active', 'completed', 'cancelled'];
    if (status == null || !allowed.contains(status)) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Status harus salah satu dari: ${allowed.join(', ')}',
        },
      );
    }

    final conn = await Database.connection;
    await conn.execute(
      'UPDATE rentals SET status = @status WHERE id = @id',
      substitutionValues: {'id': orderId, 'status': status},
    );

    return Response.json(body: {'success': true, 'message': 'Status order diperbarui'});
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Mitra order update error: $e');
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
