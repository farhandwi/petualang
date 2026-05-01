import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';

/// GET /api/buddies/[id] — detail buddy post + applications list
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

  final buddyId = int.tryParse(id);
  if (buddyId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID tidak valid'},
    );
  }

  try {
    final conn = await Database.connection;
    final results = await conn.mappedResultsQuery('''
      SELECT
        bp.id, bp.user_id, bp.mountain_id, bp.title, bp.description,
        bp.target_date, bp.max_buddies, bp.current_buddies, bp.status, bp.created_at,
        u.name AS user_name, u.profile_picture AS user_picture, u.level AS user_level,
        m.name AS mountain_name, m.location AS mountain_location, m.image_url AS mountain_image
      FROM buddy_posts bp
      LEFT JOIN users u ON u.id = bp.user_id
      LEFT JOIN mountains m ON m.id = bp.mountain_id
      WHERE bp.id = @id
      LIMIT 1
    ''', substitutionValues: {'id': buddyId});

    if (results.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Buddy post tidak ditemukan'},
      );
    }

    final row = results.first;
    final bp = Map<String, dynamic>.from(row['bp'] ?? row['buddy_posts'] ?? {});
    final u = Map<String, dynamic>.from(row['u'] ?? row['users'] ?? {});
    final m = Map<String, dynamic>.from(row['m'] ?? row['mountains'] ?? {});
    if (bp['target_date'] != null) {
      bp['target_date'] = bp['target_date'].toString().substring(0, 10);
    }
    if (bp['created_at'] != null) bp['created_at'] = bp['created_at'].toIso8601String();
    bp['user_name'] = u['user_name'] ?? u['name'];
    bp['user_picture'] = u['user_picture'] ?? u['profile_picture'];
    bp['user_level'] = u['user_level'] ?? u['level'];
    bp['mountain_name'] = m['mountain_name'] ?? m['name'];
    bp['mountain_location'] = m['mountain_location'] ?? m['location'];
    bp['mountain_image'] = m['mountain_image'] ?? m['image_url'];

    // Fetch applications
    final appResults = await conn.mappedResultsQuery('''
      SELECT
        ba.id, ba.applicant_id, ba.message, ba.status, ba.created_at,
        u.name AS applicant_name, u.profile_picture AS applicant_picture, u.level AS applicant_level
      FROM buddy_applications ba
      LEFT JOIN users u ON u.id = ba.applicant_id
      WHERE ba.buddy_post_id = @id
      ORDER BY ba.created_at DESC
    ''', substitutionValues: {'id': buddyId});

    final applications = appResults.map((r) {
      final ba = Map<String, dynamic>.from(r['ba'] ?? r['buddy_applications'] ?? {});
      final au = Map<String, dynamic>.from(r['u'] ?? r['users'] ?? {});
      if (ba['created_at'] != null) ba['created_at'] = ba['created_at'].toIso8601String();
      ba['applicant_name'] = au['applicant_name'] ?? au['name'];
      ba['applicant_picture'] = au['applicant_picture'] ?? au['profile_picture'];
      ba['applicant_level'] = au['applicant_level'] ?? au['level'];
      return ba;
    }).toList();

    bp['applications'] = applications;

    return Response.json(body: {
      'success': true,
      'data': bp,
    });
  } catch (e) {
    print('Buddy detail error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Gagal memuat detail'},
    );
  }
}
