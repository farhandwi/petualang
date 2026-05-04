import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// GET, POST /api/mitra/me/items — list & tambah alat sewa toko mitra.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  final auth = AuthGuard.requireRole(context, ['mitra']);
  if (!auth.isOk) return auth.errorResponse!;
  final mitraId = auth.info!.userId;

  final vendorId = await _getVendorIdForMitra(mitraId);
  if (vendorId == null) {
    return Response.json(
      statusCode: 404,
      body: {'success': false, 'message': 'Toko mitra tidak ditemukan'},
    );
  }

  if (context.request.method == HttpMethod.get) return _list(vendorId);
  if (context.request.method == HttpMethod.post) return _create(context, vendorId);

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}

Future<int?> _getVendorIdForMitra(int mitraId) async {
  final conn = await Database.connection;
  final results = await conn.query(
    'SELECT id FROM rental_vendors WHERE user_id = @uid LIMIT 1',
    substitutionValues: {'uid': mitraId},
  );
  if (results.isEmpty) return null;
  return results.first[0] as int;
}

Future<Response> _list(int vendorId) async {
  try {
    final conn = await Database.connection;
    final results = await conn.query(
      '''
      SELECT id, name, category, description, price_per_day, image_url,
             stock, available_stock, brand, condition, mountain_id, created_at
      FROM rental_items
      WHERE vendor_id = @vid
      ORDER BY id DESC
      ''',
      substitutionValues: {'vid': vendorId},
    );

    final list = results.map((r) => {
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
      'created_at': (r[11] as DateTime?)?.toIso8601String(),
    }).toList();

    return Response.json(body: {'success': true, 'data': list});
  } catch (e) {
    print('Mitra items list error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

Future<Response> _create(RequestContext context, int vendorId) async {
  try {
    final body = json.decode(await context.request.body()) as Map<String, dynamic>;
    final name = (body['name'] as String?)?.trim();
    final category = (body['category'] as String?)?.trim();
    final pricePerDay = body['price_per_day'];
    final stock = body['stock'] as int? ?? 0;

    if (name == null ||
        name.isEmpty ||
        category == null ||
        category.isEmpty ||
        pricePerDay == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'name, category, price_per_day wajib diisi',
        },
      );
    }

    final conn = await Database.connection;
    final result = await conn.query(
      '''
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description,
                                 price_per_day, image_url, stock, available_stock,
                                 brand, condition)
      VALUES (@vid, @mid, @name, @category, @description,
              @price, @image, @stock, @stock, @brand, @condition)
      RETURNING id, name, category, description, price_per_day, image_url,
                stock, available_stock, brand, condition
      ''',
      substitutionValues: {
        'vid': vendorId,
        'mid': body['mountain_id'],
        'name': name,
        'category': category,
        'description': body['description'] ?? '',
        'price': pricePerDay,
        'image': body['image_url'] ?? '',
        'stock': stock,
        'brand': body['brand'] ?? 'No Brand',
        'condition': body['condition'] ?? 'Baik',
      },
    );

    final r = result.first;
    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'message': 'Alat ditambahkan',
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
        },
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Mitra item create error: $e');
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
