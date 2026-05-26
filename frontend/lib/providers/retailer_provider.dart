import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/api_service.dart';
import '../models/area_model.dart';
import '../models/restaurant_model.dart';
import '../models/upload_models.dart';
import '../models/create_models.dart';

enum RetailerState { idle, loading, success, error }

/// Holds the state for the Restaurant Owner / Retailer portal.
class RetailerProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  RetailerState _state = RetailerState.idle;
  RetailerState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // The restaurant this owner manages (set after setup)
  RestaurantModel? _myRestaurant;
  RestaurantModel? get myRestaurant => _myRestaurant;

  // Areas fetched from backend (for the dropdown)
  List<AreaModel> _areas = [];
  List<AreaModel> get areas => _areas;

  // Upload tracking
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  UploadStatus? _lastUploadStatus;
  UploadStatus? get lastUploadStatus => _lastUploadStatus;

  List<UploadHistoryItem> _uploadHistory = [];
  List<UploadHistoryItem> get uploadHistory => List.unmodifiable(_uploadHistory);

  // ── Auth ─────────────────────────────────────────────────────────────────

  /// Simple credential-based login for restaurant owners.
  /// A real backend would validate against a `retailers` table.
  Future<bool> login(String email, String password) async {
    _setState(RetailerState.loading);
    _errorMessage = null;

    // Simulate a short network call
    await Future.delayed(const Duration(milliseconds: 800));

    // For now, accept any non-empty credentials — backend auth comes later
    if (email.trim().isNotEmpty && password.trim().isNotEmpty) {
      _isLoggedIn = true;
      _setState(RetailerState.success);
      return true;
    }

    _errorMessage = 'Invalid credentials. Please try again.';
    _setState(RetailerState.error);
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    _myRestaurant = null;
    _uploadHistory.clear();
    _setState(RetailerState.idle);
  }

  // ── Setup ────────────────────────────────────────────────────────────────

  /// Fetch areas from the backend (for the area dropdown).
  Future<void> fetchAreas() async {
    if (_areas.isNotEmpty) return; // already loaded
    _setState(RetailerState.loading);
    try {
      _areas = await _api.getAreas();
      _setState(RetailerState.success);
    } catch (_) {
      _setState(RetailerState.idle);
    }
  }

  /// Create a new restaurant profile for this owner.
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
      final req = CreateRestaurantRequest(
        restaurantName: name,
        areaId: areaId,
        priceCategory: priceCategory,
        cuisineType: cuisines,
        address: address,
        phone: phone,
      );
      _myRestaurant = await _api.createRestaurant(req);
      _setState(RetailerState.success);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(RetailerState.error);
      return false;
    } catch (_) {
      _errorMessage = 'Failed to create restaurant. Try again.';
      _setState(RetailerState.error);
      return false;
    }
  }

  // ── Menu Upload ───────────────────────────────────────────────────────────

  Future<bool> uploadMenu(File imageFile) async {
    final rest = _myRestaurant;
    if (rest == null) return false;

    // Find the area for this restaurant
    final area = _areas.firstWhere(
      (a) => a.areaId == rest.areaId,
      orElse: () => const AreaModel(
          areaId: '', areaName: 'Unknown', city: 'Unknown'),
    );

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.uploadMenu(
        imageFile: imageFile,
        areaName: area.areaName,
        city: area.city,
        restaurantName: rest.restaurantName,
      );

      _isUploading = false;
      _isProcessing = true;
      notifyListeners();

      await _pollStatus(result.uploadId);
      return true;
    } on ApiException catch (e) {
      _isUploading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _isUploading = false;
      _errorMessage = 'Upload failed. Check your connection.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _pollStatus(String uploadId) async {
    try {
      final st = await _api.getUploadStatus(uploadId);
      _lastUploadStatus = st;
      notifyListeners();

      if (st.isCompleted) {
        _isProcessing = false;
        _uploadHistory.insert(0, UploadHistoryItem(
          uploadId: uploadId,
          timestamp: DateTime.now(),
          itemsExtracted: st.itemsCount ?? 0,
          status: 'Completed',
        ));
        notifyListeners();
      } else if (st.isFailed) {
        _isProcessing = false;
        _errorMessage = st.errorMessage ?? 'OCR Processing failed.';
        _uploadHistory.insert(0, UploadHistoryItem(
          uploadId: uploadId,
          timestamp: DateTime.now(),
          itemsExtracted: 0,
          status: 'Failed',
        ));
        notifyListeners();
      } else {
        await Future.delayed(const Duration(seconds: 2));
        await _pollStatus(uploadId);
      }
    } catch (_) {
      _isProcessing = false;
      _errorMessage = 'Connection lost during processing.';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Allow the owner to re-register (clears current restaurant profile).
  void resetRestaurant() {
    _myRestaurant = null;
    _lastUploadStatus = null;
    _errorMessage = null;
    _setState(RetailerState.idle);
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  void _setState(RetailerState s) {
    _state = s;
    notifyListeners();
  }
}

/// Publicly accessible upload history record.
class UploadHistoryItem {
  final String uploadId;
  final DateTime timestamp;
  final int itemsExtracted;
  final String status;

  const UploadHistoryItem({
    required this.uploadId,
    required this.timestamp,
    required this.itemsExtracted,
    required this.status,
  });
}
