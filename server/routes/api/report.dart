import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/community_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// POST /api/report — laporkan post/komentar/pesan
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'success': false, 'message': 'Method not allowed'});
  }

  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);
  final payload = token != null ? JwtHelper.verifyToken(token) : null;
  final userId = payload?['sub'] as int?;

  if (userId == null) {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Autentikasi diperlukan'});
  }

  try {
    final bodyString = await context.request.body();
    final body = json.decode(bodyString) as Map<String, dynamic>;
    final reason = body['reason'] as String?;
    final targetType = body['target_type'] as String?; // 'post' | 'comment' | 'message'
    final targetId = body['target_id'] as int?;

    if (reason == null || reason.trim().isEmpty) {
      return Response.json(statusCode: 400, body: {'success': false, 'message': 'Alasan laporan wajib diisi'});
    }
    if (targetType == null || targetId == null) {
      return Response.json(statusCode: 400, body: {'success': false, 'message': 'Target laporan tidak valid'});
    }

    await CommunityService.createReport(
      reporterId: userId,
      reason: reason.trim(),
      postId: targetType == 'post' ? targetId : null,
      commentId: targetType == 'comment' ? targetId : null,
      messageId: targetType == 'message' ? targetId : null,
    );

    return Response.json(body: {'success': true, 'message': 'Laporan berhasil dikirim. Tim kami akan meninjau laporan Anda.'});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'success': false, 'message': 'Gagal mengirim laporan'});
  }
}
