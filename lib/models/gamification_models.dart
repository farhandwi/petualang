class GamificationActivity {
  final String id;
  final String title;
  final String iconAsset; // or IconData via a mapper
  final int completions;
  final String description;

  GamificationActivity({
    required this.id,
    required this.title,
    required this.iconAsset,
    required this.completions,
    required this.description,
  });

  factory GamificationActivity.fromJson(Map<String, dynamic> json) {
    return GamificationActivity(
      id: json['id'].toString(),
      title: json['title'],
      iconAsset: json['iconAsset'],
      completions: json['completions'] as int,
      description: json['description'],
    );
  }
}

class Community {
  final String id;
  final String name;
  final String imageUrl;
  final int memberCount;
  final String? activityId;

  Community({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.memberCount,
    this.activityId,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'].toString(),
      name: json['name'],
      imageUrl: json['imageUrl'] ?? 'https://picsum.photos/200',
      memberCount: json['memberCount'] as int? ?? 0,
      activityId: json['activityId']?.toString(),
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description; 
  final String activityType; 
  final String activityId;
  final bool isUnlocked;
  final String imageUrl;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.activityType,
    required this.activityId,
    required this.isUnlocked,
    required this.imageUrl,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'],
      activityType: json['activityType'],
      activityId: json['activityId'].toString(),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      imageUrl: json['imageUrl'],
    );
  }
}

class UserGamificationProfile {
  final int level;
  final int currentExp;
  final int nextLevelExp;
  final int totalActivities;
  final int totalCommunities;
  final int unlockedAchievements;
  final List<GamificationActivity> activities;
  final List<Community> communities;
  final List<Achievement> achievements;

  UserGamificationProfile({
    required this.level,
    required this.currentExp,
    required this.nextLevelExp,
    required this.totalActivities,
    required this.totalCommunities,
    required this.unlockedAchievements,
    required this.activities,
    required this.communities,
    required this.achievements,
  });

  factory UserGamificationProfile.fromJson(Map<String, dynamic> json) {
    var actList = json['activities'] as List? ?? [];
    var commList = json['communities'] as List? ?? [];
    var achList = json['achievements'] as List? ?? [];
    
    return UserGamificationProfile(
      level: json['level'] as int? ?? 1,
      currentExp: json['currentExp'] as int? ?? 0,
      nextLevelExp: json['nextLevelExp'] as int? ?? 1000,
      totalActivities: json['totalActivities'] as int? ?? 0,
      totalCommunities: json['totalCommunities'] as int? ?? 0,
      unlockedAchievements: json['unlockedAchievements'] as int? ?? 0,
      activities: actList.map((j) => GamificationActivity.fromJson(j)).toList(),
      communities: commList.map((j) => Community.fromJson(j)).toList(),
      achievements: achList.map((j) => Achievement.fromJson(j)).toList(),
    );
  }
}
