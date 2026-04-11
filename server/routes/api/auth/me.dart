import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// GET /api/auth/me - Get current user profile
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  // Extract and verify JWT token
  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);

  if (token == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Akses ditolak. Token tidak ditemukan'},
    );
  }

  final payload = JwtHelper.verifyToken(token);
  if (payload == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Token tidak valid atau sudah kadaluarsa'},
    );
  }

  final userId = payload['sub'] as int;

  try {
    final conn = await Database.connection;
    final results = await conn.query(
      '''
      SELECT id, name, email, phone, profile_picture, nik, date_of_birth, gender, 
             ktp_address, domicile_address, emergency_contact_name, emergency_contact_phone, 
             height_cm, weight_kg, is_active, created_at
      FROM users 
      WHERE id = @id AND is_active = true
      ''',
      substitutionValues: {'id': userId},
    );

    if (results.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Pengguna tidak ditemukan'},
      );
    }

    final user = results.first;
    return Response.json(
      body: {
        'success': true,
        'user': {
          'id': user[0],
          'name': user[1],
          'email': user[2],
          'phone': user[3],
          'profile_picture': user[4],
          'nik': user[5],
          'date_of_birth': (user[6] as DateTime?)?.toIso8601String(),
          'gender': user[7],
          'ktp_address': user[8],
          'domicile_address': user[9],
          'emergency_contact_name': user[10],
          'emergency_contact_phone': user[11],
          'height_cm': user[12],
          'weight_kg': user[13],
          'is_active': user[14],
          'created_at': (user[15] as DateTime?)?.toIso8601String(),
        },
      },
    );
  } catch (e) {
    print('Get me error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
