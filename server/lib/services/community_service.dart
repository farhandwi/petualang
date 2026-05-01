import 'package:petualang_server/db/database.dart';

class CommunityService {
  // ─── Communities ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> listCommunities({
    int? userId,
    String? search,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    final conn = await Database.connection;
    var where = 'WHERE 1=1';
    final values = <String, dynamic>{};

    if (search != null && search.isNotEmpty) {
      where += ' AND (c.name ILIKE @search OR c.description ILIKE @search)';
      values['search'] = '%$search%';
    }
    if (category != null && category.isNotEmpty && category != 'Semua') {
      where += ' AND c.category = @category';
      values['category'] = category;
    }

    values['limit'] = limit;
    values['offset'] = offset;

    final memberJoin = userId != null
        ? 'LEFT JOIN community_members cm2 ON cm2.community_id = c.id AND cm2.user_id = $userId'
        : '';
    final memberField =
        userId != null ? ', (cm2.id IS NOT NULL) AS is_member' : ', FALSE AS is_member';

    final results = await conn.query(
      '''
      SELECT c.id, c.name, c.slug, c.description, c.cover_image_url,
             c.icon_image_url, c.category, c.privacy,
             c.member_count, c.post_count, c.created_at
             $memberField
      FROM communities c
      $memberJoin
      $where
      ORDER BY c.member_count DESC
      LIMIT @limit OFFSET @offset
      ''',
      substitutionValues: values,
    );

