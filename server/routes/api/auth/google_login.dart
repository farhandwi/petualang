import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/services/google_auth_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// POST /api/auth/google-login
///
/// Body: `{ "id_token": "<google id token>" }`
///
/// Flow:
///   1. Verifikasi id_token ke Google.
///   2. Cari user by google_id, kalau tidak ada cari by email lalu auto-link,
///      kalau email juga tidak ada → auto-create user baru.
///   3. Generate JWT internal & balikan token + user (format sama dengan /login).
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

    final idToken = (body['id_token'] as String?)?.trim();
    if (idToken == null || idToken.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'id_token wajib diisi'},
      );
    }

    final googleUser = await GoogleAuthService.verifyIdToken(idToken);
    if (googleUser == null) {
      return Response.json(
        statusCode: 401,
        body: {'success': false, 'message': 'Token Google tidak valid'},
      );
    }

    final conn = await Database.connection;

    // 1) Cari by google_id
    var rows = await conn.query(
      _selectUserSql('WHERE google_id = @gid'),
      substitutionValues: {'gid': googleUser.googleId},
    );

    // 2) Belum ada → cari by email & auto-link
    if (rows.isEmpty) {
      final byEmail = await conn.query(
        '''
        SELECT id, is_active FROM users WHERE email = @email
        ''',
        substitutionValues: {'email': googleUser.email},
      );

      if (byEmail.isNotEmpty) {
        final existingId = byEmail.first[0] as int;
        final existingActive = byEmail.first[1] as bool;
        if (!existingActive) {
          return Response.json(
            statusCode: 403,
            body: {'success': false, 'message': 'Akun Anda telah dinonaktifkan'},
          );
        }
        await conn.execute(
          '''
          UPDATE users
          SET google_id = @gid,
              google_picture_url = COALESCE(@pic, google_picture_url),
              auth_provider = CASE WHEN auth_provider = 'email' THEN 'both' ELSE auth_provider END,
              updated_at = NOW()
          WHERE id = @id
          ''',
          substitutionValues: {
            'gid': googleUser.googleId,
            'pic': googleUser.pictureUrl,
            'id': existingId,
          },
        );

        rows = await conn.query(
          _selectUserSql('WHERE id = @id'),
          substitutionValues: {'id': existingId},
        );
      } else {
        // 3) Tidak ada → auto-create
        rows = await conn.query(
          '''
          INSERT INTO users (
            name, email, google_id, google_picture_url, auth_provider, is_active
          ) VALUES (
            @name, @email, @gid, @pic, 'google', TRUE
          )
          RETURNING ${_userColumns()}
          ''',
          substitutionValues: {
            'name': googleUser.name,
            'email': googleUser.email,
            'gid': googleUser.googleId,
            'pic': googleUser.pictureUrl,
          },
        );
      }
    }

    if (rows.isEmpty) {
      return Response.json(
        statusCode: 500,
        body: {'success': false, 'message': 'Gagal memuat data user'},
      );
    }

    final user = rows.first;
    final isActive = user[7] as bool;
    if (!isActive) {
      return Response.json(
        statusCode: 403,
        body: {'success': false, 'message': 'Akun Anda telah dinonaktifkan'},
      );
    }

    final userId = user[0] as int;
    final userName = user[1] as String;
    final userEmail = user[2] as String;
    final googlePictureUrl = user[25] as String?;
    final userRole = (user[27] as String?) ?? 'user';

    final profilePicture = (user[6] as String?) ?? googlePictureUrl;

    final token = JwtHelper.generateToken(
      userId: userId,
      email: userEmail,
      name: userName,
      role: userRole,
    );

    return Response.json(
      body: {
        'success': true,
        'message': 'Login berhasil! Selamat datang, $userName!',
        'token': token,
        'user': {
          'id': userId,
          'name': userName,
          'email': userEmail,
          'phone': user[3],
          'profile_picture': profilePicture,
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
          'google_picture_url': googlePictureUrl,
          'auth_provider': user[26] ?? 'google',
          'role': userRole,
        },
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Format request tidak valid'},
    );
  } catch (e) {
    print('Google login error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}

String _userColumns() => '''
  id, name, email, phone, password_hash, password_salt,
  profile_picture, is_active,
  nik, date_of_birth, gender,
  ktp_address, domicile_address,
  emergency_contact_name, emergency_contact_phone,
  height_cm, weight_kg, level, exp, created_at,
  birth_place, ktp_photo_url, selfie_ktp_url,
  verification_status, verified_at,
  google_picture_url, auth_provider, role
''';

String _selectUserSql(String whereClause) => '''
SELECT ${_userColumns()}
FROM users
$whereClause
''';
