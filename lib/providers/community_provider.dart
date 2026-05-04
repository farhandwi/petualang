import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../models/community_event_model.dart';
import '../models/community_rule_model.dart';
import '../services/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityService service = CommunityService();

  // State
  List<CommunityModel> communities = [];
  List<CommunityModel> trendingCommunities = [];
  List<String> categories = const [
    'Semua',
    'Hiking & Trekking',
    'Camping & Outdoor',
    'Running',
    'Fotografi',
    'Climbing',
    'Lainnya',
  ];
  String selectedCategory = 'Semua';
  String searchQuery = '';
  int totalMembersGlobal = 0;

  CommunityModel? selectedCommunity;
  List<Map<String, dynamic>> selectedMembers = [];
  List<CommunityEventModel> selectedEvents = [];
  List<Map<String, dynamic>> selectedPhotos = [];
  List<CommunityRuleModel> selectedRules = [];
  int? myRatingStars;

  bool isLoadingCommunities = false;
  bool isLoadingTrending = false;
  String? errorMessage;

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  // Getter helpers
  List<CommunityModel> get myCommunities =>
      communities.where((c) => c.isMember).toList();

  List<CommunityModel> ownedCommunitiesFor(int? userId) =>
      communities.where((c) => c.isOwnedBy(userId)).toList();

  List<CommunityModel> get filteredAllCommunities {
    return communities.where((c) {
      if (selectedCategory != 'Semua' && c.category != selectedCategory) {
        return false;
      }
      if (searchQuery.isNotEmpty &&
          !c.name.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  void setCategory(String cat) {
    selectedCategory = cat;
    notifyListeners();
  }

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  // ─── Communities ─────────────────────────────────────────────

  Future<void> fetchCommunities({String? search, String? category}) async {
    isLoadingCommunities = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await service.listCommunities(
        token: _token,
        search: search,
        category: category,
      );
      communities = result.data;
      totalMembersGlobal = result.totalMembers;
    } catch (e) {
      errorMessage = 'Gagal memuat komunitas';
    }

    isLoadingCommunities = false;
    notifyListeners();
  }

  /// Top 10 komunitas paling aktif (24 jam).
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

  Future<void> fetchCategoriesFromServer() async {
    final result = await service.getCategories(token: _token);
    if (result.isNotEmpty) {
      categories = ['Semua', ...result];
      notifyListeners();
    }
  }

  Future<void> fetchCommunityDetail(int id) async {
    try {
      selectedCommunity = await service.getCommunityDetail(id, token: _token);
      // Sync ke list utama agar card di dashboard ikut update.
      if (selectedCommunity != null) {
        final idx = communities.indexWhere((c) => c.id == id);
        if (idx != -1) communities[idx] = selectedCommunity!;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<CommunityModel?> updateCommunity({
    required int id,
    String? name,
    String? description,
    String? location,
    String? category,
    String? privacy,
    String? coverImageUrl,
    String? iconImageUrl,
  }) async {
    if (_token == null) return null;
    final updated = await service.updateCommunity(
      token: _token!,
      id: id,
      name: name,
      description: description,
      location: location,
      category: category,
      privacy: privacy,
      coverImageUrl: coverImageUrl,
      iconImageUrl: iconImageUrl,
    );
    if (updated != null) {
      final idx = communities.indexWhere((c) => c.id == id);
      if (idx != -1) communities[idx] = updated;
      if (selectedCommunity?.id == id) selectedCommunity = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<CommunityModel?> createCommunity({
    required String name,
    String? description,
    String? location,
    String? category,
    String privacy = 'public',
    String? coverImageUrl,
    String? iconImageUrl,
  }) async {
    if (_token == null) return null;
    final created = await service.createCommunity(
      token: _token!,
      name: name,
      description: description,
      location: location,
      category: category,
      privacy: privacy,
      coverImageUrl: coverImageUrl,
      iconImageUrl: iconImageUrl,
    );
    if (created != null) {
      communities = [created, ...communities];
      notifyListeners();
    }
    return created;
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

  // ─── Events / Photos / Rules / Rating per community ─────────

  Future<void> fetchEvents(int communityId) async {
    try {
      selectedEvents = await service.getEvents(communityId, token: _token);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchPhotos(int communityId) async {
    try {
      selectedPhotos = await service.getPhotos(communityId, token: _token);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchRules(int communityId) async {
    try {
      selectedRules = await service.getRules(communityId, token: _token);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> saveRules(int communityId, List<String> rules) async {
    if (_token == null) return false;
    final ok = await service.setRules(
      communityId: communityId,
      token: _token!,
      rules: rules,
    );
    if (ok) await fetchRules(communityId);
    return ok;
  }

  Future<void> fetchMyRating(int communityId) async {
    if (_token == null) return;
    try {
      myRatingStars = await service.getMyRating(communityId, _token!);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> submitRating(int communityId, int stars, {String? review}) async {
    if (_token == null) return false;
    final result = await service.submitRating(
      communityId: communityId,
      token: _token!,
      stars: stars,
      review: review,
    );
    if (result != null) {
      myRatingStars = stars;
      if (selectedCommunity?.id == communityId) {
        selectedCommunity = selectedCommunity!.copyWith(
          rating: result.rating,
          reviewCount: result.reviewCount,
        );
      }
      final idx = communities.indexWhere((c) => c.id == communityId);
      if (idx != -1) {
        communities[idx] = communities[idx].copyWith(
          rating: result.rating,
          reviewCount: result.reviewCount,
        );
      }
      notifyListeners();
      return true;
    }
    return false;
  }
}
