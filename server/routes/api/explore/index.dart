import 'package:dart_frog/dart_frog.dart';
import '../../../lib/db/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
        statusCode: 405, body: {'message': 'Method not allowed'});
  }

  try {
    final conn = await Database.connection;

    // 1. Get Top / Popular Mountains (For now, all mountains)
    final mountainsResult = await conn.mappedResultsQuery('''
      SELECT id, name, location, elevation, difficulty, price, image_url, description
      FROM mountains
      ORDER BY id ASC
      LIMIT 5
    ''');
    final mountains = mountainsResult.map((row) => row['mountains']).toList();

    // 2. Get Upcoming Open Trips
    final tripsResult = await conn.mappedResultsQuery('''
      SELECT id, mountain_id, title, description, start_date, end_date, price, max_participants, current_participants, status, image_url, created_at
      FROM open_trips
      WHERE status = 'open' AND start_date >= CURRENT_DATE
      ORDER BY start_date ASC
      LIMIT 5
    ''');
    final trips = tripsResult.map((row) {
      final map = row['open_trips'] ?? {};
      if (map['start_date'] != null)
        map['start_date'] = map['start_date'].toIso8601String();
      if (map['end_date'] != null)
        map['end_date'] = map['end_date'].toIso8601String();
      if (map['created_at'] != null)
        map['created_at'] = map['created_at'].toIso8601String();
      return map;
    }).toList();

    // 3. Get Articles / News (Top 10 Trending)
    final articlesResult = await conn.mappedResultsQuery('''
      SELECT id, title, content, category, image_url, author, view_count, likes_count, comments_count, share_count, created_at
      FROM articles
      ORDER BY view_count DESC, created_at DESC
      LIMIT 10
    ''');
    final articles = articlesResult.map((row) {
      final map = row['articles'] ?? {};
      if (map['created_at'] != null)
        map['created_at'] = map['created_at'].toIso8601String();
      return map;
    }).toList();

    return Response.json(body: {
      'status': 'success',
      'data': {
        'popular_mountains': mountains,
        'open_trips': trips,
        'articles': articles,
      }
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'status': 'error', 'message': e.toString()},
    );
  }
}
