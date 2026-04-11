import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.get) {
    return _getMountains(context);
  }
  return Response.json(
    statusCode: 405, 
    body: {'status': 'error', 'message': 'Method Not Allowed'},
  );
}

Future<Response> _getMountains(RequestContext context) async {
  try {
    final conn = await Database.connection;
    
    // Fetch mountains
    final mountainResults = await conn.mappedResultsQuery(
      'SELECT id, name, location, elevation, difficulty, price, image_url, description FROM mountains ORDER BY id ASC'
    );

    // Fetch all routes for these mountains
    final routeResults = await conn.mappedResultsQuery(
      'SELECT id, mountain_id, name, description FROM mountain_routes'
    );

    final mountains = mountainResults.map((mRow) {
      final m = mRow['mountains']!;
      final mountainId = m['id'] as int;
      
      // Filter routes for this mountain
      final routes = routeResults
          .where((rRow) => rRow['mountain_routes']!['mountain_id'] == mountainId)
          .map((rRow) {
            final r = rRow['mountain_routes']!;
            return {
              'id': r['id'],
              'name': r['name'],
              'description': r['description'],
            };
          })
          .toList();

      return {
        'id': m['id'],
        'name': m['name'],
        'location': m['location'],
        'elevation': m['elevation'],
        'difficulty': m['difficulty'],
        'price': (m['price'] is num) ? (m['price'] as num).toDouble() : double.parse(m['price'].toString()),
        'image_url': m['image_url'],
        'description': m['description'],
        'routes': routes,
      };
    }).toList();

    return Response.json(body: {
      'status': 'success',
      'data': mountains,
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'status': 'error',
        'message': 'Failed to fetch mountains: $e',
      },
    );
  }
}
