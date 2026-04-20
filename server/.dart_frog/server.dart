// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../main.dart' as entrypoint;
import '../routes/ws/dm/[conversationId].dart' as ws_dm_$conversation_id;
import '../routes/ws/chat/[communityId].dart' as ws_chat_$community_id;
import '../routes/api/report.dart' as api_report;
import '../routes/api/users/search.dart' as api_users_search;
import '../routes/api/upload/image.dart' as api_upload_image;
import '../routes/api/tickets/index.dart' as api_tickets_index;
import '../routes/api/rentals/vendors.dart' as api_rentals_vendors;
import '../routes/api/rentals/items.dart' as api_rentals_items;
import '../routes/api/rentals/index.dart' as api_rentals_index;
import '../routes/api/open_trips/index.dart' as api_open_trips_index;
import '../routes/api/open_trips/book.dart' as api_open_trips_book;
import '../routes/api/mountains/index.dart' as api_mountains_index;
import '../routes/api/gamification/me.dart' as api_gamification_me;
import '../routes/api/explore/index.dart' as api_explore_index;
import '../routes/api/dm/index.dart' as api_dm_index;
import '../routes/api/dm/[id]/messages.dart' as api_dm_$id_messages;
import '../routes/api/dm/[id]/block.dart' as api_dm_$id_block;
import '../routes/api/community/trending.dart' as api_community_trending;
import '../routes/api/community/index.dart' as api_community_index;
import '../routes/api/community/feed.dart' as api_community_feed;
import '../routes/api/community/posts/[postId]/share.dart' as api_community_posts_$post_id_share;
import '../routes/api/community/posts/[postId]/like.dart' as api_community_posts_$post_id_like;
import '../routes/api/community/posts/[postId]/index.dart' as api_community_posts_$post_id_index;
import '../routes/api/community/posts/[postId]/comments.dart' as api_community_posts_$post_id_comments;
import '../routes/api/community/[id]/members.dart' as api_community_$id_members;
import '../routes/api/community/[id]/join.dart' as api_community_$id_join;
import '../routes/api/community/[id]/index.dart' as api_community_$id_index;
import '../routes/api/community/[id]/posts/index.dart' as api_community_$id_posts_index;
import '../routes/api/chat/[communityId]/read.dart' as api_chat_$community_id_read;
import '../routes/api/chat/[communityId]/messages.dart' as api_chat_$community_id_messages;
import '../routes/api/chat/[communityId]/index.dart' as api_chat_$community_id_index;
import '../routes/api/auth/reset_password.dart' as api_auth_reset_password;
import '../routes/api/auth/register.dart' as api_auth_register;
import '../routes/api/auth/profile.dart' as api_auth_profile;
import '../routes/api/auth/me.dart' as api_auth_me;
import '../routes/api/auth/login.dart' as api_auth_login;
import '../routes/api/auth/forgot_password.dart' as api_auth_forgot_password;

import '../routes/_middleware.dart' as middleware;

