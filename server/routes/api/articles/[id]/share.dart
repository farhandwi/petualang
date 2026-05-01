import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/db/database.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'message': 'Method not allowed'});
  }

  try {
    final articleId = int.tryParse(id);
    if (articleId == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid ID'});
    }

    final conn = await Database.connection;
    await conn.execute(
      'UPDATE articles SET share_count = share_count + 1 WHERE id = @id',
      substitutionValues: {'id': articleId},
    );

    return Response.json(body: {'status': 'success', 'message': 'Share added'});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'status': 'error', 'message': e.toString()},
    );
  }
}
