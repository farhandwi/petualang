import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/services/xendit_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';
import 'dart:math';

/// GET, POST /api/rentals
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method == HttpMethod.post) {
    return _createRental(context);
  } else if (context.request.method == HttpMethod.get) {
    return _getRentals(context);
  }

  return Response.json(
    statusCode: 405,
    body: {'status': 'error', 'message': 'Method Not Allowed'},
  );
}

Future<Response> _createRental(RequestContext context) async {
  // Extract and verify JWT token
  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);

  if (token == null) {
    return Response.json(
      statusCode: 401,
      body: {'status': 'error', 'message': 'Akses ditolak. Token tidak ditemukan'},
    );
  }

  final payload = JwtHelper.verifyToken(token);
  if (payload == null) {
    return Response.json(
      statusCode: 401,
      body: {'status': 'error', 'message': 'Token tidak valid'},
    );
  }

  final userId = payload['sub'] as int;

    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final startDateStr = body['start_date'] as String?;
      final endDateStr = body['end_date'] as String?;
      final totalPrice = body['total_price'] as num?;
      final deliveryFee = body['delivery_fee'] as num? ?? 0;
      final mountainId = body['mountain_id'] as int?;
      final entryRouteId = body['entry_route_id'] as int?;
      final exitRouteId = body['exit_route_id'] as int?;
      final items = body['items'] as List<dynamic>?;

      if (startDateStr == null || endDateStr == null || totalPrice == null || items == null || items.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'status': 'error', 'message': 'Missing required fields or empty cart'},
        );
      }

    // Generate unique rental code
    final rng = Random();
    final rentalCode = 'RN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-${rng.nextInt(900) + 100}';

    final conn = await Database.connection;
    
    // In a real app we'd use transactions, but dart_postgres transaction API is complex.
    // For MVP, we insert rental then loop to insert details.
    
    final rentalResult = await conn.query(
      '''
      INSERT INTO rentals (user_id, mountain_id, entry_route_id, exit_route_id, rental_code, start_date, end_date, total_price, delivery_fee, status)
      VALUES (@userId, @mountainId, @entryRouteId, @exitRouteId, @rentalCode, @startDate, @endDate, @totalPrice, @deliveryFee, @status)
      RETURNING id, rental_code, status, created_at
      ''',
      substitutionValues: {
        'userId': userId,
        'mountainId': mountainId,
        'entryRouteId': entryRouteId,
        'exitRouteId': exitRouteId,
        'rentalCode': rentalCode,
        'startDate': startDateStr,
        'endDate': endDateStr,
        'totalPrice': totalPrice,
        'deliveryFee': deliveryFee,
        'status': 'pending', 
      },
    );

    if (rentalResult.isEmpty) {
      throw Exception('Failed to insert rental');
    }

    final inserted = rentalResult.first;
    final rentalId = inserted[0] as int;

    for (var item in items) {
      final itemId = item['item_id'] as int;
      final quantity = item['quantity'] as int;
      final pricePerDay = item['price_per_day'] as num;
      final subtotal = item['subtotal'] as num;

      await conn.query(
        '''
        INSERT INTO rental_details (rental_id, item_id, quantity, price_per_day, subtotal)
        VALUES (@rentalId, @itemId, @quantity, @pricePerDay, @subtotal)
        ''',
        substitutionValues: {
          'rentalId': rentalId,
          'itemId': itemId,
          'quantity': quantity,
          'pricePerDay': pricePerDay,
          'subtotal': subtotal,
        },
      );
    }

    // Create Xendit Invoice
    final invoice = await XenditService.createInvoice(
      externalId: rentalCode,
      amount: totalPrice.toDouble(),
      payerEmail: 'user$userId@petualang.app',
      description: 'Penyewaan Alat Gunung (Kode: $rentalCode)',
    );

    return Response.json(body: {
      'status': 'success',
      'message': 'Pesanan sewa berhasil dibuat. Silakan lanjut ke pembayaran.',
      'data': {
        'id': rentalId,
        'rental_code': inserted[1],
        'status': inserted[2],
        'created_at': (inserted[3] as DateTime).toIso8601String(),
        'payment_url': invoice?['invoice_url'] ?? '',
      }
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'status': 'error', 'message': 'Failed to process rental: $e'},
    );
  }
}

Future<Response> _getRentals(RequestContext context) async {
  // ... basic implementation for user rental history if needed
  return Response.json(body: {'status': 'success', 'data': []});
}
