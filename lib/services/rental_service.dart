import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/rental_model.dart';
import '../models/vendor_model.dart';

class RentalService {
  final Duration _timeout = const Duration(seconds: 15);

  Future<List<VendorModel>> getVendors({double? lat, double? lng, String? query}) async {
    try {
      final queryParams = <String, String>{};
      if (lat != null && lng != null) {
        queryParams['lat'] = lat.toString();
        queryParams['lng'] = lng.toString();
      }
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      final uri = Uri.parse(AppConfig.rentalVendorsEndpoint).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List rows = data['data'] as List;
          return rows.map((json) => VendorModel.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching vendors: $e');
      return [];
    }
  }

  Future<List<RentalItemModel>> getRentalItems({String? category, int? mountainId, int? vendorId}) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category != 'Semua') {
        queryParams['category'] = category;
      }
      if (mountainId != null) {
        queryParams['mountain_id'] = mountainId.toString();
      }
      if (vendorId != null) {
        queryParams['vendor_id'] = vendorId.toString();
      }

      final uri = Uri.parse(AppConfig.rentalItemsEndpoint).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List rows = data['data'] as List;
          return rows.map((json) => RentalItemModel.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching rental items: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> checkoutRental({
    required String token,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
    double deliveryFee = 0,
    int? mountainId,
    int? entryRouteId,
    int? exitRouteId,
    required List<RentalCartItem> cartItems,
  }) async {
    try {
      final formattedStart = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      final formattedEnd = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

      final items = cartItems.map((cart) => {
        'item_id': cart.item.id,
        'quantity': cart.quantity,
        'price_per_day': cart.item.pricePerDay,
        'subtotal': cart.item.pricePerDay * cart.quantity,
      }).toList();

      final response = await http.post(
        Uri.parse(AppConfig.apiRentals),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'start_date': formattedStart,
          'end_date': formattedEnd,
          'total_price': totalPrice,
          'delivery_fee': deliveryFee,
          'mountain_id': mountainId,
          'entry_route_id': entryRouteId,
          'exit_route_id': exitRouteId,
          'items': items,
        }),
      ).timeout(_timeout);

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'],
          'payment_url': data['data']['payment_url'],
        };
      }
      
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal membuat pesanan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan sistem: $e',
      };
    }
  }
}
