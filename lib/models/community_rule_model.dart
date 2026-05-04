class CommunityRuleModel {
  final int id;
  final int ordinal;
  final String text;

  CommunityRuleModel({
    required this.id,
    required this.ordinal,
    required this.text,
  });

  factory CommunityRuleModel.fromJson(Map<String, dynamic> json) {
    return CommunityRuleModel(
      id: json['id'] as int,
      ordinal: json['ordinal'] as int? ?? 0,
      text: (json['text'] as String?) ?? '',
    );
  }
}
