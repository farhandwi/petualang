import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';

/// GET /api/events — list events (default: upcoming only)
/// Query params:
///   - filter: 'upcoming' (default) | 'past' | 'all'
///   - limit: int (default 20)
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  final params = context.request.uri.queryParameters;
  final filter = params['filter'] ?? 'upcoming';
  final limit = int.tryParse(params['limit'] ?? '20') ?? 20;

  String whereClause;
  switch (filter) {
    case 'past':
      whereClause = 'WHERE event_date < NOW()';
      break;
    case 'all':
      whereClause = '';
      break;
    case 'upcoming':
    default:
      whereClause = "WHERE event_date >= NOW() AND status = 'open'";
  }

  try {
    final conn = await Database.connection;
    final results = await conn.mappedResultsQuery('''
      SELECT
        e.id, e.title, e.description, e.location, e.event_date, e.image_url,
        e.organizer_id, e.max_participants, e.current_participants, e.status, e.created_at,
        u.name AS organizer_name, u.profile_picture AS organizer_picture
      FROM events e
      LEFT JOIN users u ON u.id = e.organizer_id
      $whereClause
      ORDER BY e.event_date ASC
      LIMIT @limit
    ''', substitutionValues: {'limit': limit});

    final events = results.map((row) {
      final e = Map<String, dynamic>.from(row['e'] ?? row['events'] ?? {});
      final u = Map<String, dynamic>.from(row['u'] ?? row['users'] ?? {});
      if (e['event_date'] != null) e['event_date'] = e['event_date'].toIso8601String();
      if (e['created_at'] != null) e['created_at'] = e['created_at'].toIso8601String();
      e['organizer_name'] = u['organizer_name'] ?? u['name'];
      e['organizer_picture'] = u['organizer_picture'] ?? u['profile_picture'];
      return e;
    }).toList();

    return Response.json(body: {
      'success': true,
      'data': events,
    });
  } catch (e) {
    print('Events list error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Gagal memuat events'},
    );
  }
}
