import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/area_model.dart';
import '../models/restaurant_model.dart';
import '../models/create_models.dart';

enum AdminState { idle, loading, success, error }

// ── Dashboard Stats Model ─────────────────────────────────────────────────────

class AdminDashboardStats {
  final String restaurantId;
  final String restaurantName;
  final String areaName;
  final String city;
  final bool isActive;
  final int totalSections;
  final int totalItems;
  final int totalUploads;
  final double? avgPrice;
  final int vegItems;
  final int nonVegItems;

  const AdminDashboardStats({
    required this.restaurantId,
    required this.restaurantName,
    required this.areaName,
    required this.city,
    required this.isActive,
    required this.totalSections,
    required this.totalItems,
    required this.totalUploads,
    this.avgPrice,
    required this.vegItems,
    required this.nonVegItems,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> j) =>
      AdminDashboardStats(
        restaurantId: j['restaurant_id']?.toString() ?? '',
        restaurantName: j['restaurant_name'] ?? '',
        areaName: j['area_name'] ?? '',
        city: j['city'] ?? '',
        isActive: j['is_active'] as bool? ?? false,
        totalSections: j['total_sections'] as int? ?? 0,
        totalItems: j['total_items'] as int? ?? 0,
        totalUploads: j['total_uploads'] as int? ?? 0,
        avgPrice: (j['avg_price'] as num?)?.toDouble(),
        vegItems: j['veg_items'] as int? ?? 0,
        nonVegItems: j['non_veg_items'] as int? ?? 0,
      );
}

// ── Menu Item Model ───────────────────────────────────────────────────────────

class AdminMenuItem {
  final String itemId;
  String itemName;
  final String sectionName;
  double price;
  bool isVeg;
  bool isAvailable;
  final String? description;
  final int? calories;
  final int? healthScore;
  final String? healthLabel;

  AdminMenuItem({
    required this.itemId,
    required this.itemName,
    required this.sectionName,
    required this.price,
    required this.isVeg,
    required this.isAvailable,
    this.description,
    this.calories,
    this.healthScore,
    this.healthLabel,
  });

