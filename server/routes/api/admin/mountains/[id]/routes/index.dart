import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// GET, POST /api/admin/mountains/[id]/routes
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  final auth = AuthGuard.requireRole(context, ['admin']);
  if (!auth.isOk) return auth.errorResponse!;

  final mountainId = int.tryParse(id);
  if (mountainId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID gunung tidak valid'},
    );
  }

  if (context.request.method == HttpMethod.get) return _list(mountainId);
  if (context.request.method == HttpMethod.post) return _create(context, mountainId);

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}

Future<Response> _list(int mountainId) async {
  try {
    final conn = await Database.connection;
    final results = await conn.query(
      'SELECT id, name, description FROM mountain_routes WHERE mountain_id = @id ORDER BY id ASC',
      substitutionValues: {'id': mountainId},
    );
    final list = results.map((r) => {
      'id': r[0],
      'name': r[1],
      'description': r[2],
    }).toList();
    return Response.json(body: {'success': true, 'data': list});
  } catch (e) {
    print('Admin routes list error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

Future<Response> _create(RequestContext context, int mountainId) async {
  try {
    final body = json.decode(await context.request.body()) as Map<String, dynamic>;
    final name = (body['name'] as String?)?.trim();
    final description = (body['description'] as String?)?.trim() ?? '';

    if (name == null || name.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Nama jalur wajib diisi'},
      );
    }

    final conn = await Database.connection;
    final result = await conn.query(
      '''
      INSERT INTO mountain_routes (mountain_id, name, description)
      VALUES (@mountainId, @name, @description)
      RETURNING id, name, description
      ''',
      substitutionValues: {
        'mountainId': mountainId,
        'name': name,
        'description': description,
      },
    );
    final r = result.first;
    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'message': 'Jalur ditambahkan',
        'data': {'id': r[0], 'name': r[1], 'description': r[2]},
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Admin routes create error: $e');
    if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
      return Response.json(
        statusCode: 409,
        body: {'success': false, 'message': 'Jalur dengan nama sama sudah ada'},
      );
    }
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
