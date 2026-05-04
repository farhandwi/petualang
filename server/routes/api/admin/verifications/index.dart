import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/auth_guard.dart';

/// GET /api/admin/verifications — list user yang menunggu verifikasi identitas.
/// Query param `status` (default 'pending'): pending|verified|rejected|all
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

  final auth = AuthGuard.requireRole(context, ['admin']);
  if (!auth.isOk) return auth.errorResponse!;

  final status = context.request.uri.queryParameters['status'] ?? 'pending';

  try {
    final conn = await Database.connection;
    final whereClause = status == 'all'
        ? ''
        : 'WHERE verification_status = @status';
    final results = await conn.query(
      '''
      SELECT id, name, email, phone, profile_picture,
             nik, date_of_birth, gender, ktp_address, domicile_address,
             birth_place, ktp_photo_url, selfie_ktp_url,
             verification_status, verified_at, created_at
      FROM users
      $whereClause
      ORDER BY created_at DESC
      LIMIT 200
      ''',
      substitutionValues: status == 'all' ? {} : {'status': status},
    );

    final list = results.map((u) {
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
        'birth_place': u[10],
        'ktp_photo_url': u[11],
        'selfie_ktp_url': u[12],
        'verification_status': u[13],
        'verified_at': (u[14] as DateTime?)?.toIso8601String(),
        'created_at': (u[15] as DateTime?)?.toIso8601String(),
      };
    }).toList();

    return Response.json(body: {'success': true, 'data': list});
  } catch (e) {
    print('Admin verifications list error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Terjadi kesalahan server'},
    );
  }
}
