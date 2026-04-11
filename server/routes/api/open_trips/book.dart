import 'dart:convert';
import 'dart:math';
import 'package:dart_frog/dart_frog.dart';
import '../../../lib/db/database.dart';

/// POST /api/open_trips/book
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'message': 'Method not allowed'});
  }

  try {
    final authHeader = context.request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(statusCode: 401, body: {'message': 'Unauthorized'});
    }
    
    // Simplification: In a real app we'd decode JWT here
    // For now we assume a valid userId is passed in body as fallback, or we use a hardcoded 1 if missing for simulation.
    // In Petualang server auth logic usually requires a middleware or we can extract it.
    // We will parse it from the body.
    
    final bodyStr = await context.request.body();
    final Map<String, dynamic> body = jsonDecode(bodyStr);
    final int userId = body['user_id'] ?? 1; // dummy fallback
    final int tripId = body['open_trip_id'];

    final conn = await Database.connection;

    // 1. Check if the trip is available and has quota
    final tripRes = await conn.mappedResultsQuery(
      'SELECT id, price, max_participants, current_participants FROM open_trips WHERE id = @tripId AND status = @status',
      substitutionValues: {'tripId': tripId, 'status': 'open'},
    );

    if (tripRes.isEmpty) {
      return Response.json(statusCode: 404, body: {'status': 'error', 'message': 'Open trip not found or closed'});
    }

    final tripMap = tripRes.first['open_trips']!;
    final int maxP = tripMap['max_participants'] as int;
    final int currentP = tripMap['current_participants'] as int;
    final double price = tripMap['price'] is num ? (tripMap['price'] as num).toDouble() : double.parse(tripMap['price'].toString());

    if (currentP >= maxP) {
      return Response.json(statusCode: 400, body: {'status': 'error', 'message': 'Kuota Open Trip ini sudah penuh.'});
    }

    // 2. Check if user already booked
    final existingRes = await conn.mappedResultsQuery(
      'SELECT id FROM open_trip_bookings WHERE user_id = @userId AND open_trip_id = @tripId',
      substitutionValues: {'userId': userId, 'tripId': tripId},
    );

    if (existingRes.isNotEmpty) {
      return Response.json(statusCode: 400, body: {'status': 'error', 'message': 'Anda sudah terdaftar di Open Trip ini.'});
    }

    // 3. Create booking
    final String bookingCode = 'OT-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';

    await conn.execute('''
      INSERT INTO open_trip_bookings (user_id, open_trip_id, booking_code, payment_status, total_price)
      VALUES (@userId, @tripId, @code, 'unpaid', @price)
    ''', substitutionValues: {
      'userId': userId,
      'tripId': tripId,
      'code': bookingCode,
      'price': price,
    });

    // 4. Update trip current participants
    await conn.execute('''
      UPDATE open_trips 
      SET current_participants = current_participants + 1 
      WHERE id = @tripId
    ''', substitutionValues: {'tripId': tripId});

    return Response.json(body: {
      'status': 'success',
      'message': 'Berhasil mendaftar pada Open Trip',
      'data': {
        'booking_code': bookingCode,
        'payment_status': 'unpaid',
      }
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'status': 'error', 'message': e.toString()},
    );
  }
}
