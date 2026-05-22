enum MenuCategory {
  STARTERS,
  MAIN_COURSE,
  DRINKS,
  DESSERTS,
}

class MenuItemModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final MenuCategory category;
  final bool isAvailable;
  final String? imageUrl;
  final int? estimatedPrepTime;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.isAvailable,
    this.imageUrl,
    this.estimatedPrepTime,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: _parseCategory(json['categoryName'] as String? ?? json['category'] as String?),
      isAvailable: json['isAvailable'] as bool? ?? json['available'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String?,
      estimatedPrepTime: json['estimatedPrepTime'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category.name,
      'categoryName': category.name,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'estimatedPrepTime': estimatedPrepTime,
    };
  }

  static MenuCategory _parseCategory(String? categoryStr) {
    switch (categoryStr) {
      case 'STARTERS':
        return MenuCategory.STARTERS;
      case 'MAIN_COURSE':
        return MenuCategory.MAIN_COURSE;
      case 'DRINKS':
        return MenuCategory.DRINKS;
      case 'DESSERTS':
        return MenuCategory.DESSERTS;
      default:
        return MenuCategory.STARTERS;
    }
  }

  String get categoryDisplay {
    switch (category) {
      case MenuCategory.STARTERS:
        return 'Starters';
      case MenuCategory.MAIN_COURSE:
        return 'Mains';
      case MenuCategory.DRINKS:
        return 'Drinks';
      case MenuCategory.DESSERTS:
        return 'Desserts';
    }
  }
}
