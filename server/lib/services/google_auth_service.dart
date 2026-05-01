import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:petualang_server/utils/env_config.dart';

class GoogleUserInfo {
  GoogleUserInfo({
    required this.googleId,
    required this.email,
    required this.name,
    this.pictureUrl,
  });

  final String googleId;
  final String email;
  final String name;
  final String? pictureUrl;
}

class GoogleAuthService {
  static const _tokenInfoUrl = 'https://oauth2.googleapis.com/tokeninfo';
  static const _validIssuers = {'accounts.google.com', 'https://accounts.google.com'};

  /// Verifikasi id_token Google.
  /// Return null jika token invalid / `aud` tidak match / email belum verified.
  static Future<GoogleUserInfo?> verifyIdToken(String idToken) async {
    if (idToken.trim().isEmpty) return null;

    final allowedAudiences = EnvConfig.googleClientIds;
    if (allowedAudiences.isEmpty) {
      print('⚠️  GoogleAuthService: tidak ada GOOGLE_CLIENT_ID_* di .env');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$_tokenInfoUrl?id_token=$idToken'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('Google tokeninfo non-200: ${response.statusCode} ${response.body}');
        return null;
      }

      final payload = json.decode(response.body) as Map<String, dynamic>;

      final aud = payload['aud'] as String?;
      if (aud == null || !allowedAudiences.contains(aud)) {
        print('Google tokeninfo: aud "$aud" tidak match dengan client IDs yang terdaftar');
        return null;
      }

      final iss = payload['iss'] as String?;
      if (iss == null || !_validIssuers.contains(iss)) {
        return null;
      }

      final emailVerifiedRaw = payload['email_verified'];
      final emailVerified = emailVerifiedRaw == true || emailVerifiedRaw == 'true';
      if (!emailVerified) return null;

      final expRaw = payload['exp'];
      final exp = expRaw is int ? expRaw : int.tryParse('$expRaw');
      if (exp == null) return null;
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (exp < nowSec) return null;

      final sub = payload['sub'] as String?;
      final email = payload['email'] as String?;
      final name = (payload['name'] as String?) ?? (email?.split('@').first ?? 'User');
      final picture = payload['picture'] as String?;

      if (sub == null || email == null) return null;

      return GoogleUserInfo(
        googleId: sub,
        email: email.toLowerCase(),
        name: name,
        pictureUrl: picture,
      );
    } catch (e) {
      print('GoogleAuthService.verifyIdToken error: $e');
      return null;
    }
  }
}
