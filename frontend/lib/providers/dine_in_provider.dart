import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../core/api_service.dart';

enum DineInState { idle, checking, confirmed, error }

/// Manages all dine-in booking state for the Voice AI agent.
class DineInProvider extends ChangeNotifier {
  DineInState _state = DineInState.idle;
  DineAvailabilityResponse? _lastAvailability;
  DineBookingConfirmation? _confirmedBooking;

  // Context kept between turns
  String _restaurantId   = '';
  String _restaurantName = '';

  // ── Getters ────────────────────────────────────────────────────────────────
  DineInState get state                          => _state;
  DineAvailabilityResponse? get lastAvailability => _lastAvailability;
  DineBookingConfirmation? get confirmedBooking  => _confirmedBooking;
  bool get isChecking                            => _state == DineInState.checking;
  bool get isConfirmed                           => _state == DineInState.confirmed;

  // ── Set restaurant context ─────────────────────────────────────────────────
  void setRestaurant(String id, String name) {
    _restaurantId   = id;
    _restaurantName = name;
  }

  // ── Check availability (via Backend API) ─────────────────────────
  Future<DineAvailabilityResponse> checkAvailability({
    required String timeSlot,
    required int partySize,
    String? restaurantId,
    String? restaurantName,
  }) async {
    final name = (restaurantName?.isNotEmpty == true)
        ? restaurantName!
        : (_restaurantName.isNotEmpty ? _restaurantName : 'this restaurant');
    final id = (restaurantId?.isNotEmpty == true) ? restaurantId! : _restaurantId;

    _state = DineInState.checking;
    notifyListeners();

    try {
      final result = await ApiService().checkDineAvailability(
        restaurantId: id,
        restaurantName: name,
        timeSlot: timeSlot,
        partySize: partySize,
      );

      _lastAvailability = result;
      _state = DineInState.idle;
      notifyListeners();
      return result;
    } catch (e) {
      _state = DineInState.error;
      notifyListeners();
      
      // Fallback response for network errors
      return DineAvailabilityResponse(
        available: false,
        confirmedSlot: null,
        reason: 'error',
        alternativeSlots: [],
        nearbyRestaurants: [],
        aiMessage: "I'm having trouble connecting to the restaurant's booking system. Please check your internet connection and try again.",
      );
    }
  }

  // ── Confirm booking (via Backend API) ──────────────────────────────────────────
  Future<DineBookingConfirmation> confirmBooking({
    required String timeSlot,
    required int partySize,
    String? restaurantId,
    String? restaurantName,
  }) async {
    final name = (restaurantName?.isNotEmpty == true)
        ? restaurantName!
        : (_restaurantName.isNotEmpty ? _restaurantName : 'the restaurant');
    final id = (restaurantId?.isNotEmpty == true) ? restaurantId! : _restaurantId;

    _state = DineInState.checking;
    notifyListeners();

    try {
      final booking = await ApiService().confirmDineBooking(
        restaurantId: id,
        restaurantName: name,
        timeSlot: timeSlot,
        partySize: partySize,
      );

      _confirmedBooking = booking;
      _state = DineInState.confirmed;
      notifyListeners();
      return booking;
    } catch (e) {
      _state = DineInState.error;
      notifyListeners();
      rethrow;
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────
  void reset() {
    _state            = DineInState.idle;
    _lastAvailability = null;
    _confirmedBooking = null;
    notifyListeners();
  }
}
