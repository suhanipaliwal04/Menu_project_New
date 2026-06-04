import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<RestaurantModel> _favorites = [];

  List<RestaurantModel> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String restaurantId) {
    return _favorites.any((r) => r.restaurantId == restaurantId);
  }

  void toggleFavorite(RestaurantModel restaurant) {
    final idx = _favorites.indexWhere((r) => r.restaurantId == restaurant.restaurantId);
    if (idx >= 0) {
      _favorites.removeAt(idx);
    } else {
      _favorites.add(restaurant);
    }
    notifyListeners();
  }
}
