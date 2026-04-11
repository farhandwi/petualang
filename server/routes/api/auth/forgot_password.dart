import 'dart:convert';
import 'dart:math';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';

/// POST /api/auth/forgot_password
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

    if (email == null || email.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Email wajib diisi'},
      );
    }

    final conn = await Database.connection;

    // Check if user exists
    final results = await conn.query(
      '''
      SELECT id 
      FROM users 
      WHERE email = @email AND is_active = TRUE
      ''',
      substitutionValues: {'email': email},
    );

    if (results.isEmpty) {
      // Return success anyway for security reasons (don't leak registered emails)
      // but in our development phase we might want to return an error for easier debugging.
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Akun dengan email ini tidak ditemukan.',
        },
      );
    }

    // Generate 6-digit OTP
    final random = Random.secure();
    final otp = (100000 + random.nextInt(900000)).toString();

    // Set expiration 15 minutes from now
    // PostgreSQL TIMESTAMPTZ expects ISO 8601 string
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 15)).toIso8601String();

    // Update the database
    await conn.execute(
      '''
      UPDATE users 
      SET reset_token = @token, reset_token_expires_at = @expires_at
      WHERE email = @email
      ''',
      substitutionValues: {
        'token': otp,
        'expires_at': expiresAt,
        'email': email,
      },
    );

    // Development output: We include the OTP in the API response 
    // because we don't have an email sending service configured yet.
    return Response.json(
      body: {
        'success': true,
        'message': 'Kode keamanan (OTP) telah dikirim ke email Anda.',
        'dev_otp': otp, // REMOVE IN PRODUCTION
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Forgot password error: \$e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
