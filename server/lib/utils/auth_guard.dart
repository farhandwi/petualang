import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// Hasil autentikasi sukses: user id + role dari JWT.
class AuthInfo {
  final int userId;
  final String role;
  final String email;
  final String name;

  AuthInfo({
    required this.userId,
    required this.role,
    required this.email,
    required this.name,
  });
}

/// Hasil pemeriksaan auth — entah berhasil dengan [info]
/// atau gagal dengan [errorResponse] yang siap dikirim balik.
class AuthCheck {
  final AuthInfo? info;
  final Response? errorResponse;

  AuthCheck.ok(this.info) : errorResponse = null;
  AuthCheck.fail(this.errorResponse) : info = null;

  bool get isOk => info != null;
}

class AuthGuard {
  /// Verifikasi token dari header Authorization. Return [AuthCheck.ok]
  /// jika valid, atau [AuthCheck.fail] dengan response 401 jika tidak.
  static AuthCheck requireAuth(RequestContext context) {
    final authHeader = context.request.headers['Authorization'];
    final token = JwtHelper.extractToken(authHeader);

    if (token == null) {
      return AuthCheck.fail(
        Response.json(
          statusCode: 401,
          body: {'success': false, 'message': 'Akses ditolak. Token tidak ditemukan'},
        ),
      );
    }

    final payload = JwtHelper.verifyToken(token);
    if (payload == null) {
      return AuthCheck.fail(
        Response.json(
          statusCode: 401,
          body: {'success': false, 'message': 'Token tidak valid atau sudah kadaluarsa'},
        ),
      );
    }

    final userId = payload['sub'] as int?;
    if (userId == null) {
      return AuthCheck.fail(
        Response.json(
          statusCode: 401,
          body: {'success': false, 'message': 'Token payload tidak valid'},
        ),
      );
    }

    return AuthCheck.ok(
      AuthInfo(
        userId: userId,
        role: (payload['role'] as String?) ?? 'user',
        email: (payload['email'] as String?) ?? '',
        name: (payload['name'] as String?) ?? '',
      ),
    );
  }

  /// Verifikasi auth + role harus salah satu dari [allowedRoles].
  /// Return AuthCheck.fail dengan 403 jika role tidak diizinkan.
  static AuthCheck requireRole(
    RequestContext context,
    List<String> allowedRoles,
  ) {
    final check = requireAuth(context);
    if (!check.isOk) return check;

    final role = check.info!.role;
    if (!allowedRoles.contains(role)) {
      return AuthCheck.fail(
        Response.json(
          statusCode: 403,
          body: {
            'success': false,
            'message': 'Akses ditolak. Anda tidak memiliki izin untuk operasi ini.',
          },
        ),
      );
    }

    return check;
  }
}