  factory AdminMenuItem.fromJson(Map<String, dynamic> j) => AdminMenuItem(
        itemId: j['item_id']?.toString() ?? '',
        itemName: j['item_name'] ?? '',
        sectionName: j['section_name'] ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        isVeg: j['is_veg'] as bool? ?? true,
        isAvailable: j['is_available'] as bool? ?? true,
        description: j['description']?.toString(),
        calories: j['calories'] as int?,
        healthScore: j['health_score'] as int?,
        healthLabel: j['health_label']?.toString(),
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

class AdminProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  AdminState _state = AdminState.idle;
  AdminState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _adminEmail;
  String? get adminEmail => _adminEmail;

  List<AreaModel> _areas = [];
  List<AreaModel> get areas => _areas;

  List<RestaurantModel> _restaurants = [];
  List<RestaurantModel> get restaurants => _restaurants;

  // Selected restaurant context for dashboard
  RestaurantModel? _selectedRestaurant;
  RestaurantModel? get selectedRestaurant => _selectedRestaurant;

  // Dashboard stats
  AdminDashboardStats? _dashboardStats;
  AdminDashboardStats? get dashboardStats => _dashboardStats;

  // Menu items
  List<AdminMenuItem> _menuItems = [];
  List<AdminMenuItem> get menuItems => _menuItems;

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Real Supabase JWT login via backend /auth/admin-login
  Future<bool> login(String email, String password) async {
    _setState(AdminState.loading);
    _errorMessage = null;

    try {
      final data = await _api.login(email, password, 'SYSTEM_ADMIN');
      final token = data['access_token'] as String?;
      if (token == null || token.isEmpty) {
        _errorMessage = 'No token received from server';
        _setState(AdminState.error);
        return false;
      }
      // Store token in singleton so all auth'd calls pick it up
      _api.setAuthToken(token);
      _adminEmail = data['email']?.toString() ?? email;
      _isAuthenticated = true;
      _setState(AdminState.success);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(AdminState.error);
      return false;
    } catch (e) {
      _errorMessage = 'Login failed. Check your credentials.';
      _setState(AdminState.error);
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    _adminEmail = null;
    _dashboardStats = null;
    _menuItems = [];
    _selectedRestaurant = null;
    _api.setAuthToken(null);
    notifyListeners();
  }

  // ── Areas ─────────────────────────────────────────────────────────────────

  Future<void> fetchAreas() async {
    _setState(AdminState.loading);
    _errorMessage = null;
    try {
      _areas = await _api.getAreas();
      _setState(AdminState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(AdminState.error);
    } catch (e) {
      _errorMessage = 'Failed to load areas';
      _setState(AdminState.error);
    }
  }

  Future<bool> createArea(String areaName, String city,
      {String? pincode, String? state}) async {
    _setState(AdminState.loading);
    try {
      final req = CreateAreaRequest(
          areaName: areaName, city: city, pincode: pincode, state: state);
      final newArea = await _api.createArea(req);
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

  // ── Restaurants ───────────────────────────────────────────────────────────

  Future<void> fetchRestaurants() async {
    _setState(AdminState.loading);
    _errorMessage = null;
    try {
      _restaurants = await _api.getRestaurants();
      _setState(AdminState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(AdminState.error);
    } catch (e) {
      _errorMessage = 'Failed to load restaurants';
      _setState(AdminState.error);
    }
  }

  Future<bool> createRestaurant(
      String name, String areaId, String priceCategory,
      {List<String>? cuisines, String? address, String? phone}) async {
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
      final newRest = await _api.createRestaurant(req);
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

  void selectRestaurant(RestaurantModel restaurant) {
    _selectedRestaurant = restaurant;
    _dashboardStats = null;
    _menuItems = [];
    notifyListeners();
  }

  // ── Dashboard Stats ───────────────────────────────────────────────────────

  Future<void> fetchDashboardStats() async {
    if (_selectedRestaurant == null) return;
    _setState(AdminState.loading);
    _errorMessage = null;
    try {
      final data =
          await _api.getAdminDashboard(_selectedRestaurant!.restaurantId);
      _dashboardStats = AdminDashboardStats.fromJson(data);
      _setState(AdminState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(AdminState.error);
    } catch (e) {
      _errorMessage = 'Failed to load dashboard stats';
      _setState(AdminState.error);
    }
  }

  // ── Menu Items ────────────────────────────────────────────────────────────

  Future<void> fetchMenuItems() async {
    if (_selectedRestaurant == null) return;
    _setState(AdminState.loading);
    _errorMessage = null;
    try {
      final data =
          await _api.getAdminMenuItems(_selectedRestaurant!.restaurantId);
      _menuItems = data
          .map((e) => AdminMenuItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _setState(AdminState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(AdminState.error);
    } catch (e) {
      _errorMessage = 'Failed to load menu items';
      _setState(AdminState.error);
    }
  }

  Future<bool> updateMenuItem(
      String itemId, Map<String, dynamic> updates) async {
    if (_selectedRestaurant == null) return false;
    _errorMessage = null;
    try {
      final data = await _api.updateAdminMenuItem(
          _selectedRestaurant!.restaurantId, itemId, updates);
      // Update in local list
      final idx = _menuItems.indexWhere((m) => m.itemId == itemId);
      if (idx != -1) {
        _menuItems[idx] = AdminMenuItem.fromJson(data);
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update item';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMenuItem(String itemId) async {
    if (_selectedRestaurant == null) return false;
    _errorMessage = null;
    try {
      await _api.deleteAdminMenuItem(_selectedRestaurant!.restaurantId, itemId);
      _menuItems.removeWhere((m) => m.itemId == itemId);
      // Decrement stats count
      if (_dashboardStats != null) {
        _dashboardStats = AdminDashboardStats(
          restaurantId: _dashboardStats!.restaurantId,
          restaurantName: _dashboardStats!.restaurantName,
          areaName: _dashboardStats!.areaName,
          city: _dashboardStats!.city,
          isActive: _dashboardStats!.isActive,
          totalSections: _dashboardStats!.totalSections,
          totalItems: _dashboardStats!.totalItems - 1,
          totalUploads: _dashboardStats!.totalUploads,
          avgPrice: _dashboardStats!.avgPrice,
          vegItems: _dashboardStats!.vegItems,
          nonVegItems: _dashboardStats!.nonVegItems,
        );
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete item';
      notifyListeners();
      return false;
    }
  }

  void _setState(AdminState s) {
    _state = s;
    notifyListeners();
  }
}
