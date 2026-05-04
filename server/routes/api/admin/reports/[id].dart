import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// PATCH /api/admin/reports/[id]
/// Body: `{ "action": "dismiss" | "takedown" }`
/// - dismiss: set status='dismissed', tidak hapus konten
/// - takedown: hapus post/comment/message terkait, set status='resolved'
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

  final reportId = int.tryParse(id);
  if (reportId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID laporan tidak valid'},
    );
  }

  try {
    final body = json.decode(await context.request.body()) as Map<String, dynamic>;
    final action = body['action'] as String?;

    if (action != 'dismiss' && action != 'takedown') {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Action harus dismiss atau takedown'},
      );
    }

    final conn = await Database.connection;

    if (action == 'takedown') {
      final reportRows = await conn.query(
        'SELECT post_id, comment_id, message_id FROM reports WHERE id = @id',
        substitutionValues: {'id': reportId},
      );

      if (reportRows.isEmpty) {
        return Response.json(
          statusCode: 404,
          body: {'success': false, 'message': 'Laporan tidak ditemukan'},
        );
      }

      final r = reportRows.first;
      final postId = r[0] as int?;
      final commentId = r[1] as int?;
      final messageId = r[2] as int?;

      if (postId != null) {
        await conn.execute(
          'DELETE FROM community_posts WHERE id = @id',
          substitutionValues: {'id': postId},
        );
      }
      if (commentId != null) {
        await conn.execute(
          'DELETE FROM community_comments WHERE id = @id',
          substitutionValues: {'id': commentId},
        );
      }
      if (messageId != null) {
        await conn.execute(
          'UPDATE chat_messages SET is_deleted = TRUE, content = \'[Dihapus oleh admin]\' WHERE id = @id',
          substitutionValues: {'id': messageId},
        );
      }
    }

    final newStatus = action == 'dismiss' ? 'dismissed' : 'resolved';
    await conn.execute(
      'UPDATE reports SET status = @status WHERE id = @id',
      substitutionValues: {'id': reportId, 'status': newStatus},
    );

    return Response.json(
      body: {
        'success': true,
        'message': action == 'dismiss'
            ? 'Laporan ditolak'
            : 'Laporan ditindaklanjuti, konten dihapus',
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Admin report action error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
