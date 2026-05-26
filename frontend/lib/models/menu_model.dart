class MenuItemModel {
  final String itemId;
  final String itemName;
  final String? description;
  final double price;
  final bool? isVeg;
  final bool isAvailable;
  final int? calories;
  final int? healthScore;
  final String? healthLabel;
  final String? spiceLevel;
  final List<String>? tags;

  const MenuItemModel({
    required this.itemId,
    required this.itemName,
    this.description,
    required this.price,
    this.isVeg,
    this.isAvailable = true,
    this.calories,
    this.healthScore,
    this.healthLabel,
    this.spiceLevel,
    this.tags,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) => MenuItemModel(
        itemId: json['item_id']?.toString() ?? '',
        itemName: json['item_name'] ?? '',
        description: json['description'],
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        isVeg: json['is_veg'],
        isAvailable: json['is_available'] ?? true,
        calories: json['calories'],
        healthScore: json['health_score'],
        healthLabel: json['health_label'],
        spiceLevel: json['spice_level'],
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      );

  String get priceDisplay => '₹${price.toStringAsFixed(0)}';
}

class MenuSectionModel {
  final String sectionId;
  final String sectionName;
  final List<MenuItemModel> items;

  const MenuSectionModel({
    required this.sectionId,
    required this.sectionName,
    required this.items,
  });

  factory MenuSectionModel.fromJson(Map<String, dynamic> json) =>
      MenuSectionModel(
        sectionId: json['section_id']?.toString() ?? '',
        sectionName: json['section_name'] ?? '',
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Response from GET /restaurants/{id}/menu
class RestaurantMenuResponse {
  final RestaurantMenuInfo restaurant;
  final List<MenuSectionModel> sections;

  const RestaurantMenuResponse({
    required this.restaurant,
    required this.sections,
  });

  factory RestaurantMenuResponse.fromJson(Map<String, dynamic> json) =>
      RestaurantMenuResponse(
        restaurant: RestaurantMenuInfo.fromJson(
            json['restaurant'] as Map<String, dynamic>),
        sections: (json['sections'] as List<dynamic>? ?? [])
            .map((e) => MenuSectionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get totalItems =>
      sections.fold(0, (sum, s) => sum + s.items.length);
}

class RestaurantMenuInfo {
  final String restaurantId;
  final String restaurantName;
  final List<String>? cuisineType;
  final String? priceCategory;

  const RestaurantMenuInfo({
    required this.restaurantId,
    required this.restaurantName,
    this.cuisineType,
    this.priceCategory,
  });

  factory RestaurantMenuInfo.fromJson(Map<String, dynamic> json) =>
      RestaurantMenuInfo(
        restaurantId: json['restaurant_id']?.toString() ?? '',
        restaurantName: json['restaurant_name'] ?? '',
        cuisineType: (json['cuisine_type'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        priceCategory: json['price_category'],
      );
}
