import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/jwt_helper.dart';
import 'package:petualang_server/utils/password_helper.dart';

/// POST /api/auth/login
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  try {
    final bodyString = await context.request.body();
    final body = json.decode(bodyString) as Map<String, dynamic>;

    final email = (body['email'] as String?)?.trim().toLowerCase();
    final password = body['password'] as String?;

    if (email == null || email.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Email wajib diisi'},
      );
    }

    if (password == null || password.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Password wajib diisi'},
      );
    }

    final conn = await Database.connection;

    // Find user by email — ambil semua kolom profil
    final results = await conn.query(
      '''
      SELECT id, name, email, phone, password_hash, password_salt, 
             profile_picture, is_active,
             nik, date_of_birth, gender,
             ktp_address, domicile_address,
             emergency_contact_name, emergency_contact_phone,
             height_cm, weight_kg, level, exp, created_at,
             birth_place, ktp_photo_url, selfie_ktp_url,
             verification_status, verified_at
      FROM users 
      WHERE email = @email
      ''',
      substitutionValues: {'email': email},
    );

    if (results.isEmpty) {
      return Response.json(
        statusCode: 401,
        body: {
          'success': false,
          'message': 'Email atau password salah',
        },
      );
    }

    final user = results.first;
    final passwordHash = user[4] as String;
    final passwordSalt = user[5] as String;
    final isActive = user[7] as bool;

    if (!isActive) {
      return Response.json(
        statusCode: 403,
        body: {'success': false, 'message': 'Akun Anda telah dinonaktifkan'},
      );
    }

    // Verify password
    final isValid = PasswordHelper.verifyPassword(password, passwordSalt, passwordHash);
    if (!isValid) {
      return Response.json(
        statusCode: 401,
        body: {'success': false, 'message': 'Email atau password salah'},
      );
    }

    final userId = user[0] as int;
    final userName = user[1] as String;
    final userEmail = user[2] as String;

    // Generate JWT token
    final token = JwtHelper.generateToken(
      userId: userId,
      email: userEmail,
      name: userName,
    );

    return Response.json(
      body: {
        'success': true,
        'message': 'Login berhasil! Selamat datang kembali, $userName!',
        'token': token,
        'user': {
          'id': userId,
          'name': userName,
          'email': userEmail,
          'phone': user[3],
          'profile_picture': user[6],
          'nik': user[8],
          'date_of_birth': (user[9] as DateTime?)?.toIso8601String(),
          'gender': user[10],
          'ktp_address': user[11],
          'domicile_address': user[12],
          'emergency_contact_name': user[13],
          'emergency_contact_phone': user[14],
          'height_cm': user[15],
          'weight_kg': user[16],
          'level': user[17] ?? 1,
          'exp': user[18] ?? 0,
          'is_active': isActive,
          'created_at': (user[19] as DateTime?)?.toIso8601String(),
          'birth_place': user[20],
          'ktp_photo_url': user[21],
          'selfie_ktp_url': user[22],
          'verification_status': user[23] ?? 'unverified',
          'verified_at': (user[24] as DateTime?)?.toIso8601String(),
        },
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Login error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
