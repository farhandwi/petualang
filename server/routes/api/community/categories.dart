import 'package:dart_frog/dart_frog.dart';

/// GET /api/community/categories — daftar kategori statis untuk filter & form create.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  const categories = [
    'Hiking & Trekking',
    'Camping & Outdoor',
    'Running',
    'Fotografi',
    'Climbing',
    'Lainnya',
  ];

  return Response.json(body: {'success': true, 'data': categories});
}
