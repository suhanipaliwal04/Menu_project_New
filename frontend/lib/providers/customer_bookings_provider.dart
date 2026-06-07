import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_service.dart';

class CustomerBookingsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  List<dynamic> _bookings = [];
  List<dynamic> _orders = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollTimer;

  CustomerBookingsProvider() {
    startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadBookings(isPolling: true);
    });
  }

  List<dynamic> get bookings => _bookings;
  List<dynamic> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingCount {
    int count = 0;
    for (var b in _bookings) {
      if (b['status'] == 'PENDING') count++;
    }
    for (var o in _orders) {
      if (o['status'] == 'PENDING') count++;
    }
    return count;
  }

  /// Loads locally stored booking IDs and fetches their details from backend
  Future<void> loadBookings({bool isPolling = false}) async {
    if (!isPolling) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final idsString = await _storage.read(key: 'customer_booking_ids');
      if (idsString == null || idsString.isEmpty) {
        _bookings = [];
      } else {
        final List<String> bookingIds = List<String>.from(jsonDecode(idsString));
        if (bookingIds.isEmpty) {
          _bookings = [];
        } else {
          _bookings = await _apiService.getCustomerBookings(bookingIds);
        }
      }

      final orderIdsString = await _storage.read(key: 'customer_order_ids');
      if (orderIdsString == null || orderIdsString.isEmpty) {
        _orders = [];
      } else {
        final List<String> orderIds = List<String>.from(jsonDecode(orderIdsString));
        if (orderIds.isEmpty) {
          _orders = [];
        } else {
          _orders = await _apiService.getCustomerOrders(orderIds);
        }
      }
      
      // Sort in descending order (newest first)
      _bookings.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      _orders.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      
    } catch (e) {
      _error = 'Failed to load bookings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new booking ID to local storage and refreshes
  Future<void> addBookingId(String bookingId) async {
    try {
      final idsString = await _storage.read(key: 'customer_booking_ids');
      List<String> bookingIds = [];
      if (idsString != null && idsString.isNotEmpty) {
        bookingIds = List<String>.from(jsonDecode(idsString));
      }
      
      if (!bookingIds.contains(bookingId)) {
        bookingIds.add(bookingId);
        await _storage.write(key: 'customer_booking_ids', value: jsonEncode(bookingIds));
        await loadBookings();
      }
    } catch (e) {
      _error = 'Failed to save booking ID: $e';
      notifyListeners();
    }
  }

  /// Removes a booking ID from local storage and refreshes
  Future<void> removeBookingId(String bookingId) async {
    try {
      final idsString = await _storage.read(key: 'customer_booking_ids');
      if (idsString == null || idsString.isEmpty) return;

      List<String> bookingIds = List<String>.from(jsonDecode(idsString));
      if (bookingIds.contains(bookingId)) {
        bookingIds.remove(bookingId);
        await _storage.write(key: 'customer_booking_ids', value: jsonEncode(bookingIds));
        await loadBookings();
      }
    } catch (e) {
      _error = 'Failed to remove booking ID: $e';
      notifyListeners();
    }
  }

  /// Adds a new order ID to local storage and refreshes
  Future<void> addOrderId(String orderId) async {
    try {
      final idsString = await _storage.read(key: 'customer_order_ids');
      List<String> orderIds = [];
      if (idsString != null && idsString.isNotEmpty) {
        orderIds = List<String>.from(jsonDecode(idsString));
      }
      
      if (!orderIds.contains(orderId)) {
        orderIds.add(orderId);
        await _storage.write(key: 'customer_order_ids', value: jsonEncode(orderIds));
        await loadBookings();
      }
    } catch (e) {
      _error = 'Failed to save order ID: $e';
      notifyListeners();
    }
  }

  /// Clears all local booking and order IDs
  Future<void> clearAll() async {
    try {
      await _storage.delete(key: 'customer_booking_ids');
      await _storage.delete(key: 'customer_order_ids');
      _bookings.clear();
      _orders.clear();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear records: $e';
      notifyListeners();
    }
  }
}
