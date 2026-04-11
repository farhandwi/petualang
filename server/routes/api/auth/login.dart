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

    // Find user by email
    final results = await conn.query(
      '''
      SELECT id, name, email, phone, password_hash, password_salt, 
             profile_picture, is_active
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
