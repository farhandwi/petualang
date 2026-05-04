import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// GET, PATCH, DELETE /api/mitra/me/items/[id] — guard: item harus milik
/// vendor yang user_id-nya = mitra yang sedang login.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  final auth = AuthGuard.requireRole(context, ['mitra']);
  if (!auth.isOk) return auth.errorResponse!;
  final mitraId = auth.info!.userId;

  final itemId = int.tryParse(id);
  if (itemId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID alat tidak valid'},
    );
  }

  final ownership = await _verifyOwnership(itemId, mitraId);
  if (!ownership) {
    return Response.json(
      statusCode: 403,
      body: {'success': false, 'message': 'Alat ini bukan milik toko Anda'},
    );
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _detail(itemId);
    case HttpMethod.patch:
      return _update(context, itemId);
    case HttpMethod.delete:
      return _delete(itemId);
    default:
      return Response.json(
        statusCode: 405,
        body: {'success': false, 'message': 'Method not allowed'},
      );
  }
}

Future<bool> _verifyOwnership(int itemId, int mitraId) async {
  final conn = await Database.connection;
  final result = await conn.query(
    '''
    SELECT 1 FROM rental_items i
    JOIN rental_vendors v ON v.id = i.vendor_id
    WHERE i.id = @itemId AND v.user_id = @mitraId
    ''',
    substitutionValues: {'itemId': itemId, 'mitraId': mitraId},
  );
  return result.isNotEmpty;
}

Future<Response> _detail(int itemId) async {
  try {
    final conn = await Database.connection;
    final results = await conn.query(
      '''
      SELECT id, name, category, description, price_per_day, image_url,
             stock, available_stock, brand, condition, mountain_id
      FROM rental_items WHERE id = @id
      ''',
      substitutionValues: {'id': itemId},
    );
    final r = results.first;
    return Response.json(
      body: {
        'success': true,
        'data': {
          'id': r[0],
          'name': r[1],
          'category': r[2],
          'description': r[3],
          'price_per_day': _toDouble(r[4]),
          'image_url': r[5],
          'stock': r[6],
          'available_stock': r[7],
          'brand': r[8],
          'condition': r[9],
          'mountain_id': r[10],
        },
      },
    );
  } catch (e) {
    print('Mitra item detail error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

Future<Response> _update(RequestContext context, int itemId) async {
  try {
    final body = json.decode(await context.request.body()) as Map<String, dynamic>;
    final conn = await Database.connection;
    await conn.query(
      '''
      UPDATE rental_items SET
        name = COALESCE(@name, name),
        category = COALESCE(@category, category),
        description = COALESCE(@description, description),
        price_per_day = COALESCE(@price, price_per_day),
        image_url = COALESCE(@image, image_url),
        stock = COALESCE(@stock, stock),
        available_stock = COALESCE(@avail, available_stock),
        brand = COALESCE(@brand, brand),
        condition = COALESCE(@condition, condition)
      WHERE id = @id
      ''',
      substitutionValues: {
        'id': itemId,
        'name': body['name'],
        'category': body['category'],
        'description': body['description'],
        'price': body['price_per_day'],
        'image': body['image_url'],
        'stock': body['stock'],
        'avail': body['available_stock'],
        'brand': body['brand'],
        'condition': body['condition'],
      },
    );
    return Response.json(body: {'success': true, 'message': 'Alat diperbarui'});
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Mitra item update error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

Future<Response> _delete(int itemId) async {
  try {
    final conn = await Database.connection;
    await conn.execute(
      'DELETE FROM rental_items WHERE id = @id',
      substitutionValues: {'id': itemId},
    );
    return Response.json(body: {'success': true, 'message': 'Alat dihapus'});
  } catch (e) {
    print('Mitra item delete error: $e');
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