void main() async {
  final address = InternetAddress.tryParse('') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(createStaticFileHandler()).add(buildRootHandler()).handler;
  return entrypoint.run(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline().addMiddleware(middleware.middleware);
  final router = Router()
    ..mount('/ws/dm', (context) => buildWsDmHandler()(context))
    ..mount('/ws/chat', (context) => buildWsChatHandler()(context))
    ..mount('/api', (context) => buildApiHandler()(context))
    ..mount('/api/users', (context) => buildApiUsersHandler()(context))
    ..mount('/api/upload', (context) => buildApiUploadHandler()(context))
    ..mount('/api/tickets', (context) => buildApiTicketsHandler()(context))
    ..mount('/api/rentals', (context) => buildApiRentalsHandler()(context))
    ..mount('/api/open_trips', (context) => buildApiOpenTripsHandler()(context))
    ..mount('/api/mountains', (context) => buildApiMountainsHandler()(context))
    ..mount('/api/gamification', (context) => buildApiGamificationHandler()(context))
    ..mount('/api/explore', (context) => buildApiExploreHandler()(context))
    ..mount('/api/dm', (context) => buildApiDmHandler()(context))
    ..mount('/api/dm/<id>', (context,id,) => buildApiDm$idHandler(id,)(context))
    ..mount('/api/community', (context) => buildApiCommunityHandler()(context))
    ..mount('/api/community/posts/<postId>', (context,postId,) => buildApiCommunityPosts$postIdHandler(postId,)(context))
    ..mount('/api/community/<id>', (context,id,) => buildApiCommunity$idHandler(id,)(context))
    ..mount('/api/community/<id>/posts', (context,id,) => buildApiCommunity$idPostsHandler(id,)(context))
    ..mount('/api/chat/<communityId>', (context,communityId,) => buildApiChat$communityIdHandler(communityId,)(context))
    ..mount('/api/auth', (context) => buildApiAuthHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildWsDmHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<conversationId>', (context,conversationId,) => ws_dm_$conversation_id.onRequest(context,conversationId,));
  return pipeline.addHandler(router);
}

Handler buildWsChatHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<communityId>', (context,communityId,) => ws_chat_$community_id.onRequest(context,communityId,));
  return pipeline.addHandler(router);
}

Handler buildApiHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/report', (context) => api_report.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiUsersHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/search', (context) => api_users_search.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiUploadHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/image', (context) => api_upload_image.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiTicketsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => api_tickets_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiRentalsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/items', (context) => api_rentals_items.onRequest(context,))..all('/vendors', (context) => api_rentals_vendors.onRequest(context,))..all('/', (context) => api_rentals_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiOpenTripsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/book', (context) => api_open_trips_book.onRequest(context,))..all('/', (context) => api_open_trips_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiMountainsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => api_mountains_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiGamificationHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/me', (context) => api_gamification_me.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiExploreHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => api_explore_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiDmHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => api_dm_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiDm$idHandler(String id,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/block', (context) => api_dm_$id_block.onRequest(context,id,))..all('/messages', (context) => api_dm_$id_messages.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildApiCommunityHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/feed', (context) => api_community_feed.onRequest(context,))..all('/trending', (context) => api_community_trending.onRequest(context,))..all('/', (context) => api_community_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiCommunityPosts$postIdHandler(String postId,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/comments', (context) => api_community_posts_$post_id_comments.onRequest(context,postId,))..all('/like', (context) => api_community_posts_$post_id_like.onRequest(context,postId,))..all('/share', (context) => api_community_posts_$post_id_share.onRequest(context,postId,))..all('/', (context) => api_community_posts_$post_id_index.onRequest(context,postId,));
  return pipeline.addHandler(router);
}

Handler buildApiCommunity$idHandler(String id,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/join', (context) => api_community_$id_join.onRequest(context,id,))..all('/members', (context) => api_community_$id_members.onRequest(context,id,))..all('/', (context) => api_community_$id_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildApiCommunity$idPostsHandler(String id,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => api_community_$id_posts_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildApiChat$communityIdHandler(String communityId,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/messages', (context) => api_chat_$community_id_messages.onRequest(context,communityId,))..all('/read', (context) => api_chat_$community_id_read.onRequest(context,communityId,))..all('/', (context) => api_chat_$community_id_index.onRequest(context,communityId,));
  return pipeline.addHandler(router);
}

Handler buildApiAuthHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/forgot_password', (context) => api_auth_forgot_password.onRequest(context,))..all('/login', (context) => api_auth_login.onRequest(context,))..all('/me', (context) => api_auth_me.onRequest(context,))..all('/profile', (context) => api_auth_profile.onRequest(context,))..all('/register', (context) => api_auth_register.onRequest(context,))..all('/reset_password', (context) => api_auth_reset_password.onRequest(context,));
  return pipeline.addHandler(router);
}

