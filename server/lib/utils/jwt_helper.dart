import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class JwtHelper {
  static String get _secret =>
      Platform.environment['JWT_SECRET'] ?? 'petualang_jwt_secret_key_2024';

  /// Generate a JWT token for a user
  static String generateToken({
    required int userId,
    required String email,
    required String name,
    String role = 'user',
  }) {
    final jwt = JWT(
      {
        'sub': userId,
        'email': email,
        'name': name,
        'role': role,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
    );

    return jwt.sign(
      SecretKey(_secret),
      expiresIn: const Duration(days: 7),
    );
  }

  /// Verify and decode a JWT token
  /// Returns the payload map or null if invalid
  static Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));
      return jwt.payload as Map<String, dynamic>;
    } on JWTExpiredException {
      return null;
    } on JWTException {
      return null;
    }
  }

  /// Extract token from Authorization header
  static String? extractToken(String? authHeader) {
    if (authHeader == null || !authHeader.startsWith('Bearer ')) return null;
    return authHeader.substring(7);
  }
}
