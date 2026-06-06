import 'dart:convert';
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

  List<dynamic> get bookings => _bookings;
  List<dynamic> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads locally stored booking IDs and fetches their details from backend
  Future<void> loadBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final idsString = await _storage.read(key: 'customer_booking_ids');
      if (idsString == null || idsString.isEmpty) {
        _bookings = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final List<String> bookingIds = List<String>.from(jsonDecode(idsString));
      
      if (bookingIds.isEmpty) {
        _bookings = [];
      } else {
        _bookings = await _apiService.getCustomerBookings(bookingIds);
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
}
