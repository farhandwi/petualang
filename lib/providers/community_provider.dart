import 'dart:io';
import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../models/community_post_model.dart';
import '../models/community_comment_model.dart';
import '../services/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityService service = CommunityService();

  // State
  List<CommunityModel> communities = [];
  List<CommunityPostModel> globalFeed = [];
  List<CommunityModel> trendingCommunities = [];
  Map<int, List<CommunityPostModel>> postsByGroup = {};
  Map<int, List<CommunityCommentModel>> commentsByPost = {};
  CommunityModel? selectedCommunity;
  List<Map<String, dynamic>> selectedMembers = [];

  bool isLoadingCommunities = false;
  bool isLoadingFeed = false;
  bool isLoadingPosts = false;
  bool isCreatingPost = false;
  bool isLoadingTrending = false;
  String? errorMessage;

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  // ─── Communities ─────────────────────────────────────────────

  Future<void> fetchCommunities({String? search, String? category}) async {
    isLoadingCommunities = true;
    errorMessage = null;
    notifyListeners();

    try {
      communities = await service.listCommunities(
        token: _token,
        search: search,
        category: category,
      );
    } catch (e) {
      errorMessage = 'Gagal memuat komunitas';
    }

    isLoadingCommunities = false;
    notifyListeners();
  }

  /// Mengambil top 10 komunitas dengan posting terbanyak dalam 24 jam terakhir.
  Future<void> fetchTrendingCommunities() async {
    isLoadingTrending = true;
    notifyListeners();

    try {
      final result = await service.getTrendingCommunities(token: _token);
      trendingCommunities = result;
      print('[CommunityProvider] fetchTrendingCommunities: ${result.length} communities loaded');
    } catch (e, st) {
      print('[CommunityProvider] fetchTrendingCommunities ERROR: $e\n$st');
      // Fallback: gunakan data communities yang sudah ada (bila sudah di-fetch)
      trendingCommunities = communities.take(10).toList();
    }

    isLoadingTrending = false;
    notifyListeners();
  }


  Future<void> fetchCommunityDetail(int id) async {
    try {
      selectedCommunity = await service.getCommunityDetail(id, token: _token);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> joinCommunity(int id) async {
    if (_token == null) return false;
    final success = await service.joinCommunity(id, _token!);
    if (success) {
      // Optimistic update
      final idx = communities.indexWhere((c) => c.id == id);
      if (idx != -1) {
        communities[idx] = communities[idx].copyWith(
          isMember: true,
          memberCount: communities[idx].memberCount + 1,
        );
      }
      if (selectedCommunity?.id == id) {
        selectedCommunity = selectedCommunity!.copyWith(isMember: true);
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> leaveCommunity(int id) async {
    if (_token == null) return false;
    final success = await service.leaveCommunity(id, _token!);
    if (success) {
      final idx = communities.indexWhere((c) => c.id == id);
      if (idx != -1) {
        communities[idx] = communities[idx].copyWith(
          isMember: false,
          memberCount: (communities[idx].memberCount - 1).clamp(0, 999999),
        );
      }
      if (selectedCommunity?.id == id) {
        selectedCommunity = selectedCommunity!.copyWith(isMember: false);
      }
      notifyListeners();
    }
    return success;
  }

  Future<void> fetchMembers(int communityId) async {
    try {
      selectedMembers = await service.getMembers(communityId, token: _token);
      notifyListeners();
    } catch (_) {}
  }

  // ─── Feed ────────────────────────────────────────────────────

  Future<void> fetchFeed({bool refresh = false}) async {
    if (_token == null) return;
    isLoadingFeed = true;
    if (refresh) globalFeed = [];
    notifyListeners();

    try {
      final posts = await service.getFeed(token: _token!, offset: globalFeed.length);
      if (refresh) {
        globalFeed = posts;
      } else {
        globalFeed = [...globalFeed, ...posts];
      }
    } catch (_) {
      errorMessage = 'Gagal memuat feed';
    }

    isLoadingFeed = false;
    notifyListeners();
  }

  // ─── Posts ──────────────────────────────────────────────────

  Future<void> fetchPosts(int communityId, {bool refresh = false}) async {
    isLoadingPosts = true;
    if (refresh) postsByGroup[communityId] = [];
    notifyListeners();

    try {
      final current = postsByGroup[communityId] ?? [];
      final posts = await service.getPosts(
        communityId,
        token: _token,
        offset: refresh ? 0 : current.length,
      );
      if (refresh) {
        postsByGroup[communityId] = posts;
      } else {
        postsByGroup[communityId] = [...current, ...posts];
      }
    } catch (_) {}

    isLoadingPosts = false;
    notifyListeners();
  }

  Future<bool> createPost({
    required int communityId,
    required String content,
    File? imageFile,
  }) async {
    if (_token == null) return false;
    isCreatingPost = true;
    notifyListeners();

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await service.uploadImage(imageFile, _token!);
      if (imageUrl == null) {
        errorMessage = 'Gagal mengunggah gambar. Silakan periksa koneksi atau ukuran file.';
        isCreatingPost = false;
        notifyListeners();
        return false;
      }
    }

    print('DEBUG: CommunityProvider.createPost uploading image, result: $imageUrl');
    final success = await service.createPost(
      communityId: communityId,
      content: content,
      token: _token!,
      imageUrl: imageUrl,
    );

    if (success) {
      // Refresh posts for this specific community
      await fetchPosts(communityId, refresh: true);
      // ALSO Refresh the global feed
      await fetchFeed(refresh: true);
    }

    isCreatingPost = false;
    notifyListeners();
    return success;
  }

  Future<bool> deletePost(int postId, int communityId) async {
    if (_token == null) return false;
    final success = await service.deletePost(postId, _token!);
    if (success) {
      postsByGroup[communityId]?.removeWhere((p) => p.id == postId);
      globalFeed.removeWhere((p) => p.id == postId);
      notifyListeners();
    }
    return success;
  }

  Future<void> toggleLike(int postId, int communityId) async {
    if (_token == null) return;
    // Optimistic update
    _updateLikeOptimistic(postId, true, communityId);
    final result = await service.toggleLike(postId, _token!);
    if (result != null) {
      final liked = result['liked'] as bool;
      final count = result['like_count'] as int;
      _setLikeFromServer(postId, liked, count, communityId);
    }
  }

  void _updateLikeOptimistic(int postId, bool liked, int communityId) {
    final feedIdx = globalFeed.indexWhere((p) => p.id == postId);
    if (feedIdx != -1) {
      final p = globalFeed[feedIdx];
      globalFeed[feedIdx] = p.copyWith(
        isLiked: !p.isLiked,
        likeCount: p.isLiked ? p.likeCount - 1 : p.likeCount + 1,
      );
    }
    final posts = postsByGroup[communityId];
    if (posts != null) {
      final idx = posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final p = posts[idx];
        postsByGroup[communityId]![idx] = p.copyWith(
          isLiked: !p.isLiked,
          likeCount: p.isLiked ? p.likeCount - 1 : p.likeCount + 1,
        );
      }
    }
    notifyListeners();
  }

  void _setLikeFromServer(int postId, bool liked, int count, int communityId) {
    final feedIdx = globalFeed.indexWhere((p) => p.id == postId);
    if (feedIdx != -1) {
      globalFeed[feedIdx] = globalFeed[feedIdx].copyWith(isLiked: liked, likeCount: count);
    }
    final posts = postsByGroup[communityId];
    if (posts != null) {
      final idx = posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        postsByGroup[communityId]![idx] =
            postsByGroup[communityId]![idx].copyWith(isLiked: liked, likeCount: count);
      }
    }
    notifyListeners();
  }

  // ─── Comments ────────────────────────────────────────────────

  Future<void> fetchComments(int postId) async {
    try {
      commentsByPost[postId] = await service.getComments(postId, token: _token);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createComment({
    required int postId,
    required String content,
    int? parentId,
    File? imageFile,
  }) async {
    if (_token == null) return false;

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await service.uploadImage(imageFile, _token!);
    }

    final success = await service.createComment(
      postId: postId,
      content: content,
      token: _token!,
      parentId: parentId,
      imageUrl: imageUrl,
    );

    if (success) {
      // Optimistic update: increment comment count locally
      final feedIdx = globalFeed.indexWhere((p) => p.id == postId);
      if (feedIdx != -1) {
        globalFeed[feedIdx] = globalFeed[feedIdx].copyWith(
          commentCount: globalFeed[feedIdx].commentCount + 1,
        );
      }
      
      // Update by group as well
      for (final groupId in postsByGroup.keys) {
        final groupPosts = postsByGroup[groupId];
        if (groupPosts != null) {
          final idx = groupPosts.indexWhere((p) => p.id == postId);
          if (idx != -1) {
            groupPosts[idx] = groupPosts[idx].copyWith(
              commentCount: groupPosts[idx].commentCount + 1,
            );
          }
        }
      }

      await fetchComments(postId);
      notifyListeners();
    }
    return success;
  }

  // ─── Report ──────────────────────────────────────────────────

  Future<bool> submitReport({
    required String targetType,
    required int targetId,
    required String reason,
  }) async {
    if (_token == null) return false;
    return service.submitReport(
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      token: _token!,
    );
  }
}
