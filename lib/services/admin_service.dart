import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AdminService {
  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ========== Dashboard ==========
  Future<Map<String, dynamic>?> getDashboard(String token) async {
    final res = await http
        .get(Uri.parse(AppConfig.adminDashboardEndpoint), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  // ========== Verifications ==========
  Future<List<Map<String, dynamic>>> getVerifications(
    String token, {
    String status = 'pending',
  }) async {
    final uri = Uri.parse(AppConfig.adminVerificationsEndpoint)
        .replace(queryParameters: {'status': status});
    final res = await http.get(uri, headers: _headers(token)).timeout(_timeout);
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
    return [];
  }

  Future<bool> actionVerification(
    String token, {
    required int userId,
    required String action,
  }) async {
    final res = await http
        .patch(
          Uri.parse(AppConfig.adminVerificationDetail(userId)),
          headers: _headers(token),
          body: json.encode({'action': action}),
        )
        .timeout(_timeout);
    final data = json.decode(res.body) as Map<String, dynamic>;
    return data['success'] == true;
  }

  // ========== Users ==========
  Future<List<Map<String, dynamic>>> getUsers(
    String token, {
    String role = 'all',
    String active = 'all',
    String q = '',
  }) async {
    final params = <String, String>{
      if (role != 'all') 'role': role,
      if (active != 'all') 'active': active,
      if (q.isNotEmpty) 'q': q,
    };
    final uri = Uri.parse(AppConfig.adminUsersEndpoint).replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers(token)).timeout(_timeout);
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
    return [];
  }

  Future<bool> updateUser(
    String token,
    int userId, {
    bool? isActive,
    String? role,
  }) async {
    final body = <String, dynamic>{};
    if (isActive != null) body['is_active'] = isActive;
    if (role != null) body['role'] = role;
    final res = await http
        .patch(
          Uri.parse(AppConfig.adminUserDetail(userId)),
          headers: _headers(token),
          body: json.encode(body),
        )
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }

  // ========== Mountains ==========
  Future<List<Map<String, dynamic>>> getMountains(String token) async {
    final res = await http
        .get(Uri.parse(AppConfig.adminMountainsEndpoint), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
    return [];
  }

  Future<bool> createMountain(
    String token,
    Map<String, dynamic> body,
  ) async {
    final res = await http
        .post(
          Uri.parse(AppConfig.adminMountainsEndpoint),
          headers: _headers(token),
          body: json.encode(body),
        )
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }

  Future<bool> updateMountain(
    String token,
    int id,
    Map<String, dynamic> body,
  ) async {
    final res = await http
        .patch(
          Uri.parse(AppConfig.adminMountainDetail(id)),
          headers: _headers(token),
          body: json.encode(body),
        )
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }

  Future<bool> deleteMountain(String token, int id) async {
    final res = await http
        .delete(Uri.parse(AppConfig.adminMountainDetail(id)), headers: _headers(token))
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }

  // ========== Mountain Routes ==========
  Future<List<Map<String, dynamic>>> getMountainRoutes(String token, int mountainId) async {
    final res = await http
        .get(Uri.parse(AppConfig.adminMountainRoutes(mountainId)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
    return [];
  }

  Future<bool> createMountainRoute(
    String token,
    int mountainId,
    Map<String, dynamic> body,
  ) async {
    final res = await http
        .post(
          Uri.parse(AppConfig.adminMountainRoutes(mountainId)),
          headers: _headers(token),
          body: json.encode(body),
        )
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }

  Future<bool> deleteMountainRoute(String token, int mountainId, int routeId) async {
    final res = await http
        .delete(
          Uri.parse(AppConfig.adminMountainRouteDetail(mountainId, routeId)),
          headers: _headers(token),
        )
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }

  // ========== Reports ==========
  Future<List<Map<String, dynamic>>> getReports(String token, {String status = 'pending'}) async {
    final uri = Uri.parse(AppConfig.adminReportsEndpoint)
        .replace(queryParameters: {'status': status});
    final res = await http.get(uri, headers: _headers(token)).timeout(_timeout);
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
    return [];
  }

  Future<bool> actionReport(String token, int reportId, String action) async {
    final res = await http
        .patch(
          Uri.parse(AppConfig.adminReportDetail(reportId)),
          headers: _headers(token),
          body: json.encode({'action': action}),
        )
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }

  Future<bool> deleteCommunityPost(String token, int postId) async {
    final res = await http
        .delete(Uri.parse(AppConfig.adminCommunityPostDelete(postId)), headers: _headers(token))
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }
}
