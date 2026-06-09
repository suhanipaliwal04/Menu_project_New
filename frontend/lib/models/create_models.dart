/// Request body for POST /areas/
class CreateAreaRequest {
  final String areaName;
  final String city;
  final String? pincode;
  final String? state;

  const CreateAreaRequest({
    required this.areaName,
    required this.city,
    this.pincode,
    this.state,
  });

  Map<String, dynamic> toJson() => {
        'area_name': areaName,
        'city': city,
        if (pincode != null && pincode!.isNotEmpty) 'pincode': pincode,
        if (state != null && state!.isNotEmpty) 'state': state,
      };
}

/// Request body for POST /restaurants/
class CreateRestaurantRequest {
  final String restaurantName;
  final String areaId;
  final List<String>? cuisineType;
  final String? priceCategory;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;

  const CreateRestaurantRequest({
    required this.restaurantName,
    required this.areaId,
    this.cuisineType,
    this.priceCategory,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'restaurant_name': restaurantName,
        'area_id': areaId,
        if (cuisineType != null && cuisineType!.isNotEmpty)
          'cuisine_type': cuisineType,
        if (priceCategory != null && priceCategory!.isNotEmpty)
          'price_category': priceCategory,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}
