import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/area_model.dart';
import '../models/menu_model.dart';
import '../models/restaurant_model.dart';

enum BrowseState { idle, loading, success, error }

class BrowseProvider extends ChangeNotifier {
  // Areas
  BrowseState _areasState = BrowseState.idle;
  List<AreaModel> _areas = [];

  // All restaurants (for home screen popular section)
  BrowseState _restaurantsState = BrowseState.idle;
  List<RestaurantModel> _restaurants = [];

  // Restaurants in selected area
  BrowseState _areaRestaurantsState = BrowseState.idle;
  List<RestaurantBrief> _areaRestaurants = [];
  AreaInfo? _selectedArea;

  // Restaurant menu
  BrowseState _menuState = BrowseState.idle;
  RestaurantMenuResponse? _restaurantMenu;

  // Filters
  final List<String> _selectedFilters = [];
  bool _isVegOnly = false;

  String? _errorMessage;

  // ── Getters ──────────────────────────────────────────────────────────────────

  BrowseState get areasState => _areasState;
  List<AreaModel> get areas => _areas;

  BrowseState get restaurantsState => _restaurantsState;
  List<RestaurantModel> get restaurants => _restaurants;

  BrowseState get areaRestaurantsState => _areaRestaurantsState;
  List<RestaurantBrief> get areaRestaurants => _areaRestaurants;
  AreaInfo? get selectedArea => _selectedArea;

  BrowseState get menuState => _menuState;
  RestaurantMenuResponse? get restaurantMenu => _restaurantMenu;
  List<String> get selectedFilters => _selectedFilters;
  bool get isVegOnly => _isVegOnly;

  String? get errorMessage => _errorMessage;

  // ── Actions ───────────────────────────────────────────────────────────────────

  Future<void> loadAreas({String? city}) async {
    _areasState = BrowseState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _areas = await ApiService().getAreas(city: city);
      _areasState = BrowseState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _areasState = BrowseState.error;
    } catch (e) {
      _errorMessage = 'Could not load areas. Is the backend running?';
      _areasState = BrowseState.error;
    }

    notifyListeners();
  }

  /// Fetches all restaurants — used by home screen "Popular Near You" section.
  Future<void> loadRestaurants({String? city, String? cuisine}) async {
    if (_restaurantsState == BrowseState.loading) return;
    _restaurantsState = BrowseState.loading;
    notifyListeners();

    try {
      _restaurants = await ApiService().getRestaurants(
        city: city,
        cuisine: cuisine,
      );
      _restaurantsState = BrowseState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _restaurantsState = BrowseState.error;
    } catch (e) {
      _restaurantsState = BrowseState.error;
    }

    notifyListeners();
  }

  Future<void> loadAreaRestaurants(String areaId) async {
    _areaRestaurantsState = BrowseState.loading;
    _areaRestaurants = [];
    notifyListeners();

    try {
      final result = await ApiService().getAreaRestaurants(areaId);
      _selectedArea = result.area;
      _areaRestaurants = result.restaurants;
      _areaRestaurantsState = BrowseState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _areaRestaurantsState = BrowseState.error;
    } catch (e) {
      _errorMessage = 'Could not load restaurants.';
      _areaRestaurantsState = BrowseState.error;
    }

    notifyListeners();
  }

  Future<void> loadRestaurantMenu(String restaurantId) async {
    _menuState = BrowseState.loading;
    _restaurantMenu = null;
    notifyListeners();

    try {
      _restaurantMenu = await ApiService().getRestaurantMenu(restaurantId);
      _menuState = BrowseState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _menuState = BrowseState.error;
    } catch (e) {
      _errorMessage = 'Could not load menu.';
      _menuState = BrowseState.error;
    }

    notifyListeners();
  }

  void clearMenu() {
    _restaurantMenu = null;
    _menuState = BrowseState.idle;
    notifyListeners();
  }

  void clearSelectedArea() {
    _selectedArea = null;
    _areaRestaurants = [];
    _areaRestaurantsState = BrowseState.idle;
    notifyListeners();
  }

  void toggleFilter(String filter) {
    if (_selectedFilters.contains(filter)) {
      _selectedFilters.remove(filter);
    } else {
      _selectedFilters.add(filter);
    }
    notifyListeners();
  }

  void setVegOnly(bool val) {
    _isVegOnly = val;
    notifyListeners();
  }
}
