import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/buddy_post_model.dart';

class BuddiesProvider extends ChangeNotifier {
  List<BuddyPostModel> _buddies = [];
  BuddyPostModel? _selectedBuddy;
  bool _isLoading = false;
  bool _isCreating = false;
  String? _error;
  String? _token;

  List<BuddyPostModel> get buddies => _buddies;
  BuddyPostModel? get selectedBuddy => _selectedBuddy;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get error => _error;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _headers({bool auth = false}) => {
        'Content-Type': 'application/json',
        if (auth && _token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> fetchBuddies({String filter = 'upcoming'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.baseUrlApi}/buddies?filter=$filter'),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final list = body['data'] as List;
          _buddies = list
              .map((e) => BuddyPostModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          _error = body['message'] as String? ?? 'Gagal memuat data';
        }
      } else {
        _error = 'Server error (${response.statusCode})';
      }
    } catch (_) {
      _error = 'Tidak dapat terhubung ke server';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<BuddyPostModel?> fetchBuddyDetail(int id) async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrlApi}/buddies/$id'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          _selectedBuddy =
              BuddyPostModel.fromJson(body['data'] as Map<String, dynamic>);
          notifyListeners();
          return _selectedBuddy;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Returns null on success, error message on failure.
  Future<String?> createBuddy({
    required String title,
    String? description,
    int? mountainId,
    required DateTime targetDate,
    required int maxBuddies,
  }) async {
    if (_token == null) return 'Anda harus login terlebih dahulu';
    _isCreating = true;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrlApi}/buddies'),
            headers: _headers(auth: true),
            body: json.encode({
              'title': title,
              'description': description,
              'mountain_id': mountainId,
              'target_date':
                  targetDate.toIso8601String().substring(0, 10), // YYYY-MM-DD
              'max_buddies': maxBuddies,
            }),
          )
          .timeout(const Duration(seconds: 15));

      _isCreating = false;
      notifyListeners();

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        await fetchBuddies();
        return null;
      }
      return body['message'] as String? ?? 'Gagal membuat ajakan';
    } catch (_) {
      _isCreating = false;
      notifyListeners();
      return 'Terjadi kesalahan';
    }
  }

  /// Returns null on success, error message on failure.
  Future<String?> applyToBuddy(int buddyId, String? message) async {
    if (_token == null) return 'Anda harus login terlebih dahulu';

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrlApi}/buddies/$buddyId/apply'),
            headers: _headers(auth: true),
            body: json.encode({'message': message}),
          )
          .timeout(const Duration(seconds: 15));

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        await fetchBuddyDetail(buddyId);
        return null;
      }
      return body['message'] as String? ?? 'Gagal mengirim permintaan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}
