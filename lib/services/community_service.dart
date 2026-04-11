import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/community_model.dart';
import '../models/community_post_model.dart';
import '../models/community_comment_model.dart';

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

  /// Mengambil top komunitas berdasarkan postingan terbanyak dalam 24 jam terakhir.
  Future<List<CommunityModel>> getTrendingCommunities({String? token}) async {
    try {
      final url = AppConfig.apiCommunityTrending;
      print('[CommunityService] getTrendingCommunities → GET $url');
      final response = await http
          .get(Uri.parse(url), headers: _headers(token))
          .timeout(_timeout);
      print('[CommunityService] trending response status: ${response.statusCode}');
      print('[CommunityService] trending response body: ${response.body}');
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      print('[CommunityService] getTrendingCommunities ERROR: $e\n$st');
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

  // ─── Posts ──────────────────────────────────────────────────

  Future<List<CommunityPostModel>> getFeed({required String token, int offset = 0}) async {
    final url = '${AppConfig.apiFeed}?limit=30&offset=$offset';
    final response = await http.get(Uri.parse(url), headers: _headers(token)).timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['data'] as List<dynamic>)
        .map((e) => CommunityPostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CommunityPostModel>> getPosts(
    int communityId, {
    String? token,
    int offset = 0,
  }) async {
    final url = '${AppConfig.communityPosts(communityId)}?limit=20&offset=$offset';
    final response = await http.get(Uri.parse(url), headers: _headers(token)).timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['data'] as List<dynamic>)
        .map((e) => CommunityPostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> createPost({
    required int communityId,
    required String content,
    required String token,
    String? imageUrl,
  }) async {
    final response = await http
        .post(
          Uri.parse(AppConfig.communityPosts(communityId)),
          headers: _headers(token),
          body: json.encode({'content': content, 'image_url': imageUrl}),
        )
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['success'] as bool? ?? false;
  }

  Future<bool> deletePost(int postId, String token) async {
    final response = await http
        .delete(Uri.parse(AppConfig.postDetail(postId)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['success'] as bool? ?? false;
  }

  Future<Map<String, dynamic>?> toggleLike(int postId, String token) async {
    final response = await http
        .post(Uri.parse(AppConfig.postLike(postId)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return null;
    return data['data'] as Map<String, dynamic>;
  }

  // ─── Comments ────────────────────────────────────────────────

  Future<List<CommunityCommentModel>> getComments(int postId, {String? token}) async {
    final response = await http
        .get(Uri.parse(AppConfig.postComments(postId)), headers: _headers(token))
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['data'] as List<dynamic>)
        .map((e) => CommunityCommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> createComment({
    required int postId,
    required String content,
    required String token,
    int? parentId,
    String? imageUrl,
  }) async {
    final response = await http
        .post(
          Uri.parse(AppConfig.postComments(postId)),
          headers: _headers(token),
          body: json.encode({
            'content': content,
            if (parentId != null) 'parent_id': parentId,
            if (imageUrl != null) 'image_url': imageUrl,
          }),
        )
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['success'] as bool? ?? false;
  }

  // ─── Upload ──────────────────────────────────────────────────

  Future<String?> uploadImage(File imageFile, String token) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.uploadImageEndpoint),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final streamed = await request.send().timeout(_timeout);
      final body = await streamed.stream.bytesToString();
      print('DEBUG: uploadImage response: $body');
      final data = json.decode(body) as Map<String, dynamic>;
      if (data['success'] != true) {
        print('DEBUG: uploadImage failed with message: ${data['message']}');
        return null;
      }
      return data['url'] as String?;
    } catch (e) {
      print('DEBUG: Exception during uploadImage: $e');
      return null;
    }
  }

  // ─── Report ──────────────────────────────────────────────────

  Future<bool> submitReport({
    required String targetType,
    required int targetId,
    required String reason,
    required String token,
  }) async {
    final response = await http
        .post(
          Uri.parse(AppConfig.apiReport),
          headers: _headers(token),
          body: json.encode({
            'target_type': targetType,
            'target_id': targetId,
            'reason': reason,
          }),
        )
        .timeout(_timeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['success'] as bool? ?? false;
  }
}
