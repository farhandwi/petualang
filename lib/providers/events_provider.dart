import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/event_model.dart';

class EventsProvider extends ChangeNotifier {
  List<EventModel> _events = [];
  EventModel? _selectedEvent;
  bool _isLoading = false;
  String? _error;

  List<EventModel> get events => _events;
  EventModel? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEvents({String filter = 'upcoming'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrlApi}/events?filter=$filter'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final list = body['data'] as List;
          _events = list
              .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          _error = body['message'] as String? ?? 'Gagal memuat events';
        }
      } else {
        _error = 'Server error (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Tidak dapat terhubung ke server';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<EventModel?> fetchEventDetail(int id) async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrlApi}/events/$id'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          _selectedEvent = EventModel.fromJson(body['data'] as Map<String, dynamic>);
          notifyListeners();
          return _selectedEvent;
        }
      }
    } catch (_) {}
    return null;
  }
}
