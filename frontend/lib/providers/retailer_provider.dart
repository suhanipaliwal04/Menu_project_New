import 'dart:io';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_service.dart';
import '../models/area_model.dart';
import '../models/restaurant_model.dart';
import '../models/admin_models.dart';
import '../models/create_models.dart';

enum RetailerState { idle, loading, success, error }

/// Holds the state for the Restaurant Owner / Retailer portal.
/// Uses flutter_secure_storage to persist JWT across app restarts.
class RetailerProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'retailer_jwt';
  static const _userIdKey = 'retailer_user_id';
  static const _restaurantIdKey = 'retailer_restaurant_id';

  // ── State ──────────────────────────────────────────────────────────────────
  RetailerState _state = RetailerState.idle;
  RetailerState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _userId;
  String? get userId => _userId;

  // Restaurant this owner manages
  RestaurantModel? _myRestaurant;
  RestaurantModel? get myRestaurant => _myRestaurant;

  // Areas for dropdowns
  List<AreaModel> _areas = [];
  List<AreaModel> get areas => _areas;

  // Dashboard stats
  DashboardStats? _dashboardStats;
  DashboardStats? get dashboardStats => _dashboardStats;

  // Menu items
  List<AdminMenuItem> _menuItems = [];
  List<AdminMenuItem> get menuItems => List.unmodifiable(_menuItems);

  // Sections (for filter dropdown)
  List<MenuSectionInfo> _sections = [];
  List<MenuSectionInfo> get sections => List.unmodifiable(_sections);

  // Bookings
  List<BookingModel> _bookings = [];
  List<BookingModel> get bookings => List.unmodifiable(_bookings);

  // Takeaway Orders
  List<OrderModel> _takeawayOrders = [];
  List<OrderModel> get takeawayOrders => List.unmodifiable(_takeawayOrders);

  // Active filters
  String? _sectionFilter;
  String? get sectionFilter => _sectionFilter;
  bool? _vegFilter;
  bool? get vegFilter => _vegFilter;

  // Upload state
  bool _isUploading = false;
  bool get isUploading => _isUploading;
  String? _uploadMode = 'replace'; // 'replace' | 'append'
  String? get uploadMode => _uploadMode;
  String? _extractionMethod = 'paddleocr'; // 'paddleocr' | 'vision'
  String? get extractionMethod => _extractionMethod;
  Map<String, dynamic>? _lastUploadResult;
  Map<String, dynamic>? get lastUploadResult => _lastUploadResult;

  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_myRestaurant != null && _isLoggedIn) {
        fetchBookings();
        fetchTakeawayOrders();
        fetchDashboard();
      }
    });
  }

  // ── App Init — restore session from secure storage ─────────────────────────

  /// Call this once from main.dart or RetailerLoginScreen.initState()
  /// to restore a saved JWT session without re-logging in.
  Future<void> init() async {
    final token = await _storage.read(key: _tokenKey);
    final userId = await _storage.read(key: _userIdKey);
    final restaurantId = await _storage.read(key: _restaurantIdKey);

    if (token == null || userId == null) return;

    _api.setAuthToken(token);
    _userId = userId;
    _isLoggedIn = true;
    notifyListeners();

    // Re-fetch restaurant data in background
    if (restaurantId != null) {
      try {
        final r = await _api.getRestaurant(restaurantId);
        _myRestaurant = r;
        notifyListeners();
      } catch (_) {
        // Token may be expired — clear it
        await _clearSession();
      }
    } else {
      // Token exists but no restaurant yet — try /auth/me
      await fetchMe();
    }
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _setState(RetailerState.loading);
    _errorMessage = null;

    try {
      final data = await _api.login(email, password, 'RESTAURANT_ADMIN');
      final token = data['access_token'] as String;
      final userId = data['user_id'] as String;

      // Store JWT securely
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userIdKey, value: userId);

      _api.setAuthToken(token);
      _userId = userId;
      _isLoggedIn = true;

      // Fetch user's restaurant (if any)
      await fetchMe();

      _setState(RetailerState.success);
      _startPolling();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(RetailerState.error);
      return false;
    } catch (e) {
      _errorMessage = 'Login failed. Check your connection.';
      _setState(RetailerState.error);
      return false;
    }
  }

  Future<void> logout() async {
    await _clearSession();
    _setState(RetailerState.idle);
  }

  Future<void> fetchMe() async {
    try {
      final me = await _api.getMe();
      final restaurantId = me['restaurant_id'] as String?;
      if (restaurantId != null) {
        await _storage.write(key: _restaurantIdKey, value: restaurantId);
        _myRestaurant = await _api.getRestaurant(restaurantId);
        _startPolling();
        notifyListeners();
      }
    } on ApiException catch (e) {
      // Surface auth errors so we can debug them
      _errorMessage = 'Auth check failed (${e.statusCode}): ${e.message}';
      notifyListeners();
    } catch (e) {
      // Surface all errors for debugging
      _errorMessage = 'Session error: $e';
      notifyListeners();
    }
  }

  Future<void> _clearSession() async {
    _pollTimer?.cancel();
    await _storage.deleteAll();
    _api.setAuthToken(null);
    _isLoggedIn = false;
    _userId = null;
    _myRestaurant = null;
    _dashboardStats = null;
    _menuItems = [];
    _sections = [];
    _bookings = [];
    _takeawayOrders = [];
    _areas = [];
  }

  // ── Setup — create restaurant ──────────────────────────────────────────────

  Future<void> fetchAreas({String? city}) async {
    try {
      _areas = await _api.getAreas(city: city);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> setupRestaurant({
    required String name,
    required String areaId,
    required String priceCategory,
    List<String>? cuisines,
    String? address,
    String? phone,
  }) async {
    _setState(RetailerState.loading);
    _errorMessage = null;
    try {
      _myRestaurant = await _api.createRestaurant(
        CreateRestaurantRequest(
          restaurantName: name,
          areaId: areaId,
          priceCategory: priceCategory,
          cuisineType: cuisines,
          address: address,
          phone: phone,
        ),
      );
      if (_myRestaurant != null) {
        await _storage.write(
            key: _restaurantIdKey, value: _myRestaurant!.restaurantId);
      }
      _setState(RetailerState.success);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(RetailerState.error);
      return false;
    } catch (_) {
      _errorMessage = 'Failed to create restaurant.';
      _setState(RetailerState.error);
      return false;
    }
  }

  // ── Dashboard Stats ────────────────────────────────────────────────────────

  Future<void> fetchDashboard() async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return;
    try {
      final data = await _api.getAdminDashboard(id);
      _dashboardStats = DashboardStats.fromJson(data);
      notifyListeners();
    } catch (e) {
      debugPrint('fetchDashboard error: $e');
    }
  }

  // ── Menu Items CRUD ────────────────────────────────────────────────────────

  Future<void> fetchMenuItems({String? sectionName, bool? isVeg}) async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return;
    try {
      final raw = await _api.getAdminMenuItems(
        id,
        sectionName: sectionName,
        isVeg: isVeg,
      );
      _menuItems = raw
          .map((e) => AdminMenuItem.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchMenuItems error: $e');
    }
  }

  Future<void> fetchSections() async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return;
    try {
      final raw = await _api.getAdminSections(id);
      _sections = raw
          .map((e) => MenuSectionInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchSections error: $e');
    }
  }

  void setFilter({String? section, bool? isVeg, bool clearAll = false}) {
    if (clearAll) {
      _sectionFilter = null;
      _vegFilter = null;
    } else {
      _sectionFilter = section;
      _vegFilter = isVeg;
    }
    fetchMenuItems(sectionName: _sectionFilter, isVeg: _vegFilter);
  }

  Future<bool> addMenuItem({
    required String itemName,
    required String sectionName,
    required double price,
    required bool isVeg,
    String? description,
    int? calories,
  }) async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return false;
    try {
      final data = await _api.addAdminMenuItem(id, {
        'item_name': itemName,
        'section_name': sectionName,
        'price': price,
        'is_veg': isVeg,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (calories != null) 'calories': calories,
      });
      // Prepend to local list
      _menuItems.insert(0, AdminMenuItem.fromJson(data));
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to add item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMenuItem(
      String itemId, Map<String, dynamic> updates) async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return false;
    try {
      final data = await _api.updateAdminMenuItem(id, itemId, updates);
      final updated = AdminMenuItem.fromJson(data);
      final idx = _menuItems.indexWhere((i) => i.itemId == itemId);
      if (idx != -1) _menuItems[idx] = updated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Update failed.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMenuItem(String itemId) async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return false;
    try {
      await _api.deleteAdminMenuItem(id, itemId);
      _menuItems.removeWhere((i) => i.itemId == itemId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Delete failed.';
      notifyListeners();
      return false;
    }
  }

  // ── Menu Upload ────────────────────────────────────────────────────────────

  void setUploadMode(String mode) {
    _uploadMode = mode;
    notifyListeners();
  }

  void setExtractionMethod(String method) {
    _extractionMethod = method;
    notifyListeners();
  }

  Future<bool> uploadMenuImage(XFile imageFile) async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return false;

    _isUploading = true;
    _lastUploadResult = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.adminUploadMenuImage(
        imageFile: imageFile,
        restaurantId: id,
        mode: _uploadMode ?? 'replace',
        extractionMethod: _extractionMethod ?? 'paddleocr',
      );
      _lastUploadResult = result;
      _isUploading = false;

      // Add to history
      _uploadHistory.insert(
          0,
          UploadHistoryItem(
            uploadId: result['upload_id']?.toString() ?? '',
            timestamp: DateTime.now(),
            itemsExtracted: result['items_count'] as int? ?? 0,
            status: result['status'] == 'completed' ? 'Completed' : 'Failed',
            mode: _uploadMode ?? 'replace',
          ));

      // Refresh items list
      await fetchMenuItems();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isUploading = false;
      _lastUploadResult = null;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isUploading = false;
      _lastUploadResult = null;
      _errorMessage = 'Upload failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearAllMenuData() async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return false;
    try {
      await _api.clearAdminMenu(id);
      _menuItems = [];
      _sections = [];
      _dashboardStats = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to clear menu.';
      notifyListeners();
      return false;
    }
  }

  // ── Restaurant Settings ────────────────────────────────────────────────────

  Future<bool> updateRestaurant({
    String? name,
    String? phone,
    String? address,
    List<String>? cuisineType,
    String? priceCategory,
    bool? hasDineIn,
    bool? hasTakeaway,
    bool? isOpenManually,
    String? openingTime,
    String? closingTime,
  }) async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return false;

    final updates = <String, dynamic>{
      if (name != null && name.isNotEmpty) 'restaurant_name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (cuisineType != null) 'cuisine_type': cuisineType,
      if (priceCategory != null) 'price_category': priceCategory,
      if (hasDineIn != null) 'has_dine_in': hasDineIn,
      if (hasTakeaway != null) 'has_takeaway': hasTakeaway,
      if (isOpenManually != null) 'is_open_manually': isOpenManually,
      if (openingTime != null) 'opening_time': openingTime,
      if (closingTime != null) 'closing_time': closingTime,
    };

    if (updates.isEmpty) return true;

    try {
      final data = await _api.updateRestaurant(id, updates);
      _myRestaurant = RestaurantModel.fromJson(data);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to update restaurant.';
      notifyListeners();
      return false;
    }
  }

  // ── Upload History ─────────────────────────────────────────────────────────

  final List<UploadHistoryItem> _uploadHistory = [];
  List<UploadHistoryItem> get uploadHistory =>
      List.unmodifiable(_uploadHistory);

  // ── Bookings ───────────────────────────────────────────────────────────────

  Future<void> fetchBookings({String? status}) async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return;
    try {
      final raw = await _api.getAdminBookings(id, status: status);
      _bookings = raw.map((e) => BookingModel.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
    }
  }

  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      final data = await _api.updateBookingStatus(bookingId, status);
      // Update locally
      final updated = BookingModel.fromJson(data);
      final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
      if (index != -1) {
        _bookings[index] = updated;
        // Optionally refresh stats so badge updates immediately
        await fetchDashboard();
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to update booking status.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearAllBookings() async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return false;
    try {
      await _api.clearAdminBookings(id);
      _bookings = [];
      await fetchDashboard();
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Failed to clear bookings.';
      notifyListeners();
      return false;
    }
  }

  // ── Takeaway Orders ────────────────────────────────────────────────────────

  Future<void> fetchTakeawayOrders({String? status}) async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return;
    try {
      final raw = await _api.getAdminOrders(id);
      var orders = raw.map((e) => OrderModel.fromJson(e)).toList();
      if (status != null) {
        orders = orders.where((o) => o.status == status).toList();
      }
      _takeawayOrders = orders;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching takeaway orders: $e');
    }
  }

  Future<bool> updateTakeawayOrderStatus(String orderId, String status) async {
    try {
      final data = await _api.updateOrderStatus(orderId, status);
      final updated = OrderModel.fromJson(data);
      final index = _takeawayOrders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _takeawayOrders[index] = updated;
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to update order status.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearAllTakeawayOrders() async {
    final id = _myRestaurant?.restaurantId;
    if (id == null) return false;
    try {
      await _api.clearAdminOrders(id);
      _takeawayOrders = [];
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Failed to clear takeaway orders.';
      notifyListeners();
      return false;
    }
  }

  // ── Misc ───────────────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetRestaurant() {
    _myRestaurant = null;
    _dashboardStats = null;
    _menuItems = [];
    _sections = [];
    _takeawayOrders = [];
    _storage.delete(key: _restaurantIdKey);
    _setState(RetailerState.idle);
  }

  void _setState(RetailerState s) {
    _state = s;
    notifyListeners();
  }
}
