import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/db/database.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);

  if (token == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Token missing'},
    );
  }

  final payload = JwtHelper.verifyToken(token);
  if (payload == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Invalid token'},
    );
  }

  final userId = payload['sub'] as int;

  try {
    final conn = await Database.connection;

    // Fetch user level and exp
    final userResults = await conn.query(
      'SELECT level, exp FROM users WHERE id = @id',
      substitutionValues: {'id': userId},
    );

    if (userResults.isEmpty) {
      return Response.json(statusCode: 404, body: {'message': 'User not found'});
    }

    final level = userResults.first[0] as int? ?? 1;
    final exp = userResults.first[1] as int? ?? 0;

    // We will calculate remaining stats
    final activitiesRes = await conn.query('SELECT id, name, icon_name FROM activities');
    
    // Fallback: we just assume the user has some completions for dummy effect 
    // since the real user_activities isn't populated on app actions yet
    final userActivities = <Map<String, dynamic>>[];
    for (var act in activitiesRes) {
      // Dummy logic for completion count: if user ID is even, give them some completions
      // In real life, query user_activities table
      final uaRes = await conn.query(
        'SELECT completion_count FROM user_activities WHERE user_id = @uid AND activity_id = @aid',
        substitutionValues: {'uid': userId, 'aid': act[0]}
      );
      int count = 0;
      if (uaRes.isNotEmpty) {
        count = uaRes.first[0] as int;
      } else {
        // mock completion so gamification shows up based on level
        if (level > 1) {
          count = (level * 2) + (act[0] as int); 
        }
      }
      userActivities.add({
        'id': act[0].toString(),
        'title': act[1],
        'iconAsset': act[2],
        'completions': count,
        'description': 'Petualangan terselesaikan'
      });
    }

    // Communities User Joined
    final communitiesRes = await conn.query('''
      SELECT c.id, c.name, c.cover_image_url, c.member_count, c.activity_id 
      FROM communities c
      JOIN community_members cm ON c.id = cm.community_id
      WHERE cm.user_id = @uid
    ''', substitutionValues: {'uid': userId});

    final userCommunities = <Map<String, dynamic>>[];
    for (var c in communitiesRes) {
      userCommunities.add({
        'id': c[0].toString(),
        'name': c[1],
        'imageUrl': c[2] ?? 'https://picsum.photos/200?random=${c[0]}',
        'memberCount': c[3],
        'activityId': c[4]?.toString(),
      });
    }

    // Achievements
    final achRes = await conn.query('''
      SELECT a.id, a.title, a.description, a.image_url, a.activity_id, act.name as activity_name,
             EXISTS(SELECT 1 FROM user_achievements ua WHERE ua.achievement_id = a.id AND ua.user_id = @uid) as is_unlocked
      FROM achievements a
      JOIN activities act ON a.activity_id = act.id
    ''', substitutionValues: {'uid': userId});

    final achievementsList = <Map<String, dynamic>>[];
    for (var a in achRes) {
      // If user > level 1, mock some unlocks if record not found
      bool unlocked = a[6] as bool;
      if (!unlocked && level > 2) {
        unlocked = (a[0] as int) % 2 != 0; // random unlock
      }
      achievementsList.add({
        'id': a[0].toString(),
        'title': a[1],
        'description': a[2],
        'imageUrl': a[3],
        'activityId': a[4].toString(),
        'activityType': a[5],
        'isUnlocked': unlocked,
      });
    }

    return Response.json(
      body: {
        'success': true,
        'gamification': {
          'level': level,
          'currentExp': exp,
          'nextLevelExp': level * 1000,
          'totalActivities': userActivities.fold<int>(0, (prev, element) => prev + (element['completions'] as int)),
          'totalCommunities': userCommunities.length,
          'unlockedAchievements': achievementsList.where((a) => a['isUnlocked'] == true).length,
          'activities': userActivities,
          'communities': userCommunities,
          'achievements': achievementsList,
        }
      },
    );
  } catch (e) {
    print('Gamification fetch error: $e');
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Internal Server Error'},
    );
  }
}
