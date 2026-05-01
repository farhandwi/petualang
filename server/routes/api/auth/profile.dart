import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// PUT /api/auth/profile
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.put) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

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
    final body = await context.request.json() as Map<String, dynamic>;

    final conn = await Database.connection;
    // Map JSON payload to database fields. We update everything the user sends.
    await conn.query(
      '''
      UPDATE users SET 
        name = COALESCE(@name, name),
        phone = COALESCE(@phone, phone),
        nik = COALESCE(@nik, nik),
        date_of_birth = COALESCE(@dateOfBirth, date_of_birth),
        gender = COALESCE(@gender, gender),
        ktp_address = COALESCE(@ktpAddress, ktp_address),
        domicile_address = COALESCE(@domicileAddress, domicile_address),
        emergency_contact_name = COALESCE(@emergencyContactName, emergency_contact_name),
        emergency_contact_phone = COALESCE(@emergencyContactPhone, emergency_contact_phone),
        height_cm = COALESCE(@heightCm, height_cm),
        weight_kg = COALESCE(@weightKg, weight_kg),
        updated_at = NOW()
      WHERE id = @id
      ''',
      substitutionValues: {
        'id': userId,
        'name': body['name'],
        'phone': body['phone'],
        'nik': body['nik'],
        'dateOfBirth': body['date_of_birth'] != null ? DateTime.tryParse(body['date_of_birth']) : null,
        'gender': body['gender'],
        'ktpAddress': body['ktp_address'],
        'domicileAddress': body['domicile_address'],
        'emergencyContactName': body['emergency_contact_name'],
        'emergencyContactPhone': body['emergency_contact_phone'],
        'heightCm': body['height_cm'],
        'weightKg': body['weight_kg'],
      },
    );

    // Fetch the updated user data to return
    final results = await conn.query(
      '''
      SELECT id, name, email, phone, profile_picture, nik, date_of_birth, gender, 
             ktp_address, domicile_address, emergency_contact_name, emergency_contact_phone, 
             height_cm, weight_kg, level, exp, is_active, created_at
      FROM users 
      WHERE id = @id
      ''',
      substitutionValues: {'id': userId},
    );
    
    final user = results.first;

    return Response.json(
      body: {
        'success': true,
        'message': 'Profil berhasil diperbarui',
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
          'level': user[14],
          'exp': user[15],
          'is_active': user[16],
          'created_at': (user[17] as DateTime?)?.toIso8601String(),
        },
      },
    );
  } catch (e) {
    print('Update profile error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan sistem'},
    );
  }
}
