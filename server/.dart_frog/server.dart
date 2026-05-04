// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../main.dart' as entrypoint;
import '../routes/ws/dm/[conversationId].dart' as ws_dm_$conversation_id;
import '../routes/ws/chat/[communityId].dart' as ws_chat_$community_id;
import '../routes/api/report.dart' as api_report;
import '../routes/api/users/search.dart' as api_users_search;
import '../routes/api/users/me/upcoming_bookings.dart' as api_users_me_upcoming_bookings;
import '../routes/api/users/me/orders.dart' as api_users_me_orders;
import '../routes/api/upload/image.dart' as api_upload_image;
import '../routes/api/tickets/index.dart' as api_tickets_index;
import '../routes/api/rentals/vendors.dart' as api_rentals_vendors;
import '../routes/api/rentals/items.dart' as api_rentals_items;
import '../routes/api/rentals/index.dart' as api_rentals_index;
import '../routes/api/open_trips/index.dart' as api_open_trips_index;
import '../routes/api/open_trips/book.dart' as api_open_trips_book;
import '../routes/api/mountains/index.dart' as api_mountains_index;
import '../routes/api/mitra/me/vendor.dart' as api_mitra_me_vendor;
import '../routes/api/mitra/me/stats.dart' as api_mitra_me_stats;
import '../routes/api/mitra/me/orders/index.dart' as api_mitra_me_orders_index;
import '../routes/api/mitra/me/orders/[id].dart' as api_mitra_me_orders_$id;
import '../routes/api/mitra/me/items/index.dart' as api_mitra_me_items_index;
import '../routes/api/mitra/me/items/[id].dart' as api_mitra_me_items_$id;
import '../routes/api/gamification/me.dart' as api_gamification_me;
import '../routes/api/explore/index.dart' as api_explore_index;
import '../routes/api/events/index.dart' as api_events_index;
import '../routes/api/events/[id]/index.dart' as api_events_$id_index;
import '../routes/api/dm/index.dart' as api_dm_index;
import '../routes/api/dm/[id]/messages.dart' as api_dm_$id_messages;
import '../routes/api/dm/[id]/block.dart' as api_dm_$id_block;
import '../routes/api/community/trending.dart' as api_community_trending;
import '../routes/api/community/index.dart' as api_community_index;
import '../routes/api/community/categories.dart' as api_community_categories;
import '../routes/api/community/posts/[postId]/like.dart' as api_community_posts_$post_id_like;
import '../routes/api/community/posts/[postId]/comments.dart' as api_community_posts_$post_id_comments;
import '../routes/api/community/[id]/rules.dart' as api_community_$id_rules;
import '../routes/api/community/[id]/rating.dart' as api_community_$id_rating;
import '../routes/api/community/[id]/posts.dart' as api_community_$id_posts;
import '../routes/api/community/[id]/photos.dart' as api_community_$id_photos;
import '../routes/api/community/[id]/members.dart' as api_community_$id_members;
import '../routes/api/community/[id]/join.dart' as api_community_$id_join;
import '../routes/api/community/[id]/index.dart' as api_community_$id_index;
import '../routes/api/community/[id]/events.dart' as api_community_$id_events;
import '../routes/api/chat/[communityId]/read.dart' as api_chat_$community_id_read;
import '../routes/api/chat/[communityId]/messages.dart' as api_chat_$community_id_messages;
import '../routes/api/chat/[communityId]/index.dart' as api_chat_$community_id_index;
import '../routes/api/buddies/index.dart' as api_buddies_index;
import '../routes/api/buddies/[id]/index.dart' as api_buddies_$id_index;
import '../routes/api/buddies/[id]/apply.dart' as api_buddies_$id_apply;
import '../routes/api/auth/verify_identity.dart' as api_auth_verify_identity;
import '../routes/api/auth/reset_password.dart' as api_auth_reset_password;
import '../routes/api/auth/register.dart' as api_auth_register;
import '../routes/api/auth/profile.dart' as api_auth_profile;
import '../routes/api/auth/me.dart' as api_auth_me;
import '../routes/api/auth/login.dart' as api_auth_login;
import '../routes/api/auth/google_login.dart' as api_auth_google_login;
import '../routes/api/auth/forgot_password.dart' as api_auth_forgot_password;
import '../routes/api/articles/index.dart' as api_articles_index;
import '../routes/api/articles/[id]/view.dart' as api_articles_$id_view;
import '../routes/api/articles/[id]/share.dart' as api_articles_$id_share;
import '../routes/api/articles/[id]/like.dart' as api_articles_$id_like;
import '../routes/api/articles/[id]/comments.dart' as api_articles_$id_comments;
import '../routes/api/admin/dashboard.dart' as api_admin_dashboard;
import '../routes/api/admin/verifications/index.dart' as api_admin_verifications_index;
import '../routes/api/admin/verifications/[id].dart' as api_admin_verifications_$id;
import '../routes/api/admin/users/index.dart' as api_admin_users_index;
import '../routes/api/admin/users/[id].dart' as api_admin_users_$id;
import '../routes/api/admin/reports/index.dart' as api_admin_reports_index;
import '../routes/api/admin/reports/[id].dart' as api_admin_reports_$id;
import '../routes/api/admin/mountains/index.dart' as api_admin_mountains_index;
import '../routes/api/admin/mountains/[id]/index.dart' as api_admin_mountains_$id_index;
import '../routes/api/admin/mountains/[id]/routes/index.dart' as api_admin_mountains_$id_routes_index;
import '../routes/api/admin/mountains/[id]/routes/[routeId].dart' as api_admin_mountains_$id_routes_$route_id;
import '../routes/api/admin/community/posts/[id].dart' as api_admin_community_posts_$id;

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
    ..mount('/api/users/me', (context) => buildApiUsersMeHandler()(context))
    ..mount('/api/upload', (context) => buildApiUploadHandler()(context))
    ..mount('/api/tickets', (context) => buildApiTicketsHandler()(context))
    ..mount('/api/rentals', (context) => buildApiRentalsHandler()(context))
    ..mount('/api/open_trips', (context) => buildApiOpenTripsHandler()(context))
    ..mount('/api/mountains', (context) => buildApiMountainsHandler()(context))
    ..mount('/api/mitra/me', (context) => buildApiMitraMeHandler()(context))
    ..mount('/api/mitra/me/orders', (context) => buildApiMitraMeOrdersHandler()(context))
    ..mount('/api/mitra/me/items', (context) => buildApiMitraMeItemsHandler()(context))
    ..mount('/api/gamification', (context) => buildApiGamificationHandler()(context))
    ..mount('/api/explore', (context) => buildApiExploreHandler()(context))
    ..mount('/api/events', (context) => buildApiEventsHandler()(context))
    ..mount('/api/events/<id>', (context,id,) => buildApiEvents$idHandler(id,)(context))
    ..mount('/api/dm', (context) => buildApiDmHandler()(context))
    ..mount('/api/dm/<id>', (context,id,) => buildApiDm$idHandler(id,)(context))
    ..mount('/api/community', (context) => buildApiCommunityHandler()(context))
    ..mount('/api/community/posts/<postId>', (context,postId,) => buildApiCommunityPosts$postIdHandler(postId,)(context))
    ..mount('/api/community/<id>', (context,id,) => buildApiCommunity$idHandler(id,)(context))
    ..mount('/api/chat/<communityId>', (context,communityId,) => buildApiChat$communityIdHandler(communityId,)(context))
    ..mount('/api/buddies', (context) => buildApiBuddiesHandler()(context))
    ..mount('/api/buddies/<id>', (context,id,) => buildApiBuddies$idHandler(id,)(context))
    ..mount('/api/auth', (context) => buildApiAuthHandler()(context))
    ..mount('/api/articles', (context) => buildApiArticlesHandler()(context))
    ..mount('/api/articles/<id>', (context,id,) => buildApiArticles$idHandler(id,)(context))
    ..mount('/api/admin', (context) => buildApiAdminHandler()(context))
    ..mount('/api/admin/verifications', (context) => buildApiAdminVerificationsHandler()(context))
    ..mount('/api/admin/users', (context) => buildApiAdminUsersHandler()(context))
    ..mount('/api/admin/reports', (context) => buildApiAdminReportsHandler()(context))
    ..mount('/api/admin/mountains', (context) => buildApiAdminMountainsHandler()(context))
    ..mount('/api/admin/mountains/<id>', (context,id,) => buildApiAdminMountains$idHandler(id,)(context))
    ..mount('/', (context) => buildHandler()(context))
    ..mount('/api/admin/community/posts', (context) => buildApiAdminCommunityPostsHandler()(context));
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

