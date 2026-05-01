import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// POST /api/buddies/[id]/apply — apply to join a buddy post
/// Body: { message?: string }
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

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

  final buddyId = int.tryParse(id);
  if (buddyId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID tidak valid'},
    );
  }

  try {
    final body = json.decode(await context.request.body()) as Map<String, dynamic>;
    final message = (body['message'] as String?)?.trim();

    final conn = await Database.connection;

    // Validasi: buddy post ada & masih open & user bukan owner
    final check = await conn.query('''
      SELECT user_id, status, max_buddies, current_buddies
      FROM buddy_posts WHERE id = @id
    ''', substitutionValues: {'id': buddyId});

    if (check.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Buddy post tidak ditemukan'},
      );
    }

    final ownerId = check.first[0] as int;
    final status = check.first[1] as String;
    final maxBuddies = check.first[2] as int;
    final currentBuddies = check.first[3] as int;

    if (ownerId == userId) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Tidak bisa apply ke ajakan sendiri'},
      );
    }
    if (status != 'open') {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Ajakan sudah ditutup'},
      );
    }
    if (currentBuddies >= maxBuddies) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Slot sudah penuh'},
      );
    }

    // Insert application (UNIQUE constraint mencegah duplikat)
    try {
      await conn.execute('''
        INSERT INTO buddy_applications (buddy_post_id, applicant_id, message)
        VALUES (@bid, @aid, @msg)
      ''', substitutionValues: {
        'bid': buddyId,
        'aid': userId,
        'msg': message,
      });
    } catch (e) {
      // Kemungkinan UNIQUE violation
      return Response.json(
        statusCode: 409,
        body: {'success': false, 'message': 'Anda sudah pernah apply'},
      );
    }

    return Response.json(body: {
      'success': true,
      'message': 'Permintaan berhasil dikirim',
    });
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Buddy apply error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Gagal mengirim permintaan'},
    );
  }
}
