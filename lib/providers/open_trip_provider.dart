import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/explore_model.dart';
import 'auth_provider.dart';

class OpenTripProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  
  OpenTripProvider({required this.authProvider});

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> joinTrip(OpenTripModel trip) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = authProvider.token;
      if (token == null) {
        _error = 'Anda harus login terlebih dahulu';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrlApi}/open_trips/book'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'open_trip_id': trip.id,
          'user_id': authProvider.user?.id,
        }),
      );

      final Map<String, dynamic> body = json.decode(response.body);

      if (response.statusCode == 200 && body['status'] == 'success') {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = body['message'] ?? 'Gagal mendaftar trip';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan sistem: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
