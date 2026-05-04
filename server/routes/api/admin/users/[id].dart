import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// PATCH /api/admin/users/[id] — update user (is_active, role).
/// Body: `{ "is_active": bool?, "role": "user"|"mitra"|"admin"? }`
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
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

  if (context.request.method == HttpMethod.get) {
    return _getOne(userId);
  }
  if (context.request.method == HttpMethod.patch) {
    return _patch(context, userId, auth.info!.userId);
  }

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed'},
  );
}

Future<Response> _getOne(int userId) async {
  try {
    final conn = await Database.connection;
    final results = await conn.query(
      '''
      SELECT id, name, email, phone, profile_picture, is_active, role,
             verification_status, verified_at, level, exp, created_at,
             nik, date_of_birth, ktp_address, domicile_address
      FROM users
      WHERE id = @id
      ''',
      substitutionValues: {'id': userId},
    );

    if (results.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Pengguna tidak ditemukan'},
      );
    }

    final u = results.first;
    return Response.json(
      body: {
        'success': true,
        'data': {
          'id': u[0],
          'name': u[1],
          'email': u[2],
          'phone': u[3],
          'profile_picture': u[4],
          'is_active': u[5],
          'role': u[6],
          'verification_status': u[7],
          'verified_at': (u[8] as DateTime?)?.toIso8601String(),
          'level': u[9],
          'exp': u[10],
          'created_at': (u[11] as DateTime?)?.toIso8601String(),
          'nik': u[12],
          'date_of_birth': (u[13] as DateTime?)?.toIso8601String(),
          'ktp_address': u[14],
          'domicile_address': u[15],
        },
      },
    );
  } catch (e) {
    print('Admin user detail error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

Future<Response> _patch(RequestContext context, int targetId, int adminId) async {
  if (targetId == adminId) {
    return Response.json(
      statusCode: 400,
      body: {
        'success': false,
        'message': 'Tidak bisa mengubah akun admin Anda sendiri.',
      },
    );
  }

  try {
    final bodyString = await context.request.body();
    final body = json.decode(bodyString) as Map<String, dynamic>;

    final isActive = body['is_active'] as bool?;
    final role = body['role'] as String?;

    if (isActive == null && role == null) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Tidak ada field untuk diupdate'},
      );
    }

    if (role != null && !['user', 'mitra', 'admin'].contains(role)) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Role harus user, mitra, atau admin',
        },
      );
    }

    final conn = await Database.connection;
    final result = await conn.query(
      '''
      UPDATE users SET
        is_active = COALESCE(@isActive, is_active),
        role = COALESCE(@role, role),
        updated_at = NOW()
      WHERE id = @id
      RETURNING id, name, email, is_active, role
      ''',
      substitutionValues: {
        'id': targetId,
        'isActive': isActive,
        'role': role,
      },
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
        'message': 'Pengguna diperbarui',
        'data': {
          'id': u[0],
          'name': u[1],
          'email': u[2],
          'is_active': u[3],
          'role': u[4],
        },
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Admin user update error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
