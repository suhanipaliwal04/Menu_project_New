class RestaurantModel {
  final String restaurantId;
  final String areaId;
  final String? areaName;
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
  final int slotDurationMins;
  final int maxDineInPerSlot;
  final int maxCapacity;
  final int takeawaySlotDurationMins;
  final double? latitude;
  final double? longitude;
  final double? distance;

  const RestaurantModel({
    required this.restaurantId,
    required this.areaId,
    this.areaName,
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
    this.slotDurationMins = 15,
    this.maxDineInPerSlot = 5,
    this.maxCapacity = 100,
    this.takeawaySlotDurationMins = 15,
    this.latitude,
    this.longitude,
    this.distance,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      RestaurantModel(
        restaurantId: json['restaurant_id']?.toString() ?? '',
        areaId: json['area_id']?.toString() ?? '',
        areaName: json['area_name']?.toString(),
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
        slotDurationMins: (json['slot_duration_mins'] as num?)?.toInt() ?? 15,
        maxDineInPerSlot: (json['max_dine_in_per_slot'] as num?)?.toInt() ?? 5,
        maxCapacity: (json['max_capacity'] as num?)?.toInt() ?? 100,
        takeawaySlotDurationMins: (json['takeaway_slot_duration_mins'] as num?)?.toInt() ?? 15,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        distance: (json['distance'] as num?)?.toDouble(),
      );

  String get cuisineDisplay =>
      cuisineType?.join(', ') ?? 'Various Cuisines';

  String get displayLocation {
    if (areaName != null && areaName!.isNotEmpty) return areaName!;
    if (address != null && address!.isNotEmpty) return address!;
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
