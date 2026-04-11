class RouteModel {
  final int id;
  final String name;
  final String? description;

  RouteModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

class MountainModel {
  final int id;
  final String name;
  final String location;
  final int elevation;
  final String difficulty;
  final double price;
  final String imageUrl;
  final String description;
  final List<RouteModel> routes;

  MountainModel({
    required this.id,
    required this.name,
    required this.location,
    required this.elevation,
    required this.difficulty,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.routes = const [],
  });

  factory MountainModel.fromJson(Map<String, dynamic> json) {
    return MountainModel(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String,
      elevation: json['elevation'] is int ? json['elevation'] as int : int.parse(json['elevation'].toString()),
      difficulty: json['difficulty'] as String,
      price: json['price'] is num ? (json['price'] as num).toDouble() : double.parse(json['price'].toString()),
      imageUrl: json['image_url'] as String,
      description: json['description'] as String,
      routes: (json['routes'] as List?)
              ?.map((r) => RouteModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
