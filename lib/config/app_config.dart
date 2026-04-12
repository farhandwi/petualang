import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const int serverPort = 8080;
  
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
  static String get meEndpoint => '$apiAuth/me';
  static String get profileEndpoint => '$apiAuth/profile';
  static String get forgotPasswordEndpoint => '$apiAuth/forgot_password';
  static String get resetPasswordEndpoint => '$apiAuth/reset_password';

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

  // Chat endpoints
  static String chatInfo(int communityId) => '$baseUrl/api/chat/$communityId';
  static String chatMessages(int communityId) => '$baseUrl/api/chat/$communityId/messages';
  static String chatRead(int communityId) => '$baseUrl/api/chat/$communityId/read';

  // Upload endpoint
  static String get uploadImageEndpoint => '$baseUrl/api/upload/image';

  // WebSocket base — ws:// not http://
  static String get wsBaseUrl {
    if (kIsWeb) return 'ws://localhost:$serverPort';
    if (Platform.isAndroid) return 'ws://10.0.2.2:$serverPort';
    return 'ws://localhost:$serverPort';
  }
  static String chatWsUrl(int communityId, String token) =>
      '$wsBaseUrl/ws/chat/$communityId?token=$token';

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
