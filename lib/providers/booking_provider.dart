import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/mountain_model.dart';
import '../models/ticket_model.dart';
import '../models/upcoming_booking_model.dart';
import 'auth_provider.dart';

class BookingProvider with ChangeNotifier {
  final AuthProvider authProvider;
  
  BookingProvider({required this.authProvider});

  String _searchQuery = '';
  List<MountainModel> _mountains = [];
  List<UpcomingBookingModel> _upcomingBookings = [];
  bool _isLoading = false;
  bool _isLoadingUpcoming = false;
  String? _errorMessage;
  String? _lastPaymentUrl;

  String get searchQuery => _searchQuery;
  List<MountainModel> get mountains => _mountains;
  List<UpcomingBookingModel> get upcomingBookings => _upcomingBookings;
  bool get isLoading => _isLoading;
  bool get isLoadingUpcoming => _isLoadingUpcoming;
  String? get errorMessage => _errorMessage;
  String? get lastPaymentUrl => _lastPaymentUrl;

  List<MountainModel> get filteredMountains {
    if (_searchQuery.isEmpty) return _mountains;
    final query = _searchQuery.toLowerCase();
    return _mountains.where((m) {
      final matchesName = m.name.toLowerCase().contains(query);
      final matchesLocation = m.location.toLowerCase().contains(query);
      final matchesRoute = m.routes.any((r) => r.name.toLowerCase().contains(query));
      return matchesName || matchesLocation || matchesRoute;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchMountains() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrlApi}/mountains'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'];
        _mountains = list.map((m) => MountainModel.fromJson(m)).toList();
      } else {
        _errorMessage = 'Gagal memuat daftar gunung';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch user's upcoming bookings (untuk section "Trip Mendatang" di home).
  /// Kalau user belum login atau belum ada bookings, list akan kosong.
  Future<void> fetchUpcomingBookings() async {
    final token = authProvider.token;
    if (token == null) {
      _upcomingBookings = [];
      notifyListeners();
      return;
    }

    _isLoadingUpcoming = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrlApi}/users/me/upcoming_bookings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final list = data['data'] as List;
          _upcomingBookings = list
              .map((e) => UpcomingBookingModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      _upcomingBookings = [];
    } finally {
      _isLoadingUpcoming = false;
      notifyListeners();
    }
  }

  Future<TicketModel?> bookTicket({
    required int mountainId,
    required DateTime date,
    required int climbersCount,
    required double totalPrice,
    int? mountainRouteId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _lastPaymentUrl = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrlApi}/tickets'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mountain_id': mountainId,
          'mountain_route_id': mountainRouteId,
          'date': date.toIso8601String(),
          'climbers_count': climbersCount,
          'total_price': totalPrice,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _lastPaymentUrl = data['data']['payment_url'];
        return TicketModel.fromJson(data['data']);
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Gagal memesan tiket';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
