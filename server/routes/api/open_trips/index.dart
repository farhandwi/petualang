import 'package:dart_frog/dart_frog.dart';
import '../../../lib/db/database.dart';

/// GET /api/open_trips
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: 405, body: {'message': 'Method not allowed'});
  }

  try {
    final conn = await Database.connection;

    final results = await conn.mappedResultsQuery('''
      SELECT id, mountain_id, title, description, start_date, end_date, price, max_participants, current_participants, status, image_url, created_at
      FROM open_trips
      WHERE status = 'open' AND start_date >= CURRENT_DATE
      ORDER BY start_date ASC
    ''');
    
    final trips = results.map((row) {
      final map = row['open_trips'] ?? {};
      if (map['start_date'] != null) map['start_date'] = map['start_date'].toIso8601String();
      if (map['end_date'] != null) map['end_date'] = map['end_date'].toIso8601String();
      if (map['created_at'] != null) map['created_at'] = map['created_at'].toIso8601String();
      return map;
    }).toList();

    return Response.json(body: {
      'status': 'success',
      'data': trips,
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'status': 'error', 'message': e.toString()},
    );
  }
}
