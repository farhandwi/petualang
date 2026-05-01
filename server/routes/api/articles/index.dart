import 'package:dart_frog/dart_frog.dart';
import '../../../lib/db/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
        statusCode: 405, body: {'message': 'Method not allowed'});
  }

  try {
    final conn = await Database.connection;
    final queryParams = context.request.url.queryParameters;

    final search = queryParams['search'];
    final category = queryParams['category'];

    // Default page & limit
    final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
    final limit = int.tryParse(queryParams['limit'] ?? '10') ?? 10;
    final offset = (page - 1) * limit;

    String sql = '''
      SELECT id, title, content, category, image_url, author, view_count, likes_count, comments_count, share_count, created_at
      FROM articles
      WHERE 1=1
    ''';

    Map<String, dynamic> substitutionValues = {
      'limit': limit,
      'offset': offset,
    };

    if (search != null && search.isNotEmpty) {
      sql += ' AND (title ILIKE @search OR content ILIKE @search)';
      substitutionValues['search'] = '%\$search%';
    }

    if (category != null &&
        category.isNotEmpty &&
        category.toLowerCase() != 'semua') {
      sql += ' AND category = @category';
      substitutionValues['category'] = category;
    }

    sql += ' ORDER BY created_at DESC LIMIT @limit OFFSET @offset';

    final result = await conn.mappedResultsQuery(sql,
        substitutionValues: substitutionValues);

    final articles = result.map((row) {
      final map = row['articles'] ?? {};
      if (map['created_at'] != null)
        map['created_at'] = map['created_at'].toIso8601String();
      return map;
    }).toList();

    // Get total count
    String countSql = 'SELECT COUNT(*) as count FROM articles WHERE 1=1';
    if (search != null && search.isNotEmpty)
      countSql += ' AND (title ILIKE @search OR content ILIKE @search)';
    if (category != null &&
        category.isNotEmpty &&
        category.toLowerCase() != 'semua')
      countSql += ' AND category = @category';

    final countResult = await conn.mappedResultsQuery(countSql,
        substitutionValues: substitutionValues);
    final totalCount =
        countResult.isNotEmpty ? countResult.first['']!['count'] as int : 0;

    // Get unique categories for the filter
    final categoriesResult = await conn.mappedResultsQuery('''
      SELECT DISTINCT category FROM articles WHERE category IS NOT NULL
    ''');
    final categories = categoriesResult
        .map((row) => row['articles']!['category'] as String)
        .toList();
    if (!categories.contains('Semua')) {
      categories.insert(0, 'Semua');
    }

    return Response.json(body: {
      'status': 'success',
      'data': articles,
      'meta': {
        'page': page,
        'limit': limit,
        'total': totalCount,
      },
      'categories': categories,
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'status': 'error', 'message': e.toString()},
    );
  }
}
