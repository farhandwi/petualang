import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// GET, PATCH /api/mitra/me/vendor — vendor toko milik mitra.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  final auth = AuthGuard.requireRole(context, ['mitra']);
  if (!auth.isOk) return auth.errorResponse!;
  final mitraId = auth.info!.userId;

  if (context.request.method == HttpMethod.get) return _get(mitraId);
  if (context.request.method == HttpMethod.patch) return _update(context, mitraId);

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}

Future<Response> _get(int mitraId) async {
  try {
    final conn = await Database.connection;
    final results = await conn.query(
      '''
      SELECT id, name, address, contact_phone, is_open, image_url,
             rating, review_count, mountain_id, latitude, longitude,
             created_at
      FROM rental_vendors
      WHERE user_id = @uid
      LIMIT 1
      ''',
      substitutionValues: {'uid': mitraId},
    );

    if (results.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Toko belum diatur untuk akun mitra ini. Hubungi admin.',
        },
      );
    }

    final v = results.first;
    return Response.json(
      body: {
        'success': true,
        'data': {
          'id': v[0],
          'name': v[1],
          'address': v[2],
          'contact_phone': v[3],
          'is_open': v[4],
          'image_url': v[5],
          'rating': _toDouble(v[6]),
          'review_count': v[7],
          'mountain_id': v[8],
          'latitude': _toDouble(v[9]),
          'longitude': _toDouble(v[10]),
          'created_at': (v[11] as DateTime?)?.toIso8601String(),
        },
      },
    );
  } catch (e) {
    print('Mitra vendor get error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

Future<Response> _update(RequestContext context, int mitraId) async {
  try {
    final body = json.decode(await context.request.body()) as Map<String, dynamic>;
    final conn = await Database.connection;

    final affected = await conn.execute(
      '''
      UPDATE rental_vendors SET
        name = COALESCE(@name, name),
        address = COALESCE(@address, address),
        contact_phone = COALESCE(@phone, contact_phone),
        is_open = COALESCE(@isOpen, is_open),
        image_url = COALESCE(@image, image_url),
        latitude = COALESCE(@lat, latitude),
        longitude = COALESCE(@lng, longitude)
      WHERE user_id = @uid
      ''',
      substitutionValues: {
        'uid': mitraId,
        'name': body['name'],
        'address': body['address'],
        'phone': body['contact_phone'],
        'isOpen': body['is_open'],
        'image': body['image_url'],
        'lat': body['latitude'],
        'lng': body['longitude'],
      },
    );

    if (affected == 0) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Toko tidak ditemukan'},
      );
    }

    return Response.json(body: {'success': true, 'message': 'Toko diperbarui'});
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Mitra vendor update error: $e');
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
