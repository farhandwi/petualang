import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// PATCH /api/admin/verifications/[id]
/// Body: `{ "action": "approve" | "reject" }`
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }
  if (context.request.method != HttpMethod.patch) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  final auth = AuthGuard.requireRole(context, ['admin']);
  if (!auth.isOk) return auth.errorResponse!;

  final userId = int.tryParse(id);
  if (userId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID pengguna tidak valid'},
    );
  }

  try {
    final bodyString = await context.request.body();
    final body = json.decode(bodyString) as Map<String, dynamic>;
    final action = body['action'] as String?;

    String newStatus;
    if (action == 'approve') {
      newStatus = 'verified';
    } else if (action == 'reject') {
      newStatus = 'rejected';
    } else {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Action harus approve atau reject'},
      );
    }

    final conn = await Database.connection;
    final result = await conn.query(
      '''
      UPDATE users SET
        verification_status = @status,
        verified_at = CASE WHEN @status = 'verified' THEN NOW() ELSE NULL END,
        updated_at = NOW()
      WHERE id = @id
      RETURNING id, name, email, verification_status, verified_at
      ''',
      substitutionValues: {'id': userId, 'status': newStatus},
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Pengguna tidak ditemukan'},
      );
    }

    final u = result.first;
    return Response.json(
      body: {
        'success': true,
        'message': action == 'approve'
            ? 'Verifikasi disetujui'
            : 'Verifikasi ditolak',
        'data': {
          'id': u[0],
          'name': u[1],
          'email': u[2],
          'verification_status': u[3],
          'verified_at': (u[4] as DateTime?)?.toIso8601String(),
        },
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Admin verification update error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
