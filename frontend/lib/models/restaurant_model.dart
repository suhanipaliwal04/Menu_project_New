class RestaurantModel {
  final String restaurantId;
  final String areaId;
  final String restaurantName;
  final List<String>? cuisineType;
  final String? priceCategory;
  final String? address;
  final String? phone;
  final bool isActive;

  const RestaurantModel({
    required this.restaurantId,
    required this.areaId,
    required this.restaurantName,
    this.cuisineType,
    this.priceCategory,
    this.address,
    this.phone,
    this.isActive = true,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      RestaurantModel(
        restaurantId: json['restaurant_id']?.toString() ?? '',
        areaId: json['area_id']?.toString() ?? '',
        restaurantName: json['restaurant_name'] ?? '',
        cuisineType: (json['cuisine_type'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        priceCategory: json['price_category'],
        address: json['address'],
        phone: json['phone'],
        isActive: json['is_active'] ?? true,
      );

  String get cuisineDisplay =>
      cuisineType?.join(', ') ?? 'Various Cuisines';

  String get priceCategoryDisplay {
    switch (priceCategory) {
      case 'budget': return '₹ Budget';
      case 'mid-range': return '₹₹ Mid-Range';
      case 'premium': return '₹₹₹ Premium';
      default: return '';
    }
  }
}
