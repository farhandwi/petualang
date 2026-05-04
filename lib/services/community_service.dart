import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/community_model.dart';
import '../models/community_post_model.dart';
import '../models/community_event_model.dart';
import '../models/community_rule_model.dart';

class CommunityService {
  static const _timeout = Duration(seconds: 60);

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── Communities ─────────────────────────────────────────────

  /// Returns ([list], totalMembers across communities for header).
  Future<({List<CommunityModel> data, int totalMembers})> listCommunities({
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
    if (data['success'] != true) return (data: <CommunityModel>[], totalMembers: 0);
    final list = (data['data'] as List<dynamic>)
        .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = data['meta'] as Map<String, dynamic>?;
    final totalMembers = meta?['total_members'] as int? ?? 0;
    return (data: list, totalMembers: totalMembers);
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

  Future<CommunityModel?> updateCommunity({
    required String token,
    required int id,
    String? name,
    String? description,
    String? location,
    String? category,
    String? privacy,
    String? coverImageUrl,
    String? iconImageUrl,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (category != null) 'category': category,
      if (privacy != null) 'privacy': privacy,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      if (iconImageUrl != null) 'icon_image_url': iconImageUrl,
    };
    final response = await http
        .put(
          Uri.parse(AppConfig.communityDetail(id)),
          headers: _headers(token),
          body: json.encode(body),
        )
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return null;
    return CommunityModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<CommunityModel?> createCommunity({
    required String token,
    required String name,
    String? description,
    String? location,
    String? category,
    String privacy = 'public',
    String? coverImageUrl,
    String? iconImageUrl,
  }) async {
    final response = await http
        .post(
          Uri.parse(AppConfig.apiCommunity),
          headers: _headers(token),
          body: json.encode({
            'name': name,
            if (description != null) 'description': description,
            if (location != null) 'location': location,
            if (category != null) 'category': category,
            'privacy': privacy,
            if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
            if (iconImageUrl != null) 'icon_image_url': iconImageUrl,
          }),
        )
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return null;
    return CommunityModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ─── Membership ─────────────────────────────────────────────

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

  // ─── Categories ─────────────────────────────────────────────

  Future<List<String>> getCategories({String? token}) async {
    try {
      final response = await http
          .get(Uri.parse(AppConfig.apiCommunityCategories), headers: _headers(token))
          .timeout(_timeout);
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return const [];
      return (data['data'] as List<dynamic>).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  // ─── Posts ──────────────────────────────────────────────────

  Future<List<CommunityPostModel>> getPosts(int communityId,
      {String? token, int limit = 20, int offset = 0}) async {
    final url = '${AppConfig.communityPosts(communityId)}?limit=$limit&offset=$offset';
    final response = await http
        .get(Uri.parse(url), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['data'] as List<dynamic>)
        .map((e) => CommunityPostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityPostModel?> createPost({
    required String token,
    required int communityId,
    required String content,
    String? imageUrl,
  }) async {
    final response = await http
        .post(
          Uri.parse(AppConfig.communityPosts(communityId)),
          headers: _headers(token),
          body: json.encode({
            'content': content,
            if (imageUrl != null) 'image_url': imageUrl,
          }),
        )
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return null;
    return CommunityPostModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<({bool liked, int likeCount})?> toggleLike(int postId, String token) async {
    final response = await http
        .post(Uri.parse(AppConfig.postLike(postId)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return null;
    final d = data['data'] as Map<String, dynamic>;
    return (liked: d['liked'] as bool? ?? false, likeCount: d['like_count'] as int? ?? 0);
  }

  // ─── Events / Photos / Rules / Rating ───────────────────────

  Future<List<CommunityEventModel>> getEvents(int communityId, {String? token}) async {
    final response = await http
        .get(Uri.parse(AppConfig.communityEvents(communityId)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['data'] as List<dynamic>)
        .map((e) => CommunityEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getPhotos(int communityId, {String? token}) async {
    final response = await http
        .get(Uri.parse(AppConfig.communityPhotos(communityId)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['data'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<List<CommunityRuleModel>> getRules(int communityId, {String? token}) async {
    final response = await http
        .get(Uri.parse(AppConfig.communityRules(communityId)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['data'] as List<dynamic>)
        .map((e) => CommunityRuleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> setRules({
    required int communityId,
    required String token,
    required List<String> rules,
  }) async {
    final response = await http
        .put(
          Uri.parse(AppConfig.communityRules(communityId)),
          headers: _headers(token),
          body: json.encode({'rules': rules}),
        )
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['success'] as bool? ?? false;
  }

  Future<int?> getMyRating(int communityId, String token) async {
    final response = await http
        .get(Uri.parse(AppConfig.communityRating(communityId)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return null;
    final d = data['data'] as Map<String, dynamic>?;
    return d?['stars'] as int?;
  }

  Future<({double rating, int reviewCount})?> submitRating({
    required int communityId,
    required String token,
    required int stars,
    String? review,
  }) async {
    final response = await http
        .post(
          Uri.parse(AppConfig.communityRating(communityId)),
          headers: _headers(token),
          body: json.encode({
            'stars': stars,
            if (review != null) 'review': review,
          }),
        )
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return null;
    final r = data['rating'];
    final c = data['review_count'];
    return (
      rating: r is num ? r.toDouble() : 0.0,
      reviewCount: c is int ? c : 0,
    );
  }
}
