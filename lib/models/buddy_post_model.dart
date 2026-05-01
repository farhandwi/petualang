class BuddyApplicationModel {
  final int id;
  final int applicantId;
  final String? applicantName;
  final String? applicantPicture;
  final int? applicantLevel;
  final String? message;
  final String status;
  final DateTime createdAt;

  BuddyApplicationModel({
    required this.id,
    required this.applicantId,
    this.applicantName,
    this.applicantPicture,
    this.applicantLevel,
    this.message,
    this.status = 'pending',
    required this.createdAt,
  });

  factory BuddyApplicationModel.fromJson(Map<String, dynamic> json) {
    return BuddyApplicationModel(
      id: json['id'] as int,
      applicantId: json['applicant_id'] as int,
      applicantName: json['applicant_name'] as String?,
      applicantPicture: json['applicant_picture'] as String?,
      applicantLevel: json['applicant_level'] as int?,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class BuddyPostModel {
  final int id;
  final int userId;
  final String? userName;
  final String? userPicture;
  final int? userLevel;
  final int? mountainId;
  final String? mountainName;
  final String? mountainLocation;
  final String? mountainImage;
  final String title;
  final String? description;
  final DateTime targetDate;
  final int maxBuddies;
  final int currentBuddies;
  final String status;
  final DateTime createdAt;
  final List<BuddyApplicationModel> applications;

  BuddyPostModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userPicture,
    this.userLevel,
    this.mountainId,
    this.mountainName,
    this.mountainLocation,
    this.mountainImage,
    required this.title,
    this.description,
    required this.targetDate,
    this.maxBuddies = 1,
    this.currentBuddies = 0,
    this.status = 'open',
    required this.createdAt,
    this.applications = const [],
  });

  int get spotsLeft => maxBuddies - currentBuddies;

  factory BuddyPostModel.fromJson(Map<String, dynamic> json) {
    final apps = json['applications'] as List? ?? [];
    return BuddyPostModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String?,
      userPicture: json['user_picture'] as String?,
      userLevel: json['user_level'] as int?,
      mountainId: json['mountain_id'] as int?,
      mountainName: json['mountain_name'] as String?,
      mountainLocation: json['mountain_location'] as String?,
      mountainImage: json['mountain_image'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetDate: DateTime.parse(json['target_date'] as String),
      maxBuddies: json['max_buddies'] as int? ?? 1,
      currentBuddies: json['current_buddies'] as int? ?? 0,
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['created_at'] as String),
      applications: apps
          .map((a) => BuddyApplicationModel.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
