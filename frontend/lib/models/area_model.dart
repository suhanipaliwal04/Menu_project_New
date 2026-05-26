class AreaModel {
  final String areaId;
  final String areaName;
  final String city;
  final String? pincode;
  final String? state;

  const AreaModel({
    required this.areaId,
    required this.areaName,
    required this.city,
    this.pincode,
    this.state,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) => AreaModel(
        areaId: json['area_id']?.toString() ?? '',
        areaName: json['area_name'] ?? '',
        city: json['city'] ?? '',
        pincode: json['pincode'],
        state: json['state'],
      );

  String get displayName => '$areaName, $city';
}

// Response for GET /areas/{id}/restaurants
class AreaRestaurantsResponse {
  final AreaInfo area;
  final List<RestaurantBrief> restaurants;

  const AreaRestaurantsResponse({
    required this.area,
    required this.restaurants,
  });

  factory AreaRestaurantsResponse.fromJson(Map<String, dynamic> json) =>
      AreaRestaurantsResponse(
        area: AreaInfo.fromJson(json['area'] as Map<String, dynamic>),
        restaurants: (json['restaurants'] as List<dynamic>? ?? [])
            .map((e) => RestaurantBrief.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AreaInfo {
  final String areaId;
  final String areaName;
  final String city;

  const AreaInfo({
    required this.areaId,
    required this.areaName,
    required this.city,
  });

  factory AreaInfo.fromJson(Map<String, dynamic> json) => AreaInfo(
        areaId: json['area_id']?.toString() ?? '',
        areaName: json['area_name'] ?? '',
        city: json['city'] ?? '',
      );
}

class RestaurantBrief {
  final String restaurantId;
  final String restaurantName;
  final List<String>? cuisineType;
  final String? priceCategory;

  const RestaurantBrief({
    required this.restaurantId,
    required this.restaurantName,
    this.cuisineType,
    this.priceCategory,
  });

  factory RestaurantBrief.fromJson(Map<String, dynamic> json) => RestaurantBrief(
        restaurantId: json['restaurant_id']?.toString() ?? '',
        restaurantName: json['restaurant_name'] ?? '',
        cuisineType: (json['cuisine_type'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        priceCategory: json['price_category'],
      );
}
