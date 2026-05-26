import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/area_model.dart';
import '../models/restaurant_model.dart';
import '../models/create_models.dart';

enum AdminState { idle, loading, success, error }

class AdminProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  AdminState _state = AdminState.idle;
  AdminState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AreaModel> _areas = [];
  List<AreaModel> get areas => _areas;

  List<RestaurantModel> _restaurants = [];
  List<RestaurantModel> get restaurants => _restaurants;

  // Track login state simply
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // Fake auth for now
  Future<bool> login(String username, String password) async {
    _setState(AdminState.loading);
    _errorMessage = null;

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (username == 'admin' && password == 'admin123') {
      _isAuthenticated = true;
      _setState(AdminState.success);
      return true;
    } else {
      _isAuthenticated = false;
      _errorMessage = 'Invalid username or password';
      _setState(AdminState.error);
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> fetchAreas() async {
    _setState(AdminState.loading);
    _errorMessage = null;
    try {
      _areas = await _apiService.getAreas();
      _setState(AdminState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(AdminState.error);
    } catch (e) {
      _errorMessage = 'Failed to load areas';
      _setState(AdminState.error);
    }
  }

  Future<void> fetchRestaurants() async {
    _setState(AdminState.loading);
    _errorMessage = null;
    try {
      _restaurants = await _apiService.getRestaurants();
      _setState(AdminState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(AdminState.error);
    } catch (e) {
      _errorMessage = 'Failed to load restaurants';
      _setState(AdminState.error);
    }
  }

  Future<bool> createArea(String areaName, String city, {String? pincode, String? state}) async {
    _setState(AdminState.loading);
    try {
      final req = CreateAreaRequest(
        areaName: areaName,
        city: city,
        pincode: pincode,
        state: state,
      );
      final newArea = await _apiService.createArea(req);
      _areas.add(newArea);
      _setState(AdminState.success);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(AdminState.error);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create area';
      _setState(AdminState.error);
      return false;
    }
  }

  Future<bool> createRestaurant(String name, String areaId, String priceCategory, {List<String>? cuisines, String? address, String? phone}) async {
    _setState(AdminState.loading);
    try {
      final req = CreateRestaurantRequest(
        restaurantName: name,
        areaId: areaId,
        priceCategory: priceCategory,
        cuisineType: cuisines,
        address: address,
        phone: phone,
      );
      final newRest = await _apiService.createRestaurant(req);
      _restaurants.add(newRest);
      _setState(AdminState.success);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(AdminState.error);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create restaurant';
      _setState(AdminState.error);
      return false;
    }
  }

  void _setState(AdminState s) {
    _state = s;
    notifyListeners();
  }
}
