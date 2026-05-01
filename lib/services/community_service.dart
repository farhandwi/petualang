import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/community_model.dart';

class CommunityService {
  static const _timeout = Duration(seconds: 60);

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── Communities ─────────────────────────────────────────────

  Future<List<CommunityModel>> listCommunities({
    String? token,
    String? search,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    var url = '${AppConfig.apiCommunity}?limit=$limit&offset=$offset';
    if (search != null && search.isNotEmpty) url += '&q=${Uri.encodeComponent(search)}';
    if (category != null && category.isNotEmpty && category != 'Semua') {
      url += '&category=${Uri.encodeComponent(category)}';
    }

    final response = await http
        .get(Uri.parse(url), headers: _headers(token))
        .timeout(_timeout);

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    final list = data['data'] as List<dynamic>;
    return list.map((e) => CommunityModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CommunityModel>> getTrendingCommunities({String? token}) async {
    try {
      final response = await http
          .get(Uri.parse(AppConfig.apiCommunityTrending), headers: _headers(token))
          .timeout(_timeout);
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<CommunityModel?> getCommunityDetail(int id, {String? token}) async {
    final response = await http
        .get(Uri.parse(AppConfig.communityDetail(id)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return null;
    return CommunityModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<bool> joinCommunity(int id, String token) async {
    final response = await http
        .post(Uri.parse(AppConfig.communityJoin(id)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['success'] as bool? ?? false;
  }

  Future<bool> leaveCommunity(int id, String token) async {
    final response = await http
        .delete(Uri.parse(AppConfig.communityJoin(id)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['success'] as bool? ?? false;
  }

  Future<List<Map<String, dynamic>>> getMembers(int id, {String? token}) async {
    final response = await http
        .get(Uri.parse(AppConfig.communityMembers(id)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['data'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}
