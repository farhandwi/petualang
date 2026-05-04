import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const int serverPort = 8080;

  /// Google OAuth **Web** Client ID — wajib di-set untuk Google Sign-In:
  /// - Web: dipakai langsung sebagai client id.
  /// - Android/iOS: dipakai sebagai `serverClientId` agar `id_token` yang
  ///   dikirim ke server punya `aud` = Web Client ID (lebih mudah validasi
  ///   di server karena hanya satu audience yang stabil lintas platform).
  /// Format: `xxxxxxxx-xxxx.apps.googleusercontent.com`
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$serverPort';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:$serverPort'; // Default Android Emulator Host IP
    } else {
      return 'http://localhost:$serverPort';
    }
  }

  // API endpoints
  static String get baseUrlApi => '$baseUrl/api';
  static String get apiAuth => '$baseUrl/api/auth';
  static String get loginEndpoint => '$apiAuth/login';
  static String get registerEndpoint => '$apiAuth/register';
  static String get googleLoginEndpoint => '$apiAuth/google_login';
  static String get meEndpoint => '$apiAuth/me';
  static String get profileEndpoint => '$apiAuth/profile';
  static String get forgotPasswordEndpoint => '$apiAuth/forgot_password';
  static String get resetPasswordEndpoint => '$apiAuth/reset_password';
  static String get verifyIdentityEndpoint => '$apiAuth/verify_identity';

  // Rental endpoints
  static String get apiRentals => '$baseUrlApi/rentals';
  static String get rentalItemsEndpoint => '$apiRentals/items';
  static String get rentalVendorsEndpoint => '$apiRentals/vendors';

  // Community endpoints
  static String get apiCommunity => '$baseUrl/api/community';
  static String get apiFeed => '$apiCommunity/feed';
  static String communityDetail(int id) => '$apiCommunity/$id';
  static String communityJoin(int id) => '$apiCommunity/$id/join';
  static String communityMembers(int id) => '$apiCommunity/$id/members';
  static String communityPosts(int id) => '$apiCommunity/$id/posts';
  static String postDetail(int postId) => '$apiCommunity/posts/$postId';
  static String postLike(int postId) => '$apiCommunity/posts/$postId/like';
  static String postShare(int postId) => '$apiCommunity/posts/$postId/share';
  static String postComments(int postId) => '$apiCommunity/posts/$postId/comments';
  static String get apiReport => '$baseUrl/api/report';
  static String get apiCommunityTrending => '$apiCommunity/trending';
  static String get apiCommunityCategories => '$apiCommunity/categories';
  static String communityEvents(int id) => '$apiCommunity/$id/events';
  static String communityPhotos(int id) => '$apiCommunity/$id/photos';
  static String communityRules(int id) => '$apiCommunity/$id/rules';
  static String communityRating(int id) => '$apiCommunity/$id/rating';

  // Chat endpoints
  static String chatInfo(int communityId) => '$baseUrl/api/chat/$communityId';
  static String chatMessages(int communityId) => '$baseUrl/api/chat/$communityId/messages';
  static String chatRead(int communityId) => '$baseUrl/api/chat/$communityId/read';

  // DM endpoints
  static String get apiDm => '$baseUrlApi/dm';
  static String dmConversations() => apiDm;
  static String dmMessages(int conversationId) => '$apiDm/$conversationId/messages';
  static String dmBlock(int userId) => '$apiDm/$userId/block';
  static String dmSearchUsers(String query) => '$baseUrlApi/users/search?q=$query';

  // Upload endpoint
  static String get uploadImageEndpoint => '$baseUrl/api/upload/image';

  // Admin endpoints
  static String get apiAdmin => '$baseUrlApi/admin';
  static String get adminDashboardEndpoint => '$apiAdmin/dashboard';
  static String get adminVerificationsEndpoint => '$apiAdmin/verifications';
  static String adminVerificationDetail(int id) => '$apiAdmin/verifications/$id';
  static String get adminUsersEndpoint => '$apiAdmin/users';
  static String adminUserDetail(int id) => '$apiAdmin/users/$id';
  static String get adminMountainsEndpoint => '$apiAdmin/mountains';
  static String adminMountainDetail(int id) => '$apiAdmin/mountains/$id';
  static String adminMountainRoutes(int mountainId) =>
      '$apiAdmin/mountains/$mountainId/routes';
  static String adminMountainRouteDetail(int mountainId, int routeId) =>
      '$apiAdmin/mountains/$mountainId/routes/$routeId';
  static String get adminReportsEndpoint => '$apiAdmin/reports';
  static String adminReportDetail(int id) => '$apiAdmin/reports/$id';
  static String adminCommunityPostDelete(int id) =>
      '$apiAdmin/community/posts/$id';

  // Mitra endpoints
  static String get apiMitra => '$baseUrlApi/mitra';
  static String get mitraVendorEndpoint => '$apiMitra/me/vendor';
  static String get mitraItemsEndpoint => '$apiMitra/me/items';
  static String mitraItemDetail(int id) => '$apiMitra/me/items/$id';
  static String get mitraOrdersEndpoint => '$apiMitra/me/orders';
  static String mitraOrderDetail(int id) => '$apiMitra/me/orders/$id';
  static String get mitraStatsEndpoint => '$apiMitra/me/stats';

  // WebSocket base — ws:// not http://
  static String get wsBaseUrl {
    if (kIsWeb) return 'ws://localhost:$serverPort';
    if (Platform.isAndroid) return 'ws://10.0.2.2:$serverPort';
    return 'ws://localhost:$serverPort';
  }
  static String chatWsUrl(int communityId, String token) =>
      '$wsBaseUrl/ws/chat/$communityId?token=$token';
  static String dmWsUrl(int conversationId, String token) =>
      '$wsBaseUrl/ws/dm/$conversationId?token=$token';

  /// Resolves an image URL from the background.
  /// If [url] is relative (starts with /), it prefixes it with [baseUrl].
  static String resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    // Prefix relative URL with baseUrl
    final cleanUrl = url.startsWith('/') ? url : '/$url';
    return '$baseUrl$cleanUrl';
  }
}
