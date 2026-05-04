import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// DELETE /api/admin/community/posts/[id] — hapus post komunitas (admin only).
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }
  if (context.request.method != HttpMethod.delete) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  final auth = AuthGuard.requireRole(context, ['admin']);
  if (!auth.isOk) return auth.errorResponse!;

  final postId = int.tryParse(id);
  if (postId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'ID post tidak valid'},
    );
  }

  try {
    final conn = await Database.connection;
    final affected = await conn.execute(
      'DELETE FROM community_posts WHERE id = @id',
      substitutionValues: {'id': postId},
    );

    if (affected == 0) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Post tidak ditemukan'},
      );
    }

    return Response.json(body: {'success': true, 'message': 'Post dihapus'});
  } catch (e) {
    print('Admin delete post error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
