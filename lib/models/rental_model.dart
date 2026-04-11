class RentalItemModel {
  final int id;
  final String name;
  final String category;
  final String description;
  final double pricePerDay;
  final String imageUrl;
  final int stock;
  final int availableStock;
  final String brand;
  final String condition;

  RentalItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.pricePerDay,
    required this.imageUrl,
    required this.stock,
    required this.availableStock,
    required this.brand,
    required this.condition,
  });

  factory RentalItemModel.fromJson(Map<String, dynamic> json) {
    return RentalItemModel(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      pricePerDay: (json['price_per_day'] as num).toDouble(),
      imageUrl: json['image_url'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
      availableStock: json['available_stock'] as int? ?? 0,
      brand: json['brand'] as String? ?? 'No Brand',
      condition: json['condition'] as String? ?? 'Baik',
    );
  }
}

class RentalCartItem {
  final RentalItemModel item;
  int quantity;

  RentalCartItem({
    required this.item,
    this.quantity = 1,
  });
}
