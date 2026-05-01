import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';

/// GET /api/events/[id] — detail event
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  final eventId = int.tryParse(id);
  if (eventId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID tidak valid'},
    );
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
      WHERE e.id = @id
      LIMIT 1
    ''', substitutionValues: {'id': eventId});

    if (results.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Event tidak ditemukan'},
      );
    }

    final row = results.first;
    final e = Map<String, dynamic>.from(row['e'] ?? row['events'] ?? {});
    final u = Map<String, dynamic>.from(row['u'] ?? row['users'] ?? {});
    if (e['event_date'] != null) e['event_date'] = e['event_date'].toIso8601String();
    if (e['created_at'] != null) e['created_at'] = e['created_at'].toIso8601String();
    e['organizer_name'] = u['organizer_name'] ?? u['name'];
    e['organizer_picture'] = u['organizer_picture'] ?? u['profile_picture'];

    return Response.json(body: {
      'success': true,
      'data': e,
    });
  } catch (err) {
    print('Event detail error: $err');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Gagal memuat event'},
    );
  }
}
