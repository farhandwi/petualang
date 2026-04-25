import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/db/database.dart';
import '../../../../lib/utils/jwt_helper.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.get) {
    return _getComments(context, id);
  } else if (context.request.method == HttpMethod.post) {
    return _addComment(context, id);
  }
  return Response.json(statusCode: 405, body: {'message': 'Method not allowed'});
}

Future<Response> _getComments(RequestContext context, String id) async {
  try {
    final articleId = int.tryParse(id);
    if (articleId == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid ID'});
    }

    final conn = await Database.connection;
    final sql = '''
      SELECT 
        c.id, c.content, c.created_at,
        u.id as user_id, u.name as user_name, u.profile_picture as user_avatar
      FROM article_comments c
      JOIN users u ON c.user_id = u.id
      WHERE c.article_id = @article_id
      ORDER BY c.created_at DESC
    ''';
    
    final result = await conn.mappedResultsQuery(
      sql,
      substitutionValues: {'article_id': articleId},
    );

    final comments = result.map((row) {
      final c = row['article_comments'] ?? {};
      final u = row['users'] ?? {};
      final empty = row[''] ?? {};
      return {
        'id': c['id'] ?? empty['id'],
        'content': c['content'] ?? empty['content'],
        'created_at': (c['created_at'] ?? empty['created_at'])?.toIso8601String(),
        'user': {
          'id': u['id'] ?? empty['user_id'],
          'name': u['name'] ?? empty['user_name'],
          'avatar': u['profile_picture'] ?? empty['user_avatar'],
        }
      };
    }).toList();

    return Response.json(body: {'status': 'success', 'data': comments});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'status': 'error', 'message': e.toString()},
    );
  }
}

Future<Response> _addComment(RequestContext context, String id) async {
  try {
    final articleId = int.tryParse(id);
    if (articleId == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid ID'});
    }

    final authHeader = context.request.headers['Authorization'];
    final token = JwtHelper.extractToken(authHeader);
    final payload = token != null ? JwtHelper.verifyToken(token) : null;
    final userId = payload?['sub'] as int?;

    if (userId == null) {
      return Response.json(statusCode: 401, body: {'message': 'Unauthorized'});
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final content = body['content'] as String?;

    if (content == null || content.isEmpty) {
      return Response.json(statusCode: 400, body: {'message': 'Content required'});
    }

    final conn = await Database.connection;
    await conn.execute(
      '''
      INSERT INTO article_comments (article_id, user_id, content) 
      VALUES (@article_id, @user_id, @content)
      ''',
      substitutionValues: {
        'article_id': articleId,
        'user_id': userId,
        'content': content,
      },
    );

    await conn.execute(
      'UPDATE articles SET comments_count = comments_count + 1 WHERE id = @id',
      substitutionValues: {'id': articleId},
    );

    return Response.json(body: {'status': 'success', 'message': 'Comment added'});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'status': 'error', 'message': e.toString()},
    );
  }
}
