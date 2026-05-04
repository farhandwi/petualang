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
    final ticketResults = await conn.mappedResultsQuery('''
      SELECT t.id, t.booking_code, t.date, t.total_price, t.status, t.created_at, m.name as mountain_name 
      FROM tickets t 
      LEFT JOIN mountains m ON t.mountain_id = m.id
      WHERE t.user_id = @uid
      ORDER BY t.created_at DESC
    ''', substitutionValues: {'uid': userId});

    final rentalResults = await conn.mappedResultsQuery('''
      SELECT r.id, r.rental_code, r.start_date, r.end_date, r.total_price, r.status, r.created_at
      FROM rentals r
      WHERE r.user_id = @uid
      ORDER BY r.created_at DESC
    ''', substitutionValues: {'uid': userId});

    final List<Map<String, dynamic>> orders = [];

    for (var row in ticketResults) {
      final t = row['tickets'] ?? row['t'] ?? {};
      final m = row['mountains'] ?? row['m'] ?? {};
      orders.add({
        'type': 'ticket',
        'id': t['id'],
        'code': t['booking_code'],
        'date': t['date']?.toIso8601String(),
        'total_price': t['total_price'],
        'status': t['status'],
        'created_at': t['created_at']?.toIso8601String(),
        'title': m['mountain_name'] != null ? '${m['mountain_name']} — Base Camp' : 'Tiket Gunung',
      });
    }

    for (var row in rentalResults) {
      final r = row['rentals'] ?? row['r'] ?? {};
      
      // We can also fetch the items if needed, but for now we'll use a generic title 
      // or we can fetch the first item's name. Let's do a subquery or just use a generic name.
      final itemsResult = await conn.mappedResultsQuery('''
        SELECT i.name 
        FROM rental_details rd 
        JOIN rental_items i ON rd.item_id = i.id 
        WHERE rd.rental_id = @rid LIMIT 1
      ''', substitutionValues: {'rid': r['id']});
      
      String title = 'Sewa Alat Gunung';
      if (itemsResult.isNotEmpty) {
        final iName = (itemsResult.first['rental_items'] ?? itemsResult.first['i'] ?? {})['name'];
        if (iName != null) {
          title = iName.toString();
          // if there are more, we can append " + lainnya"
        }
      }

      orders.add({
        'type': 'rental',
        'id': r['id'],
        'code': r['rental_code'],
        'start_date': r['start_date']?.toIso8601String(),
        'end_date': r['end_date']?.toIso8601String(),
        'total_price': r['total_price'],
        'status': r['status'],
        'created_at': r['created_at']?.toIso8601String(),
        'title': title,
      });
    }

    // Sort all orders by created_at descending
    orders.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA); // Descending
    });

    return Response.json(body: {
      'success': true,
      'data': orders,
    });
  } catch (e) {
    print('Error fetching orders: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Gagal memuat pesanan'},
    );
  }
}
