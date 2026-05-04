import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// GET, PATCH, DELETE /api/admin/mountains/[id]
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  final auth = AuthGuard.requireRole(context, ['admin']);
  if (!auth.isOk) return auth.errorResponse!;

  final mountainId = int.tryParse(id);
  if (mountainId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID gunung tidak valid'},
    );
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _detail(mountainId);
    case HttpMethod.patch:
      return _update(context, mountainId);
    case HttpMethod.delete:
      return _delete(mountainId);
    default:
      return Response.json(
        statusCode: 405,
        body: {'success': false, 'message': 'Method not allowed'},
      );
  }
}

Future<Response> _detail(int id) async {
  try {
    final conn = await Database.connection;
    final results = await conn.query(
      '''
      SELECT id, name, location, elevation, difficulty, price, image_url,
             description, is_featured, rating,
             external_booking_url, use_external_booking
      FROM mountains WHERE id = @id
      ''',
      substitutionValues: {'id': id},
    );

    if (results.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Gunung tidak ditemukan'},
      );
    }

    final m = results.first;
    return Response.json(
      body: {
        'success': true,
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
  } catch (e) {
    print('Admin mountain detail error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

Future<Response> _update(RequestContext context, int id) async {
  try {
    final body = json.decode(await context.request.body()) as Map<String, dynamic>;
    final conn = await Database.connection;
    await conn.query(
      '''
      UPDATE mountains SET
        name = COALESCE(@name, name),
        location = COALESCE(@location, location),
        elevation = COALESCE(@elevation, elevation),
        difficulty = COALESCE(@difficulty, difficulty),
        price = COALESCE(@price, price),
        image_url = COALESCE(@image, image_url),
        description = COALESCE(@description, description),
        is_featured = COALESCE(@featured, is_featured),
        rating = COALESCE(@rating, rating),
        external_booking_url = COALESCE(@extUrl, external_booking_url),
        use_external_booking = COALESCE(@useExt, use_external_booking)
      WHERE id = @id
      ''',
      substitutionValues: {
        'id': id,
        'name': body['name'],
        'location': body['location'],
        'elevation': body['elevation'],
        'difficulty': body['difficulty'],
        'price': body['price'],
        'image': body['image_url'],
        'description': body['description'],
        'featured': body['is_featured'],
        'rating': body['rating'],
        'extUrl': body['external_booking_url'],
        'useExt': body['use_external_booking'],
      },
    );
    return Response.json(body: {'success': true, 'message': 'Gunung diperbarui'});
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Admin mountain update error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

Future<Response> _delete(int id) async {
  try {
    final conn = await Database.connection;
    final result = await conn.execute(
      'DELETE FROM mountains WHERE id = @id',
      substitutionValues: {'id': id},
    );
    if (result == 0) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Gunung tidak ditemukan'},
      );
    }
    return Response.json(body: {'success': true, 'message': 'Gunung dihapus'});
  } catch (e) {
    print('Admin mountain delete error: $e');
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
