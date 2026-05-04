import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/order_model.dart';
import 'auth_provider.dart';

class OrderProvider with ChangeNotifier {
  final AuthProvider authProvider;
  
  OrderProvider({required this.authProvider});

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOrders() async {
    final token = authProvider.token;
    if (token == null) {
      _orders = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrlApi}/users/me/orders'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final list = data['data'] as List;
          _orders = list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          _errorMessage = data['message'] ?? 'Gagal memuat pesanan';
        }
      } else {
        _errorMessage = 'Gagal memuat pesanan. Status: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
