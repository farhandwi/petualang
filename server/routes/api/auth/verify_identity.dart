import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// POST /api/auth/verify-identity
/// Submit data verifikasi identitas user (KYC)
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

    final name = body['name'] as String?;
    final nik = body['nik'] as String?;
    final birthPlace = body['birth_place'] as String?;
    final ktpPhotoUrl = body['ktp_photo_url'] as String?;
    final selfieKtpUrl = body['selfie_ktp_url'] as String?;

    // Validasi field wajib
    if (name == null || name.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Nama lengkap wajib diisi'},
      );
    }
    if (nik == null || nik.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Nomor KTP wajib diisi'},
      );
    }
    if (nik.trim().length != 16) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Nomor KTP harus 16 digit'},
      );
    }
    if (birthPlace == null || birthPlace.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Tempat lahir wajib diisi'},
      );
    }
    if (ktpPhotoUrl == null || ktpPhotoUrl.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Foto KTP wajib diunggah'},
      );
    }
    if (selfieKtpUrl == null || selfieKtpUrl.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Foto selfie dengan KTP wajib diunggah'},
      );
    }

    final conn = await Database.connection;

    // Cek status verifikasi saat ini — jika sudah verified, tidak boleh submit ulang
    final currentUser = await conn.query(
      'SELECT verification_status FROM users WHERE id = @id',
      substitutionValues: {'id': userId},
    );
    if (currentUser.isNotEmpty) {
      final currentStatus = currentUser.first[0] as String? ?? 'unverified';
      if (currentStatus == 'verified') {
        return Response.json(
          statusCode: 400,
          body: {'success': false, 'message': 'Identitas Anda sudah terverifikasi.'},
        );
      }
    }

    // Update data verifikasi & set status ke 'pending'
    await conn.query(
      '''
      UPDATE users SET
        name = @name,
        nik = @nik,
        birth_place = @birthPlace,
        ktp_photo_url = @ktpPhotoUrl,
        selfie_ktp_url = @selfieKtpUrl,
        verification_status = 'pending',
        verified_at = NULL,
        updated_at = NOW()
      WHERE id = @id
      ''',
      substitutionValues: {
        'id': userId,
        'name': name.trim(),
        'nik': nik.trim(),
        'birthPlace': birthPlace.trim(),
        'ktpPhotoUrl': ktpPhotoUrl.trim(),
        'selfieKtpUrl': selfieKtpUrl.trim(),
      },
    );

    // Fetch updated user
    final results = await conn.query(
      '''
      SELECT id, name, email, phone, profile_picture, nik, date_of_birth, gender,
             ktp_address, domicile_address, emergency_contact_name, emergency_contact_phone,
             height_cm, weight_kg, level, exp, is_active, created_at,
             birth_place, ktp_photo_url, selfie_ktp_url, verification_status, verified_at
      FROM users WHERE id = @id
      ''',
      substitutionValues: {'id': userId},
    );

    if (results.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Pengguna tidak ditemukan'},
      );
    }

    final u = results.first;

    return Response.json(
      body: {
        'success': true,
        'message': 'Data verifikasi berhasil dikirim. Sedang dalam proses review.',
        'user': _buildUserJson(u),
      },
    );
  } catch (e) {
    print('Verify identity error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan sistem'},
    );
  }
}

Map<String, dynamic> _buildUserJson(dynamic u) {
  return {
    'id': u[0],
    'name': u[1],
    'email': u[2],
    'phone': u[3],
    'profile_picture': u[4],
    'nik': u[5],
    'date_of_birth': (u[6] as DateTime?)?.toIso8601String(),
    'gender': u[7],
    'ktp_address': u[8],
    'domicile_address': u[9],
    'emergency_contact_name': u[10],
    'emergency_contact_phone': u[11],
    'height_cm': u[12],
    'weight_kg': u[13],
    'level': u[14] ?? 1,
    'exp': u[15] ?? 0,
    'is_active': u[16] ?? true,
    'created_at': (u[17] as DateTime?)?.toIso8601String(),
    'birth_place': u[18],
    'ktp_photo_url': u[19],
    'selfie_ktp_url': u[20],
    'verification_status': u[21] ?? 'unverified',
    'verified_at': (u[22] as DateTime?)?.toIso8601String(),
  };
}
