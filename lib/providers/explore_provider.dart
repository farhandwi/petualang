import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/explore_model.dart';

class ExploreProvider extends ChangeNotifier {
  ExploreDataResponse? _exploreData;
  bool _isLoading = false;
  String? _error;

  ExploreDataResponse? get exploreData => _exploreData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchExploreData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrlApi}/explore'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['status'] == 'success') {
          _exploreData = ExploreDataResponse.fromJson(body['data']);
        } else {
          _error = 'Gagal memuat data: ${body['status']}';
        }
      } else {
        _error = 'Terjadi kesalahan sistem (${response.statusCode})';
      }
    } catch (e, stackTrace) {
      print('Exception in ExploreProvider: $e');
      print('Stacktrace: $stackTrace');
      _error = 'Gagal terhubung ke server. Periksa koneksi internet Anda. ($e)';
    }

    _isLoading = false;
    notifyListeners();
  }
}
