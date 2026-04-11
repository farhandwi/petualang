import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';

/// Global middleware: CORS headers + DB initialization
Handler middleware(Handler handler) {
  return (context) async {
    // Initialize DB connection on first request
    await Database.connection;

    final response = await handler(context);

    // Only set Content-Type: application/json if it's not already set.
    // This allows images and other static files to be served correctly.
    final contentType = response.headers['Content-Type'];
    final headers = {
      ...response.headers,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers':
          'Origin, Content-Type, Accept, Authorization',
    };

    if (contentType == null) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }

    return response.copyWith(headers: headers);
  };
}
