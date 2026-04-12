import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lokasi yang dipilih user dari pencarian
class LocationResult {
  final String displayName;  // alamat lengkap
  final String shortName;    // kota pendek untuk UI
  final double lat;
  final double lng;

  LocationResult({
    required this.displayName,
    required this.shortName,
    required this.lat,
    required this.lng,
  });

  factory LocationResult.fromNominatim(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};

    // Build a short human-readable label
    final parts = <String>[
      address['suburb'] ?? '',
      address['city_district'] ?? '',
      address['city'] ?? address['town'] ?? address['county'] ?? '',
      address['state'] ?? '',
    ].where((s) => s.isNotEmpty).take(2).toList();

    final short = parts.isNotEmpty ? parts.join(', ') : json['display_name'] ?? 'Lokasi';

    return LocationResult(
      displayName: json['display_name'] ?? '',
      shortName: short,
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lon'].toString()),
    );
  }
}

/// Service untuk geocoding menggunakan Nominatim OpenStreetMap (gratis, tidak perlu API key)
class LocationService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org';
  static const _headers = {
    'User-Agent': 'PetualangApp/1.0 (contact@petualang.app)',
    'Accept-Language': 'id-ID,id;q=0.9,en;q=0.8',
  };

  /// Cari lokasi berdasarkan teks (seperti Google Maps search)
  static Future<List<LocationResult>> searchPlace(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'q': query,
          'format': 'jsonv2',
          'addressdetails': '1',
          'limit': '5',
          'countrycodes': 'id',  // Batasi di Indonesia saja
        },
      );

      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data
            .map((item) => LocationResult.fromNominatim(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('LocationService.searchPlace error: $e');
      return [];
    }
  }

  /// Reverse geocoding — ubah koordinat menjadi nama lokasi
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse('$_baseUrl/reverse').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lng.toString(),
          'format': 'jsonv2',
          'addressdetails': '1',
          'zoom': '12',
        },
      );

      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};

        final parts = <String>[
          address['suburb'] ?? '',
          address['city_district'] ?? '',
          address['city'] ?? address['town'] ?? address['county'] ?? '',
          address['state'] ?? '',
        ].where((s) => s.isNotEmpty).take(2).toList();

        return parts.isNotEmpty ? parts.join(', ') : null;
      }
      return null;
    } catch (e) {
      print('LocationService.reverseGeocode error: $e');
      return null;
    }
  }
}
