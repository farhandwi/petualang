import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityService service = CommunityService();

  // State
  List<CommunityModel> communities = [];
  List<CommunityModel> trendingCommunities = [];
  CommunityModel? selectedCommunity;
  List<Map<String, dynamic>> selectedMembers = [];

  bool isLoadingCommunities = false;
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
    } catch (_) {
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
}
