import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/services/xendit_service.dart';
import 'dart:math';

/// POST /api/tickets
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'status': 'error', 'message': 'Method Not Allowed'},
    );
  }
  
  // Simplification for MVP: Hardcode userId or parse basic header.
  // In a real app, properly verify JWT.
  int userId = 1; 

  return _bookTicket(context, userId);
}

Future<Response> _bookTicket(RequestContext context, int userId) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final mountainId = body['mountain_id'] as int?;
    final mountainRouteId = body['mountain_route_id'] as int?;
    final dateStr = body['date'] as String?;
    final climbersCount = body['climbers_count'] as int?;
    final totalPrice = body['total_price'] as num?;

    if (mountainId == null || dateStr == null || climbersCount == null || totalPrice == null) {
      return Response.json(
        statusCode: 400,
        body: {'status': 'error', 'message': 'Missing required fields'},
      );
    }

    // Generate unique booking code
    final rng = Random();
    final bookingCode = 'PTL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-${rng.nextInt(900) + 100}';

    final conn = await Database.connection;
    final result = await conn.query(
      '''
      INSERT INTO tickets (user_id, mountain_id, mountain_route_id, booking_code, date, climbers_count, total_price, status)
      VALUES (@userId, @mountainId, @mountainRouteId, @bookingCode, @date, @climbersCount, @totalPrice, @status)
      RETURNING id, booking_code, status, created_at
      ''',
      substitutionValues: {
        'userId': userId,
        'mountainId': mountainId,
        'mountainRouteId': mountainRouteId,
        'bookingCode': bookingCode,
        'date': DateTime.parse(dateStr).toIso8601String(),
        'climbersCount': climbersCount,
        'totalPrice': totalPrice,
        'status': 'PENDING', 
      },
    );

    if (result.isEmpty) {
      throw Exception('Failed to insert ticket');
    }

    final inserted = result.first;

    // Create Xendit Invoice
    final invoice = await XenditService.createInvoice(
      externalId: bookingCode,
      amount: totalPrice.toDouble(),
      payerEmail: 'user$userId@petualang.app',
      description: 'Pemesanan Tiket Gunung (Kode: $bookingCode)',
    );

    return Response.json(body: {
      'status': 'success',
      'message': 'Tiket berhasil dipesan. Silakan selesaikan pembayaran.',
      'data': {
        'id': inserted[0],
        'booking_code': inserted[1],
        'status': inserted[2],
        'created_at': inserted[3].toIso8601String(),
        'payment_url': invoice?['invoice_url'] ?? '',
      }
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'status': 'error',
        'message': 'Failed to process booking: $e',
      },
    );
  }
}
