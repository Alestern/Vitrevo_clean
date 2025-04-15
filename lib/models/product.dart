class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String nutritionText;
  
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.nutritionText,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      nutritionText: json['nutritionText'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'nutritionText': nutritionText,
    };
  }
} 