import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();
  String? _token;

  void setToken(String? token) {
    if (_token == token) return;
    _token = token;
  }

  // Dashboard
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? get dashboard => _dashboard;

  /// Convenience: jumlah verifikasi pending dari dashboard payload.
  int get pendingVerificationCount {
    final users = _dashboard?['users'] as Map?;
    return (users?['pending_verifications'] as int?) ?? 0;
  }

  int get pendingReportCount =>
      (_dashboard?['pending_reports'] as int?) ?? 0;

  // Verifications
  List<Map<String, dynamic>> _verifications = [];
  List<Map<String, dynamic>> get verifications => _verifications;

  // Users
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> get users => _users;

  // Mountains
  List<Map<String, dynamic>> _mountains = [];
  List<Map<String, dynamic>> get mountains => _mountains;

  // Reports
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> get reports => _reports;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> fetchDashboard() async {
    if (_token == null) return;
    _setLoading(true);
    _dashboard = await _service.getDashboard(_token!);
    _setLoading(false);
  }

  Future<void> fetchVerifications({String status = 'pending'}) async {
    if (_token == null) return;
    _setLoading(true);
    _verifications = await _service.getVerifications(_token!, status: status);
    _setLoading(false);
  }

  Future<bool> actionVerification(int userId, String action) async {
    if (_token == null) return false;
    final ok = await _service.actionVerification(_token!, userId: userId, action: action);
    if (ok) {
      _verifications.removeWhere((u) => u['id'] == userId);
      notifyListeners();
    }
    return ok;
  }

  Future<void> fetchUsers({String role = 'all', String active = 'all', String q = ''}) async {
    if (_token == null) return;
    _setLoading(true);
    _users = await _service.getUsers(_token!, role: role, active: active, q: q);
    _setLoading(false);
  }

  Future<bool> updateUser(int userId, {bool? isActive, String? role}) async {
    if (_token == null) return false;
    final ok = await _service.updateUser(_token!, userId, isActive: isActive, role: role);
    if (ok) {
      final idx = _users.indexWhere((u) => u['id'] == userId);
      if (idx >= 0) {
        if (isActive != null) _users[idx]['is_active'] = isActive;
        if (role != null) _users[idx]['role'] = role;
        notifyListeners();
      }
    }
    return ok;
  }

  Future<void> fetchMountains() async {
    if (_token == null) return;
    _setLoading(true);
    _mountains = await _service.getMountains(_token!);
    _setLoading(false);
  }

  Future<bool> createMountain(Map<String, dynamic> body) async {
    if (_token == null) return false;
    final ok = await _service.createMountain(_token!, body);
    if (ok) await fetchMountains();
    return ok;
  }

  Future<bool> updateMountain(int id, Map<String, dynamic> body) async {
    if (_token == null) return false;
    final ok = await _service.updateMountain(_token!, id, body);
    if (ok) await fetchMountains();
    return ok;
  }

  Future<bool> deleteMountain(int id) async {
    if (_token == null) return false;
    final ok = await _service.deleteMountain(_token!, id);
    if (ok) {
      _mountains.removeWhere((m) => m['id'] == id);
      notifyListeners();
    }
    return ok;
  }

  Future<List<Map<String, dynamic>>> fetchMountainRoutes(int mountainId) async {
    if (_token == null) return [];
    return _service.getMountainRoutes(_token!, mountainId);
  }

  Future<bool> createMountainRoute(int mountainId, Map<String, dynamic> body) async {
    if (_token == null) return false;
    return _service.createMountainRoute(_token!, mountainId, body);
  }

  Future<bool> deleteMountainRoute(int mountainId, int routeId) async {
    if (_token == null) return false;
    return _service.deleteMountainRoute(_token!, mountainId, routeId);
  }

  Future<void> fetchReports({String status = 'pending'}) async {
    if (_token == null) return;
    _setLoading(true);
    _reports = await _service.getReports(_token!, status: status);
    _setLoading(false);
  }

  Future<bool> actionReport(int reportId, String action) async {
    if (_token == null) return false;
    final ok = await _service.actionReport(_token!, reportId, action);
    if (ok) {
      _reports.removeWhere((r) => r['id'] == reportId);
      notifyListeners();
    }
    return ok;
  }
}
