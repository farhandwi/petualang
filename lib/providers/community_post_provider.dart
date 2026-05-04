import 'package:flutter/material.dart';
import '../models/community_post_model.dart';
import '../services/community_service.dart';

class CommunityPostProvider extends ChangeNotifier {
  final CommunityService service = CommunityService();

  /// Posts per communityId
  final Map<int, List<CommunityPostModel>> postsByCommunity = {};
  final Map<int, bool> _loading = {};

  String? _token;
  void setToken(String? token) {
    _token = token;
  }

  bool isLoading(int communityId) => _loading[communityId] ?? false;
  List<CommunityPostModel> postsFor(int communityId) =>
      postsByCommunity[communityId] ?? const <CommunityPostModel>[];

  Future<void> loadPosts(int communityId, {bool refresh = false}) async {
    if (_loading[communityId] == true) return;
    if (!refresh && (postsByCommunity[communityId]?.isNotEmpty ?? false)) {
      return;
    }
    _loading[communityId] = true;
    notifyListeners();
    try {
      final posts = await service.getPosts(communityId, token: _token);
      postsByCommunity[communityId] = posts;
    } catch (_) {
      postsByCommunity[communityId] = [];
    }
    _loading[communityId] = false;
    notifyListeners();
  }

  Future<bool> createPost({
    required int communityId,
    required String content,
    String? imageUrl,
  }) async {
    if (_token == null) return false;
    final created = await service.createPost(
      token: _token!,
      communityId: communityId,
      content: content,
      imageUrl: imageUrl,
    );
    if (created != null) {
      final list = postsByCommunity[communityId] ?? [];
      // Pinned posts tetap di atas; insert post baru tepat setelah pinned.
      final firstNonPinned = list.indexWhere((p) => !p.isPinned);
      final insertAt = firstNonPinned < 0 ? list.length : firstNonPinned;
      postsByCommunity[communityId] = [
        ...list.take(insertAt),
        created,
        ...list.skip(insertAt),
      ];
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> toggleLike(int communityId, int postId) async {
    if (_token == null) return;
    // Optimistic flip
    _flipLike(communityId, postId, optimistic: true);
    final res = await service.toggleLike(postId, _token!);
    if (res == null) {
      _flipLike(communityId, postId, optimistic: true); // rollback
      return;
    }
    final list = postsByCommunity[communityId];
    if (list == null) return;
    final idx = list.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    list[idx] = list[idx].copyWith(
      isLiked: res.liked,
      likeCount: res.likeCount,
    );
    notifyListeners();
  }

  void _flipLike(int communityId, int postId, {bool optimistic = false}) {
    final list = postsByCommunity[communityId];
    if (list == null) return;
    final idx = list.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final p = list[idx];
    list[idx] = p.copyWith(
      isLiked: !p.isLiked,
      likeCount: (p.likeCount + (p.isLiked ? -1 : 1)).clamp(0, 999999),
    );
    notifyListeners();
  }
}
