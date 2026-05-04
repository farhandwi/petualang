import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class MitraService {
  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ========== Vendor (toko) ==========
  Future<Map<String, dynamic>?> getVendor(String token) async {
    final res = await http
        .get(Uri.parse(AppConfig.mitraVendorEndpoint), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<bool> updateVendor(String token, Map<String, dynamic> body) async {
    final res = await http
        .patch(
          Uri.parse(AppConfig.mitraVendorEndpoint),
          headers: _headers(token),
          body: json.encode(body),
        )
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }

  // ========== Items ==========
  Future<List<Map<String, dynamic>>> getItems(String token) async {
    final res = await http
        .get(Uri.parse(AppConfig.mitraItemsEndpoint), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
    return [];
  }

  Future<bool> createItem(String token, Map<String, dynamic> body) async {
    final res = await http
        .post(
          Uri.parse(AppConfig.mitraItemsEndpoint),
          headers: _headers(token),
          body: json.encode(body),
        )
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }

  Future<bool> updateItem(String token, int id, Map<String, dynamic> body) async {
    final res = await http
        .patch(
          Uri.parse(AppConfig.mitraItemDetail(id)),
          headers: _headers(token),
          body: json.encode(body),
        )
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }

  Future<bool> deleteItem(String token, int id) async {
    final res = await http
        .delete(Uri.parse(AppConfig.mitraItemDetail(id)), headers: _headers(token))
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }

  // ========== Orders ==========
  Future<List<Map<String, dynamic>>> getOrders(
    String token, {
    String status = 'all',
  }) async {
    final uri = Uri.parse(AppConfig.mitraOrdersEndpoint)
        .replace(queryParameters: {'status': status});
    final res = await http.get(uri, headers: _headers(token)).timeout(_timeout);
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getOrderDetail(String token, int id) async {
    final res = await http
        .get(Uri.parse(AppConfig.mitraOrderDetail(id)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<bool> updateOrderStatus(String token, int id, String status) async {
    final res = await http
        .patch(
          Uri.parse(AppConfig.mitraOrderDetail(id)),
          headers: _headers(token),
          body: json.encode({'status': status}),
        )
        .timeout(_timeout);
    return (json.decode(res.body) as Map<String, dynamic>)['success'] == true;
  }

  // ========== Stats ==========
  Future<Map<String, dynamic>?> getStats(String token) async {
    final res = await http
        .get(Uri.parse(AppConfig.mitraStatsEndpoint), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>?;
    }
    return null;
  }
}
