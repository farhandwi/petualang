import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_model.dart';

class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;

  AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });
}

class AuthService {
  static const Duration _timeout = Duration(seconds: 15);

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(_timeout);

      final data = json.decode(response.body) as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? 'Terjadi kesalahan';

      if (success && response.statusCode == 200) {
        final token = data['token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;
        return AuthResult(
          success: true,
          message: message,
          token: token,
          user: userData != null ? UserModel.fromJson(userData) : null,
        );
      }

      return AuthResult(success: false, message: message);
    } on Exception catch (e) {
      return AuthResult(
        success: false,
        message: _parseError(e),
      );
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'phone': phone,
        }),
      ).timeout(_timeout);

      final data = json.decode(response.body) as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? 'Terjadi kesalahan';

      if (success && response.statusCode == 201) {
        final token = data['token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;
        return AuthResult(
          success: true,
          message: message,
          token: token,
          user: userData != null ? UserModel.fromJson(userData) : null,
        );
      }

      return AuthResult(success: false, message: message);
    } on Exception catch (e) {
      return AuthResult(
        success: false,
        message: _parseError(e),
      );
    }
  }

  Future<UserModel?> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.meEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>?;
        return userData != null ? UserModel.fromJson(userData) : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<AuthResult> updateProfile(String token, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse(AppConfig.profileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(_timeout);

      final responseData = json.decode(response.body) as Map<String, dynamic>;
      final success = responseData['success'] as bool? ?? false;
      final message = responseData['message'] as String? ?? 'Terjadi kesalahan';

      if (success && response.statusCode == 200) {
        final userData = responseData['user'] as Map<String, dynamic>?;
        return AuthResult(
          success: true,
          message: message,
          user: userData != null ? UserModel.fromJson(userData) : null,
        );
      }

      return AuthResult(success: false, message: message);
    } on Exception catch (e) {
      return AuthResult(success: false, message: _parseError(e));
    }
  }

  Future<AuthResult> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.forgotPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      ).timeout(_timeout);

      final data = json.decode(response.body) as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? 'Terjadi kesalahan';

      if (success && response.statusCode == 200) {
        // For development, we might get the OTP back in the response
        final otp = data['dev_otp'] as String?;
        return AuthResult(success: true, message: message, token: otp);
      }

      return AuthResult(success: false, message: message);
    } on Exception catch (e) {
      return AuthResult(success: false, message: _parseError(e));
    }
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.resetPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'token': token,
          'newPassword': newPassword,
        }),
      ).timeout(_timeout);

      final data = json.decode(response.body) as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? 'Terjadi kesalahan';

      if (success && response.statusCode == 200) {
        return AuthResult(success: true, message: message);
      }

      return AuthResult(success: false, message: message);
    } on Exception catch (e) {
      return AuthResult(success: false, message: _parseError(e));
    }
  }

  String _parseError(Exception e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Tidak dapat terhubung ke server. Pastikan server berjalan.';
    }
    if (msg.contains('TimeoutException')) {
      return 'Request timeout. Periksa koneksi internet Anda.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  /// Upload satu file gambar ke /api/upload/image, kembalikan URL-nya
  Future<String?> uploadImageFile(String token, File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.uploadImageEndpoint),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['success'] == true && data['url'] != null) {
        return data['url'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Submit verifikasi identitas (KYC)
  Future<AuthResult> verifyIdentity(String token, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.verifyIdentityEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(_timeout);

      final responseData = json.decode(response.body) as Map<String, dynamic>;
      final success = responseData['success'] as bool? ?? false;
      final message = responseData['message'] as String? ?? 'Terjadi kesalahan';

      if (success && response.statusCode == 200) {
        final userData = responseData['user'] as Map<String, dynamic>?;
        return AuthResult(
          success: true,
          message: message,
          user: userData != null ? UserModel.fromJson(userData) : null,
        );
      }

      return AuthResult(success: false, message: message);
    } on Exception catch (e) {
      return AuthResult(success: false, message: _parseError(e));
    }
  }
}

