import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';

/// Dilempar saat Google Sign-In gagal (bukan user cancel).
class GoogleSignInException implements Exception {
  GoogleSignInException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Wrapper tipis di atas `GoogleSignIn` plugin.
///
/// Dipakai oleh `AuthProvider.loginWithGoogle` untuk mendapatkan `id_token`
/// yang lalu dikirim ke endpoint `/api/auth/google_login`.
class GoogleSignInService {
  GoogleSignInService()
      : _googleSignIn = GoogleSignIn(
          // `serverClientId` WAJIB di-set agar `id_token` punya `aud` = Web
          // Client ID. Tanpa ini, di Android/iOS `aud`-nya akan jadi Client ID
          // platform-specific, dan server harus menerima 3 audience berbeda.
          // Pakai Web Client ID saja → konsisten lintas platform.
          //
          // Catatan: di Web, `serverClientId` di-ignore — plugin pakai meta
          // tag `google-signin-client_id` di index.html.
          serverClientId: kIsWeb
              ? null
              : (AppConfig.googleWebClientId.isEmpty
                  ? null
                  : AppConfig.googleWebClientId),
          scopes: const ['email', 'profile'],
        );

  final GoogleSignIn _googleSignIn;

  /// Trigger Google Sign-In flow & ambil `id_token`.
  ///
  /// - Return `null` kalau user cancel (UI tidak perlu tampilkan error).
  /// - Throw [GoogleSignInException] kalau ada error config / native error
  ///   (UI harus tampilkan pesan error).
  Future<String?> signInAndGetIdToken() async {
    // Validasi config — di mobile, kalau Web Client ID tidak di-set,
    // plugin akan error tanpa pesan yang jelas. Cegah lebih awal.
    if (!kIsWeb && AppConfig.googleWebClientId.isEmpty) {
      throw GoogleSignInException(
        'Google Web Client ID belum di-set. Run: '
        'flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=<WEB_CLIENT_ID>.apps.googleusercontent.com',
      );
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // user cancel
        debugPrint('GoogleSignIn: user cancelled');
        return null;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw GoogleSignInException(
          'Google tidak mengembalikan id_token. '
          'Cek: serverClientId benar, SHA-1 fingerprint sudah didaftarkan di '
          'Google Cloud Console untuk Android Client ID.',
        );
      }
      debugPrint('GoogleSignIn success: ${account.email}');
      return idToken;
    } on GoogleSignInException {
      rethrow;
    } catch (e) {
      // Native plugin errors (PlatformException dengan code "sign_in_failed",
      // status 10 = DEVELOPER_ERROR, dst). Jangan ditelan — surface ke UI.
      debugPrint('GoogleSignIn native error: $e');
      throw GoogleSignInException(
        'Google Sign-In gagal: $e\n\n'
        'Cek SHA-1 fingerprint sudah didaftarkan di Android Client ID & '
        'package name = com.example.petualang.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore — sign out best-effort
    }
  }
}
