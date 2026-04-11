import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/password_helper.dart';

/// POST /api/auth/reset_password
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
    final token = body['token'] as String?;
    final newPassword = body['newPassword'] as String?;

    if (email == null || email.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Email wajib diisi'},
      );
    }
    if (token == null || token.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Token OTP wajib diisi'},
      );
    }
    if (newPassword == null || newPassword.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Password baru wajib diisi'},
      );
    }
    if (newPassword.length < 6) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Password minimal 6 karakter'},
      );
    }

    final conn = await Database.connection;

    // Verify token and expiration
    final results = await conn.query(
      '''
      SELECT id, reset_token_expires_at 
      FROM users 
      WHERE email = @email AND reset_token = @token AND is_active = TRUE
      ''',
      substitutionValues: {
        'email': email,
        'token': token,
      },
    );

    if (results.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Token OTP salah atau tidak valid'},
      );
    }

    final expiresAt = results.first[1] as DateTime?;

    if (expiresAt == null || expiresAt.isBefore(DateTime.now().toUtc())) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Token OTP sudah kadaluarsa'},
      );
    }

    // Hash the new password
    final salt = PasswordHelper.generateSalt();
    final hash = PasswordHelper.hashPassword(newPassword, salt);

    // Update the user's password and clear the reset token
    await conn.execute(
      '''
      UPDATE users 
      SET password_hash = @hash, 
          password_salt = @salt,
          reset_token = NULL,
          reset_token_expires_at = NULL,
          updated_at = NOW()
      WHERE email = @email
      ''',
      substitutionValues: {
        'hash': hash,
        'salt': salt,
        'email': email,
      },
    );

    return Response.json(
      body: {
        'success': true,
        'message': 'Sandi Anda berhasil diatur ulang. Silakan masuk.',
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Reset password error: \$e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
