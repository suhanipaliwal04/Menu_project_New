class RestaurantModel {
  final String restaurantId;
  final String areaId;
  final String restaurantName;
  final List<String>? cuisineType;
  final String? priceCategory;
  final String? address;
  final String? phone;
  final bool isActive;
  final bool hasDineIn;
  final bool hasTakeaway;
  final bool isOpenManually;
  final String? openingTime;
  final String? closingTime;
  final double averageRating;
  final int totalReviews;

  const RestaurantModel({
    required this.restaurantId,
    required this.areaId,
    required this.restaurantName,
    this.cuisineType,
    this.priceCategory,
    this.address,
    this.phone,
    this.isActive = true,
    this.hasDineIn = true,
    this.hasTakeaway = true,
    this.isOpenManually = true,
    this.openingTime,
    this.closingTime,
    this.averageRating = 4.8,
    this.totalReviews = 0,
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
        hasDineIn: json['has_dine_in'] ?? true,
        hasTakeaway: json['has_takeaway'] ?? true,
        isOpenManually: json['is_open_manually'] ?? true,
        openingTime: json['opening_time'],
        closingTime: json['closing_time'],
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 4.8,
        totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      );

  String get cuisineDisplay =>
      cuisineType?.join(', ') ?? 'Various Cuisines';

  String get displayLocation {
    if (address != null && address!.isNotEmpty) return address!;
    if (areaId.isNotEmpty) return areaId;
    return 'Unknown Location';
  }

  String get priceCategoryDisplay {
    switch (priceCategory) {
      case 'budget': return '₹ Budget';
      case 'mid-range': return '₹₹ Mid-Range';
      case 'premium': return '₹₹₹ Premium';
      default: return '';
    }
  }
}