    return results.map((r) => _mapCommunity(r)).toList();
  }

  /// Mengembalikan hingga 10 komunitas dengan postingan terbanyak dalam 24 jam terakhir.
  /// is_member selalu false untuk endpoint home (tidak perlu autentikasi join).
  static Future<List<Map<String, dynamic>>> getTopCommunitiesByPosts24h({
    int limit = 10,
  }) async {
    try {
      final conn = await Database.connection;

      final results = await conn.query(
        '''
        SELECT c.id, c.name, c.slug, c.description, c.cover_image_url,
               c.icon_image_url, c.category, c.privacy,
               c.member_count, c.post_count, c.created_at,
               FALSE AS is_member,
               COUNT(p.id) AS recent_post_count
        FROM communities c
        LEFT JOIN community_posts p
          ON p.community_id = c.id
          AND p.created_at >= NOW() - INTERVAL \'24 hours\'
        GROUP BY c.id
        ORDER BY recent_post_count DESC, c.member_count DESC
        LIMIT @limit
        ''',
        substitutionValues: {'limit': limit},
      );

      print('[Trending] Query returned ${results.length} communities');
      return results.map((r) => _mapCommunityTrending(r)).toList();
    } catch (e, st) {
      print('[Trending] ERROR in getTopCommunitiesByPosts24h: $e\n$st');
      return [];
    }
  }


  static Future<Map<String, dynamic>?> getCommunityById(
    int id, {
    int? userId,
  }) async {
    final conn = await Database.connection;
    final memberJoin = userId != null
        ? 'LEFT JOIN community_members cm2 ON cm2.community_id = c.id AND cm2.user_id = $userId'
        : '';
    final memberField =
        userId != null ? ', (cm2.id IS NOT NULL) AS is_member' : ', FALSE AS is_member';

    final results = await conn.query(
      '''
      SELECT c.id, c.name, c.slug, c.description, c.cover_image_url,
             c.icon_image_url, c.category, c.privacy,
             c.member_count, c.post_count, c.created_at
             $memberField
      FROM communities c
      $memberJoin
      WHERE c.id = @id
      ''',
      substitutionValues: {'id': id},
    );
    if (results.isEmpty) return null;
    return _mapCommunity(results.first);
  }

  // ─── Members ────────────────────────────────────────────────

  static Future<bool> joinCommunity(int communityId, int userId) async {
    final conn = await Database.connection;
    try {
      await conn.execute(
        '''
        INSERT INTO community_members (community_id, user_id, role)
        VALUES (@cid, @uid, 'member')
        ON CONFLICT DO NOTHING
        ''',
        substitutionValues: {'cid': communityId, 'uid': userId},
      );
      await conn.execute(
        '''
        UPDATE communities SET member_count = member_count + 1 WHERE id = @id
        AND NOT EXISTS (
          SELECT 1 FROM community_members WHERE community_id = @id AND user_id = @uid
          AND joined_at < NOW() - interval '1 second'
        )
        ''',
        substitutionValues: {'id': communityId, 'uid': userId},
      );
      // Simpler: just increment
      await conn.execute(
        'UPDATE communities SET member_count = (SELECT COUNT(*) FROM community_members WHERE community_id = @id) WHERE id = @id',
        substitutionValues: {'id': communityId},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> leaveCommunity(int communityId, int userId) async {
    final conn = await Database.connection;
    await conn.execute(
      'DELETE FROM community_members WHERE community_id = @cid AND user_id = @uid',
      substitutionValues: {'cid': communityId, 'uid': userId},
    );
    await conn.execute(
      'UPDATE communities SET member_count = (SELECT COUNT(*) FROM community_members WHERE community_id = @id) WHERE id = @id',
      substitutionValues: {'id': communityId},
    );
    return true;
  }

  static Future<List<Map<String, dynamic>>> getMembers(
    int communityId, {
    int limit = 30,
    int offset = 0,
  }) async {
    final conn = await Database.connection;
    final results = await conn.query(
      '''
      SELECT u.id, u.name, u.profile_picture, u.level, cm.role, cm.joined_at
      FROM community_members cm
      JOIN users u ON u.id = cm.user_id
      WHERE cm.community_id = @cid
      ORDER BY cm.role DESC, cm.joined_at ASC
      LIMIT @limit OFFSET @offset
      ''',
      substitutionValues: {'cid': communityId, 'limit': limit, 'offset': offset},
    );
    return results
        .map((r) => {
              'id': r[0],
              'name': r[1],
              'profile_picture': r[2],
              'level': r[3],
              'role': r[4],
              'joined_at': (r[5] as DateTime?)?.toIso8601String(),
            })
        .toList();
  }

  static Future<bool> isMember(int communityId, int userId) async {
    final conn = await Database.connection;
    final r = await conn.query(
      'SELECT 1 FROM community_members WHERE community_id = @cid AND user_id = @uid',
      substitutionValues: {'cid': communityId, 'uid': userId},
    );
    return r.isNotEmpty;
  }

  // ─── Posts ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPosts(
    int communityId, {
    int? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final conn = await Database.connection;
    final likeJoin = userId != null
        ? 'LEFT JOIN community_likes cl ON cl.post_id = p.id AND cl.user_id = $userId'
        : '';
    final likeField = userId != null ? ', (cl.id IS NOT NULL) AS is_liked' : ', FALSE AS is_liked';

    final results = await conn.query(
      '''
      SELECT p.id, p.community_id, p.user_id, u.name AS author_name,
             u.profile_picture AS author_avatar, u.level AS author_level,
             p.content, p.image_url, p.like_count, p.comment_count, p.share_count,
             p.is_pinned, p.created_at, c.name AS community_name
             $likeField
      FROM community_posts p
      JOIN users u ON u.id = p.user_id
      JOIN communities c ON c.id = p.community_id
      $likeJoin
      WHERE p.community_id = @cid
      ORDER BY p.is_pinned DESC, p.created_at DESC
      LIMIT @limit OFFSET @offset
      ''',
      substitutionValues: {'cid': communityId, 'limit': limit, 'offset': offset},
    );
    print('DEBUG: CommunityService.getPosts SQL result count: ${results.length} for CID: $communityId');
    return results.map((r) => _mapPost(r)).toList();
  }

  static Future<List<Map<String, dynamic>>> getGlobalFeed(
    int userId, {
    int limit = 30,
    int offset = 0,
  }) async {
    final conn = await Database.connection;
    final results = await conn.query(
      '''
      SELECT p.id, p.community_id, p.user_id, u.name AS author_name,
             u.profile_picture AS author_avatar, u.level AS author_level,
             p.content, p.image_url, p.like_count, p.comment_count, p.share_count,
             p.is_pinned, p.created_at, c.name AS community_name,
             (cl.id IS NOT NULL) AS is_liked
      FROM community_posts p
      JOIN users u ON u.id = p.user_id
      JOIN communities c ON c.id = p.community_id
      JOIN community_members cm ON cm.community_id = p.community_id AND cm.user_id = @uid
      LEFT JOIN community_likes cl ON cl.post_id = p.id AND cl.user_id = @uid
      ORDER BY p.created_at DESC
      LIMIT @limit OFFSET @offset
      ''',
      substitutionValues: {'uid': userId, 'limit': limit, 'offset': offset},
    );
    return results.map((r) => _mapPost(r)).toList();
  }

  static Future<List<Map<String, dynamic>>> getUserPosts(
    int userId, {
    int limit = 30,
    int offset = 0,
  }) async {
    final conn = await Database.connection;
    final results = await conn.query(
      '''
      SELECT p.id, p.community_id, p.user_id, u.name AS author_name,
             u.profile_picture AS author_avatar, u.level AS author_level,
             p.content, p.image_url, p.like_count, p.comment_count, p.share_count,
             p.is_pinned, p.created_at, c.name AS community_name,
             (cl.id IS NOT NULL) AS is_liked
      FROM community_posts p
      JOIN users u ON u.id = p.user_id
      JOIN communities c ON c.id = p.community_id
      LEFT JOIN community_likes cl ON cl.post_id = p.id AND cl.user_id = @uid
      WHERE p.user_id = @uid
      ORDER BY p.created_at DESC
      LIMIT @limit OFFSET @offset
      ''',
      substitutionValues: {'uid': userId, 'limit': limit, 'offset': offset},
    );
    return results.map((r) => _mapPost(r)).toList();
  }

  static Future<Map<String, dynamic>?> getPostById(int postId, {int? userId}) async {
    final conn = await Database.connection;
    final likeJoin = userId != null
        ? 'LEFT JOIN community_likes cl ON cl.post_id = p.id AND cl.user_id = $userId'
        : '';
    final likeField = userId != null ? ', (cl.id IS NOT NULL) AS is_liked' : ', FALSE AS is_liked';

    final results = await conn.query(
      '''
      SELECT p.id, p.community_id, p.user_id, u.name,
             u.profile_picture, u.level AS author_level, p.content, p.image_url, p.like_count,
             p.comment_count, p.share_count, p.is_pinned, p.created_at, c.name
             $likeField
      FROM community_posts p
      JOIN users u ON u.id = p.user_id
      JOIN communities c ON c.id = p.community_id
      $likeJoin
      WHERE p.id = @id
      ''',
      substitutionValues: {'id': postId},
    );
    if (results.isEmpty) return null;
    return _mapPost(results.first);
  }

  static Future<Map<String, dynamic>> createPost({
    required int communityId,
    required int userId,
    required String content,
    String? imageUrl,
  }) async {
    print('DEBUG: CommunityService.createPost received imageUrl: $imageUrl');
    final conn = await Database.connection;
    final result = await conn.query(
      '''
      INSERT INTO community_posts (community_id, user_id, content, image_url)
      VALUES (@cid, @uid, @content, @image)
      RETURNING id, created_at
      ''',
      substitutionValues: {
        'cid': communityId,
        'uid': userId,
        'content': content,
        'image': imageUrl,
      },
    );
    print('DEBUG: CommunityService.createPost INSERT result: $result');
    await conn.execute(
      'UPDATE communities SET post_count = post_count + 1 WHERE id = @id',
      substitutionValues: {'id': communityId},
    );
    final row = result.first;
    return {'id': row[0], 'created_at': (row[1] as DateTime).toIso8601String()};
  }

  static Future<bool> deletePost(int postId, int userId) async {
    final conn = await Database.connection;
    // Only owner or admin can delete
    final result = await conn.query(
      'SELECT community_id, user_id FROM community_posts WHERE id = @id',
      substitutionValues: {'id': postId},
    );
    if (result.isEmpty) return false;
    final postUserId = result.first[1] as int;
    final communityId = result.first[0] as int;

    final isAdmin = await conn.query(
      'SELECT 1 FROM community_members WHERE community_id = @cid AND user_id = @uid AND role = \'admin\'',
      substitutionValues: {'cid': communityId, 'uid': userId},
    );
    if (postUserId != userId && isAdmin.isEmpty) return false;

    await conn.execute(
      'DELETE FROM community_posts WHERE id = @id',
      substitutionValues: {'id': postId},
    );
    await conn.execute(
      'UPDATE communities SET post_count = GREATEST(post_count - 1, 0) WHERE id = @cid',
      substitutionValues: {'cid': communityId},
    );
    return true;
  }

  // ─── Likes ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> toggleLike(int postId, int userId) async {
    final conn = await Database.connection;
    final existing = await conn.query(
      'SELECT id FROM community_likes WHERE post_id = @pid AND user_id = @uid',
      substitutionValues: {'pid': postId, 'uid': userId},
    );
    if (existing.isNotEmpty) {
      await conn.execute(
        'DELETE FROM community_likes WHERE post_id = @pid AND user_id = @uid',
        substitutionValues: {'pid': postId, 'uid': userId},
      );
      await conn.execute(
        'UPDATE community_posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = @id',
        substitutionValues: {'id': postId},
      );
      final r = await conn.query(
        'SELECT like_count FROM community_posts WHERE id = @id',
        substitutionValues: {'id': postId},
      );
      return {'liked': false, 'like_count': r.first[0]};
    } else {
      await conn.execute(
        'INSERT INTO community_likes (user_id, post_id) VALUES (@uid, @pid) ON CONFLICT DO NOTHING',
        substitutionValues: {'pid': postId, 'uid': userId},
      );
      await conn.execute(
        'UPDATE community_posts SET like_count = like_count + 1 WHERE id = @id',
        substitutionValues: {'id': postId},
      );
      final r = await conn.query(
        'SELECT like_count FROM community_posts WHERE id = @id',
        substitutionValues: {'id': postId},
      );
      return {'liked': true, 'like_count': r.first[0]};
    }
  }

  // ─── Share ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> incrementShareCount(int postId) async {
    final conn = await Database.connection;
    await conn.execute(
      'UPDATE community_posts SET share_count = share_count + 1 WHERE id = @id',
      substitutionValues: {'id': postId},
    );
    final r = await conn.query(
      'SELECT share_count FROM community_posts WHERE id = @id',
      substitutionValues: {'id': postId},
    );
    return {'share_count': r.first[0] as int};
  }

  // ─── Comments ────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getComments(
    int postId, {
    int? userId,
  }) async {
    final conn = await Database.connection;
    // Fetch top-level comments
    final results = await conn.query(
      '''
      SELECT c.id, c.post_id, c.user_id, u.name, u.profile_picture, u.level as author_level,
             c.parent_id, c.content, c.image_url, c.like_count, c.created_at
      FROM community_comments c
      JOIN users u ON u.id = c.user_id
      WHERE c.post_id = @pid AND c.parent_id IS NULL
      ORDER BY c.created_at ASC
      ''',
      substitutionValues: {'pid': postId},
    );

    final comments = <Map<String, dynamic>>[];
    for (final r in results) {
      final commentId = r[0] as int;
      // Fetch replies
      final replies = await conn.query(
        '''
        SELECT c.id, c.post_id, c.user_id, u.name, u.profile_picture, u.level as author_level,
               c.parent_id, c.content, c.image_url, c.like_count, c.created_at
        FROM community_comments c
        JOIN users u ON u.id = c.user_id
        WHERE c.parent_id = @pid
        ORDER BY c.created_at ASC
        ''',
        substitutionValues: {'pid': commentId},
      );
      comments.add({
        ..._mapComment(r),
        'replies': replies.map((rep) => _mapComment(rep)).toList(),
      });
    }
    return comments;
  }

  static Future<Map<String, dynamic>> createComment({
    required int postId,
    required int userId,
    required String content,
    int? parentId,
    String? imageUrl,
  }) async {
    final conn = await Database.connection;
    final result = await conn.query(
      '''
      INSERT INTO community_comments (post_id, user_id, content, parent_id, image_url)
      VALUES (@pid, @uid, @content, @parent, @image)
      RETURNING id, created_at
      ''',
      substitutionValues: {
        'pid': postId,
        'uid': userId,
        'content': content,
        'parent': parentId,
        'image': imageUrl,
      },
    );
    if (parentId == null) {
      await conn.execute(
        'UPDATE community_posts SET comment_count = comment_count + 1 WHERE id = @id',
        substitutionValues: {'id': postId},
      );
    }
    final row = result.first;
    return {'id': row[0], 'created_at': (row[1] as DateTime).toIso8601String()};
  }

  static Future<bool> deleteComment(int commentId, int userId) async {
    final conn = await Database.connection;
    final r = await conn.query(
      'SELECT user_id, post_id FROM community_comments WHERE id = @id',
      substitutionValues: {'id': commentId},
    );
    if (r.isEmpty) return false;
    if ((r.first[0] as int) != userId) return false;
    await conn.execute(
      'DELETE FROM community_comments WHERE id = @id',
      substitutionValues: {'id': commentId},
    );
    await conn.execute(
      'UPDATE community_posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = @pid',
      substitutionValues: {'pid': r.first[1]},
    );
    return true;
  }

  // ─── Report ──────────────────────────────────────────────────

  static Future<void> createReport({
    required int reporterId,
    required String reason,
    int? postId,
    int? commentId,
    int? messageId,
  }) async {
    final conn = await Database.connection;
    await conn.execute(
      '''
      INSERT INTO reports (reporter_id, reason, post_id, comment_id, message_id)
      VALUES (@rid, @reason, @post, @comment, @message)
      ''',
      substitutionValues: {
        'rid': reporterId,
        'reason': reason,
        'post': postId,
        'comment': commentId,
        'message': messageId,
      },
    );
  }

  // ─── Helpers ────────────────────────────────────────────────

  static Map<String, dynamic> _mapCommunity(dynamic r) => {
        'id': r[0],
        'name': r[1],
        'slug': r[2],
        'description': r[3],
        'cover_image_url': r[4],
        'icon_image_url': r[5],
        'category': r[6],
        'privacy': r[7],
        'member_count': r[8],
        'post_count': r[9],
        'created_at': (r[10] as DateTime?)?.toIso8601String(),
        'is_member': r[11] ?? false,
      };

  /// Mapper untuk getTopCommunitiesByPosts24h — kolom sama + recent_post_count di index 12.
  static Map<String, dynamic> _mapCommunityTrending(dynamic r) => {
        'id': r[0],
        'name': r[1],
        'slug': r[2],
        'description': r[3],
        'cover_image_url': r[4],
        'icon_image_url': r[5],
        'category': r[6],
        'privacy': r[7],
        'member_count': r[8],
        'post_count': r[9],
        'created_at': (r[10] as DateTime?)?.toIso8601String(),
        'is_member': r[11] ?? false,
        'recent_post_count': r[12] ?? 0,
      };

  static Map<String, dynamic> _mapPost(dynamic r) => {
        'id': r[0],
        'community_id': r[1],
        'user_id': r[2],
        'author_name': r[3],
        'author_avatar': r[4],
        'author_level': r[5],
        'content': r[6],
        'image_url': r[7],
        'like_count': r[8],
        'comment_count': r[9],
        'share_count': r[10],
        'is_pinned': r[11],
        'created_at': (r[12] as DateTime?)?.toIso8601String(),
        'community_name': r[13],
        'is_liked': r[14] ?? false,
      };

  static Map<String, dynamic> _mapComment(dynamic r) => {
        'id': r[0],
        'post_id': r[1],
        'user_id': r[2],
        'author_name': r[3],
        'author_avatar': r[4],
        'author_level': r[5],
        'parent_id': r[6],
        'content': r[7],
        'image_url': r[8],
        'like_count': r[9],
        'created_at': (r[10] as DateTime?)?.toIso8601String(),
        'replies': <Map<String, dynamic>>[],
      };
}
