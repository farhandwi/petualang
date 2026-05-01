import 'dart:io' as dart_io;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_sign_in_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, onboarding }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _onboardingKey = 'has_seen_onboarding';

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _token;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool _isLoading = false;
  bool get isLoading => _isLoading || _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Check connection to API and load user from storage
  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final hasSeenOnboarding = await _storage.read(key: _onboardingKey);
      if (hasSeenOnboarding == null) {
        _status = AuthStatus.onboarding;
      } else {
        final savedToken = await _storage.read(key: _tokenKey);
        if (savedToken != null) {
          final profile = await _authService.getProfile(savedToken);
          if (profile != null) {
            _token = savedToken;
            _user = profile;
            _status = AuthStatus.authenticated;
          } else {
            await _storage.delete(key: _tokenKey);
            _status = AuthStatus.unauthenticated;
          }
        } else {
          _status = AuthStatus.unauthenticated;
        }
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Login
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email: email, password: password);

    _isLoading = false;

    if (result.success && result.token != null) {
      _token = result.token;
      _user = result.user;
      _status = AuthStatus.authenticated;
      await _storage.write(key: _tokenKey, value: result.token);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  /// Login with Google
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final idToken = await _googleSignInService.signInAndGetIdToken();
      if (idToken == null) {
        // user cancel — silent (no error toast)
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _authService.loginWithGoogle(idToken);
      _isLoading = false;

      if (result.success && result.token != null) {
        _token = result.token;
        _user = result.user;
        _status = AuthStatus.authenticated;
        await _storage.write(key: _tokenKey, value: result.token);
        notifyListeners();
        return true;
      }

      _errorMessage = result.message;
      notifyListeners();
      return false;
    } on GoogleSignInException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal login dengan Google: $e';
      notifyListeners();
      return false;
    }
  }

  /// Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      phone: phone,
    );

    _isLoading = false;

    if (result.success && result.token != null) {
      _token = result.token;
      _user = result.user;
      _status = AuthStatus.authenticated;
      await _storage.write(key: _tokenKey, value: result.token);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  /// Update Profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_token == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.updateProfile(_token!, data);

    _isLoading = false;

    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  /// Upload gambar (KTP / selfie) ke server, kembalikan URL
  Future<String?> uploadImage(dart_io.File imageFile) async {
    if (_token == null) return null;
    return _authService.uploadImageFile(_token!, imageFile);
  }

  /// Submit verifikasi identitas (KYC)
  Future<bool> verifyIdentity(Map<String, dynamic> data) async {
    if (_token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.verifyIdentity(_token!, data);

    _isLoading = false;

    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  /// Forgot Password
  Future<AuthResult> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.forgotPassword(email);

    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.message;
    }
    notifyListeners();
    return result;
  }

  /// Reset Password
  Future<AuthResult> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.resetPassword(
      email: email, 
      token: token, 
      newPassword: newPassword,
    );

    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.message;
    }
    notifyListeners();
    return result;
  }

  /// Logout
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _googleSignInService.signOut();
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _storage.write(key: _onboardingKey, value: 'true');
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
