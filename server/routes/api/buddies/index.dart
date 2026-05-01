import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET  /api/buddies  — list buddy posts
///   Query: filter=upcoming|all (default upcoming), limit=20
/// POST /api/buddies  — create buddy post (auth required)
///   Body: { mountain_id, title, description, target_date (YYYY-MM-DD), max_buddies }
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method == HttpMethod.get) {
    return _handleGet(context);
  }
  if (context.request.method == HttpMethod.post) {
    return _handlePost(context);
  }
  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}

Future<Response> _handleGet(RequestContext context) async {
  final params = context.request.uri.queryParameters;
  final filter = params['filter'] ?? 'upcoming';
  final limit = int.tryParse(params['limit'] ?? '20') ?? 20;

  final whereClause = filter == 'all'
      ? ''
      : "WHERE bp.target_date >= CURRENT_DATE AND bp.status = 'open'";

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
      $whereClause
      ORDER BY bp.target_date ASC
      LIMIT @limit
    ''', substitutionValues: {'limit': limit});

    final buddies = results.map(_mapBuddyRow).toList();

    return Response.json(body: {
      'success': true,
      'data': buddies,
    });
  } catch (e) {
    print('Buddies list error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Gagal memuat data'},
    );
  }
}

Future<Response> _handlePost(RequestContext context) async {
  final token = JwtHelper.extractToken(context.request.headers['Authorization']);
  if (token == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Token tidak ditemukan'},
    );
  }
  final payload = JwtHelper.verifyToken(token);
  if (payload == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Token tidak valid'},
    );
  }
  final userId = payload['sub'] as int;

  try {
    final body = json.decode(await context.request.body()) as Map<String, dynamic>;
    final title = (body['title'] as String?)?.trim();
    final description = (body['description'] as String?)?.trim();
    final mountainId = body['mountain_id'] as int?;
    final targetDateStr = body['target_date'] as String?;
    final maxBuddies = body['max_buddies'] as int? ?? 1;

    if (title == null || title.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Judul wajib diisi'},
      );
    }
    if (targetDateStr == null) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Tanggal target wajib diisi'},
      );
    }
    final targetDate = DateTime.tryParse(targetDateStr);
    if (targetDate == null) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Format tanggal tidak valid'},
      );
    }

    final conn = await Database.connection;
    final result = await conn.query('''
      INSERT INTO buddy_posts (user_id, mountain_id, title, description, target_date, max_buddies)
      VALUES (@uid, @mid, @title, @desc, @date, @max)
      RETURNING id
    ''', substitutionValues: {
      'uid': userId,
      'mid': mountainId,
      'title': title,
      'desc': description,
      'date': targetDate,
      'max': maxBuddies,
    });

    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'message': 'Berhasil membuat ajakan',
        'id': result.first[0],
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Buddy create error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Gagal membuat ajakan'},
    );
  }
}

Map<String, dynamic> _mapBuddyRow(Map<String, Map<String, dynamic>> row) {
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
  return bp;
}
