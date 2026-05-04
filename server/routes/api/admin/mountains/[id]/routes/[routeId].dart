import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// PATCH, DELETE /api/admin/mountains/[id]/routes/[routeId]
Future<Response> onRequest(RequestContext context, String id, String routeId) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  final auth = AuthGuard.requireRole(context, ['admin']);
  if (!auth.isOk) return auth.errorResponse!;

  final mountainId = int.tryParse(id);
  final rId = int.tryParse(routeId);
  if (mountainId == null || rId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID tidak valid'},
    );
  }

  if (context.request.method == HttpMethod.patch) {
    return _update(context, mountainId, rId);
  }
  if (context.request.method == HttpMethod.delete) {
    return _delete(mountainId, rId);
  }

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}

Future<Response> _update(RequestContext context, int mountainId, int routeId) async {
  try {
    final body = json.decode(await context.request.body()) as Map<String, dynamic>;
    final conn = await Database.connection;
    await conn.query(
      '''
      UPDATE mountain_routes SET
        name = COALESCE(@name, name),
        description = COALESCE(@description, description)
      WHERE id = @id AND mountain_id = @mountainId
      ''',
      substitutionValues: {
        'id': routeId,
        'mountainId': mountainId,
        'name': body['name'],
        'description': body['description'],
      },
    );
    return Response.json(body: {'success': true, 'message': 'Jalur diperbarui'});
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Admin route update error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

Future<Response> _delete(int mountainId, int routeId) async {
  try {
    final conn = await Database.connection;
    final affected = await conn.execute(
      'DELETE FROM mountain_routes WHERE id = @id AND mountain_id = @mountainId',
      substitutionValues: {'id': routeId, 'mountainId': mountainId},
    );
    if (affected == 0) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Jalur tidak ditemukan'},
      );
    }
    return Response.json(body: {'success': true, 'message': 'Jalur dihapus'});
  } catch (e) {
    print('Admin route delete error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
