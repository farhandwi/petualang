import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';

/// GET /api/rentals/items
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'status': 'error', 'message': 'Method Not Allowed'},
    );
  }

  try {
    // Optional query filters
    final category = context.request.url.queryParameters['category'];
    final mountainId = context.request.url.queryParameters['mountain_id'];
    final vendorId = context.request.url.queryParameters['vendor_id'];
    
    final conn = await Database.connection;
    String query = 'SELECT id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition FROM rental_items';
    final Map<String, dynamic> substitutionValues = {};
    final conditions = <String>[];

    if (category != null && category.isNotEmpty && category != 'Semua') {
      conditions.add('category = @category');
      substitutionValues['category'] = category;
    }
    
    if (mountainId != null && mountainId.isNotEmpty) {
      conditions.add('(mountain_id = @mountainId OR mountain_id IS NULL)');
      substitutionValues['mountainId'] = int.tryParse(mountainId) ?? 0;
    }

    if (vendorId != null && vendorId.isNotEmpty) {
      conditions.add('vendor_id = @vendorId');
      substitutionValues['vendorId'] = int.tryParse(vendorId) ?? 0;
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' ORDER BY id ASC';

    final results = await conn.query(query, substitutionValues: substitutionValues);

    final items = results.map((row) {
      return {
        'id': row[0],
        'name': row[1],
        'category': row[2],
        'description': row[3],
        'price_per_day': (row[4] is num) ? (row[4] as num).toDouble() : double.parse(row[4].toString()),
        'image_url': row[5],
        'stock': row[6],
        'available_stock': row[7],
        'brand': row[8],
        'condition': row[9],
      };
    }).toList();

    return Response.json(body: {
      'status': 'success',
      'data': items,
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'status': 'error',
        'message': 'Failed to fetch rental items: $e',
      },
    );
  }
}
