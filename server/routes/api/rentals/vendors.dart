import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'dart:math' as math;

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  var p = 0.017453292519943295; // Math.PI / 180
  var a = 0.5 -
      math.cos((lat2 - lat1) * p) / 2 +
      math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
  return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
}

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: 405, body: {'status': 'error', 'message': 'Method Not Allowed'});
  }

  try {
    final lat = double.tryParse(context.request.url.queryParameters['lat'] ?? '');
    final lng = double.tryParse(context.request.url.queryParameters['lng'] ?? '');
    final searchQuery = context.request.url.queryParameters['q'];

    final conn = await Database.connection;
    
    // Subquery for categories
    String sql = '''
      SELECT 
        v.id, v.name, v.address, v.rating, v.review_count, v.is_open, v.image_url, v.latitude, v.longitude,
        (
          SELECT array_agg(cat) FROM (
            SELECT category AS cat FROM rental_items 
            WHERE vendor_id = v.id AND category IS NOT NULL 
            GROUP BY category 
            ORDER BY count(*) DESC 
            LIMIT 4
          ) sub
        ) AS top_categories
      FROM rental_vendors v
      WHERE 1=1
    ''';
    
    final Map<String, dynamic> substitutionValues = {};
    if (searchQuery != null && searchQuery.isNotEmpty) {
      sql += ' AND (v.name ILIKE @q OR v.address ILIKE @q)';
      substitutionValues['q'] = '%\$searchQuery%';
    }
    
    final results = await conn.query(sql, substitutionValues: substitutionValues);
    
    final vendors = results.map((row) {
      final vLat = row[7] != null ? double.parse(row[7].toString()) : null;
      final vLng = row[8] != null ? double.parse(row[8].toString()) : null;
      double? distance;
      if (lat != null && lng != null && vLat != null && vLng != null) {
        distance = calculateDistance(lat, lng, vLat, vLng);
      }
      
      return {
        'id': row[0],
        'name': row[1],
        'address': row[2],
        'rating': row[3] != null ? double.parse(row[3].toString()) : 0.0,
        'review_count': row[4] ?? 0,
        'is_open': row[5] ?? true,
        'image_url': row[6],
        'latitude': vLat,
        'longitude': vLng,
        'distance': distance,
        'categories': row[9] ?? [],
      };
    }).toList();

    // Sort by distance if lat/lng are provided
    if (lat != null && lng != null) {
      vendors.sort((a, b) {
        final d1 = a['distance'] as double?;
        final d2 = b['distance'] as double?;
        if (d1 == null) return 1;
        if (d2 == null) return -1;
        return d1.compareTo(d2);
      });
    }

    return Response.json(body: {
      'status': 'success',
      'data': vendors,
    });
  } catch (e) {
    return Response.json(statusCode: 500, body: {'status': 'error', 'message': e.toString()});
  }
}
