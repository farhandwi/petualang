import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/jwt_helper.dart';
import 'package:petualang_server/utils/password_helper.dart';

/// POST /api/auth/register
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

    // Validate required fields
    final name = (body['name'] as String?)?.trim();
    final email = (body['email'] as String?)?.trim().toLowerCase();
    final phone = (body['phone'] as String?)?.trim();
    final password = body['password'] as String?;
    final confirmPassword = body['confirm_password'] as String?;

    if (name == null || name.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Nama lengkap wajib diisi'},
      );
    }

    if (email == null || email.isEmpty || !email.contains('@')) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Format email tidak valid'},
      );
    }

    if (password == null || password.length < 8) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Password minimal 8 karakter',
        },
      );
    }

    if (password != confirmPassword) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Konfirmasi password tidak cocok'},
      );
    }

    final conn = await Database.connection;

    // Check if email already exists
    final existing = await conn.query(
      'SELECT id FROM users WHERE email = @email',
      substitutionValues: {'email': email},
    );

    if (existing.isNotEmpty) {
      return Response.json(
        statusCode: 409,
        body: {'success': false, 'message': 'Email sudah terdaftar'},
      );
    }

    // Hash password
    final salt = PasswordHelper.generateSalt();
    final passwordHash = PasswordHelper.hashPassword(password, salt);

    // Insert new user
    final result = await conn.query(
      '''
      INSERT INTO users (name, email, phone, password_hash, password_salt)
      VALUES (@name, @email, @phone, @hash, @salt)
      RETURNING id, name, email, phone, created_at
      ''',
      substitutionValues: {
        'name': name,
        'email': email,
        'phone': phone,
        'hash': passwordHash,
        'salt': salt,
      },
    );

    final user = result.first;
    final userId = user[0] as int;
    final userName = user[1] as String;
    final userEmail = user[2] as String;

    // Generate JWT
    final token = JwtHelper.generateToken(
      userId: userId,
      email: userEmail,
      name: userName,
    );

    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'message': 'Registrasi berhasil! Selamat datang, $userName!',
        'token': token,
        'user': {
          'id': userId,
          'name': userName,
          'email': userEmail,
          'phone': user[3],
        },
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Register error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