Handler buildApiUsersMeHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/orders', (context) => api_users_me_orders.onRequest(context,))..all('/upcoming_bookings', (context) => api_users_me_upcoming_bookings.onRequest(context,));
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

Handler buildApiMitraMeHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/stats', (context) => api_mitra_me_stats.onRequest(context,))..all('/vendor', (context) => api_mitra_me_vendor.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiMitraMeOrdersHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<id>', (context,id,) => api_mitra_me_orders_$id.onRequest(context,id,))..all('/', (context) => api_mitra_me_orders_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiMitraMeItemsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<id>', (context,id,) => api_mitra_me_items_$id.onRequest(context,id,))..all('/', (context) => api_mitra_me_items_index.onRequest(context,));
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

Handler buildApiEventsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => api_events_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiEvents$idHandler(String id,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => api_events_$id_index.onRequest(context,id,));
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
    ..all('/categories', (context) => api_community_categories.onRequest(context,))..all('/trending', (context) => api_community_trending.onRequest(context,))..all('/', (context) => api_community_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiCommunityPosts$postIdHandler(String postId,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/comments', (context) => api_community_posts_$post_id_comments.onRequest(context,postId,))..all('/like', (context) => api_community_posts_$post_id_like.onRequest(context,postId,));
  return pipeline.addHandler(router);
}

Handler buildApiCommunity$idHandler(String id,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/events', (context) => api_community_$id_events.onRequest(context,id,))..all('/join', (context) => api_community_$id_join.onRequest(context,id,))..all('/members', (context) => api_community_$id_members.onRequest(context,id,))..all('/photos', (context) => api_community_$id_photos.onRequest(context,id,))..all('/posts', (context) => api_community_$id_posts.onRequest(context,id,))..all('/rating', (context) => api_community_$id_rating.onRequest(context,id,))..all('/rules', (context) => api_community_$id_rules.onRequest(context,id,))..all('/', (context) => api_community_$id_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildApiChat$communityIdHandler(String communityId,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/messages', (context) => api_chat_$community_id_messages.onRequest(context,communityId,))..all('/read', (context) => api_chat_$community_id_read.onRequest(context,communityId,))..all('/', (context) => api_chat_$community_id_index.onRequest(context,communityId,));
  return pipeline.addHandler(router);
}

Handler buildApiBuddiesHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => api_buddies_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiBuddies$idHandler(String id,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/apply', (context) => api_buddies_$id_apply.onRequest(context,id,))..all('/', (context) => api_buddies_$id_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildApiAuthHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/forgot_password', (context) => api_auth_forgot_password.onRequest(context,))..all('/google_login', (context) => api_auth_google_login.onRequest(context,))..all('/login', (context) => api_auth_login.onRequest(context,))..all('/me', (context) => api_auth_me.onRequest(context,))..all('/profile', (context) => api_auth_profile.onRequest(context,))..all('/register', (context) => api_auth_register.onRequest(context,))..all('/reset_password', (context) => api_auth_reset_password.onRequest(context,))..all('/verify_identity', (context) => api_auth_verify_identity.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiArticlesHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => api_articles_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiArticles$idHandler(String id,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/comments', (context) => api_articles_$id_comments.onRequest(context,id,))..all('/like', (context) => api_articles_$id_like.onRequest(context,id,))..all('/share', (context) => api_articles_$id_share.onRequest(context,id,))..all('/view', (context) => api_articles_$id_view.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildApiAdminHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/dashboard', (context) => api_admin_dashboard.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiAdminVerificationsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<id>', (context,id,) => api_admin_verifications_$id.onRequest(context,id,))..all('/', (context) => api_admin_verifications_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiAdminUsersHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<id>', (context,id,) => api_admin_users_$id.onRequest(context,id,))..all('/', (context) => api_admin_users_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiAdminReportsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<id>', (context,id,) => api_admin_reports_$id.onRequest(context,id,))..all('/', (context) => api_admin_reports_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiAdminMountainsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => api_admin_mountains_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiAdminMountains$idHandler(String id,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => api_admin_mountains_$id_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/api/admin/mountains/<id>/routes/<routeId>', (context,id,routeId,) => api_admin_mountains_$id_routes_$route_id.onRequest(context,id,routeId,))..all('/api/admin/mountains/<id>/routes', (context,id,) => api_admin_mountains_$id_routes_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildApiAdminCommunityPostsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<id>', (context,id,) => api_admin_community_posts_$id.onRequest(context,id,));
  return pipeline.addHandler(router);
}

