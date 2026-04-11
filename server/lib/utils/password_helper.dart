import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHelper {
  static const int _saltLength = 32;

  /// Generate a random salt
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(_saltLength, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Hash a password with a salt using SHA-256
  static String hashPassword(String password, String salt) {
    final combined = '$password:$salt:petualang_pepper_2024';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    
    // Double hash for extra security
    final combinedDigest = '$digest:$salt';
    final bytes2 = utf8.encode(combinedDigest);
    final digest2 = sha256.convert(bytes2);
    
    return digest2.toString();
  }

  /// Verify a password against a stored hash
  static bool verifyPassword(String password, String salt, String storedHash) {
    final computedHash = hashPassword(password, salt);
    return computedHash == storedHash;
  }
}
