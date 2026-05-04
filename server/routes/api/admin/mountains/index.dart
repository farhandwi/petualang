import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// GET, POST /api/admin/mountains
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  final auth = AuthGuard.requireRole(context, ['admin']);
  if (!auth.isOk) return auth.errorResponse!;

  if (context.request.method == HttpMethod.get) return _list();
  if (context.request.method == HttpMethod.post) return _create(context);

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}

Future<Response> _list() async {
  try {
    final conn = await Database.connection;
    final results = await conn.query(
      '''
      SELECT id, name, location, elevation, difficulty, price, image_url,
             description, is_featured, rating,
             external_booking_url, use_external_booking
      FROM mountains
      ORDER BY id ASC
      ''',
    );
    final list = results.map((m) {
      return {
        'id': m[0],
        'name': m[1],
        'location': m[2],
        'elevation': m[3],
        'difficulty': m[4],
        'price': _toDouble(m[5]),
        'image_url': m[6],
        'description': m[7],
        'is_featured': m[8] ?? false,
        'rating': _toDouble(m[9]),
        'external_booking_url': m[10],
        'use_external_booking': m[11] ?? false,
      };
    }).toList();
    return Response.json(body: {'success': true, 'data': list});
  } catch (e) {
    print('Admin mountains list error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

Future<Response> _create(RequestContext context) async {
  try {
    final body = json.decode(await context.request.body()) as Map<String, dynamic>;

    final name = (body['name'] as String?)?.trim();
    final location = (body['location'] as String?)?.trim();
    final elevation = body['elevation'] as int?;
    final difficulty = (body['difficulty'] as String?)?.trim();
    final price = body['price'];
    final imageUrl = (body['image_url'] as String?)?.trim() ?? '';
    final description = (body['description'] as String?)?.trim() ?? '';
    final isFeatured = body['is_featured'] as bool? ?? false;

    if (name == null ||
        name.isEmpty ||
        location == null ||
        location.isEmpty ||
        elevation == null ||
        difficulty == null ||
        price == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'name, location, elevation, difficulty, price wajib diisi',
        },
      );
    }

    final externalBookingUrl = (body['external_booking_url'] as String?)?.trim();
    final useExternalBooking = body['use_external_booking'] as bool? ?? false;

    final conn = await Database.connection;
    final result = await conn.query(
      '''
      INSERT INTO mountains (name, location, elevation, difficulty, price,
                             image_url, description, is_featured,
                             external_booking_url, use_external_booking)
      VALUES (@name, @location, @elevation, @difficulty, @price,
              @image, @description, @featured,
              @extUrl, @useExt)
      RETURNING id, name, location, elevation, difficulty, price, image_url,
                description, is_featured, rating,
                external_booking_url, use_external_booking
      ''',
      substitutionValues: {
        'name': name,
        'location': location,
        'elevation': elevation,
        'difficulty': difficulty,
        'price': price,
        'image': imageUrl,
        'description': description,
        'featured': isFeatured,
        'extUrl': externalBookingUrl,
        'useExt': useExternalBooking,
      },
    );

    final m = result.first;
    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'message': 'Gunung ditambahkan',
        'data': {
          'id': m[0],
          'name': m[1],
          'location': m[2],
          'elevation': m[3],
          'difficulty': m[4],
          'price': _toDouble(m[5]),
          'image_url': m[6],
          'description': m[7],
          'is_featured': m[8],
          'rating': _toDouble(m[9]),
          'external_booking_url': m[10],
          'use_external_booking': m[11] ?? false,
        },
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Admin mountains create error: $e');
    if (e.toString().contains('duplicate')) {
      return Response.json(
        statusCode: 409,
        body: {'success': false, 'message': 'Nama gunung sudah ada'},
      );
    }
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
