import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';

enum DineInState { idle, checking, confirmed, error }

/// Manages all dine-in booking state for the Voice AI agent.
///
/// ──────────────────────────────────────────────────────────────
/// AVAILABILITY RULES (client-side mock — no backend needed)
/// ──────────────────────────────────────────────────────────────
///
/// The rules are designed to make all 4 test cases easily triggerable:
///
/// SCENARIO 1 – Booking confirmed
///   → Party ≤ 5 AND time is NOT 7:00 PM / 8:00 PM
///   → e.g. "2 people at 7:30 PM" → ✅ confirmed
///
/// SCENARIO 2 – Time unavailable, alternatives shown
///   → Any party size AND time is exactly 7:00 PM OR 8:00 PM
///   → e.g. "2 people at 7 PM" → ❌ "7 PM is full, try 7:30 / 9:00..."
///
/// SCENARIO 3 – Seats unavailable, nearby restaurants shown
///   → Party ≥ 6 AND time is NOT 7:00 PM / 8:00 PM
///   → e.g. "6 people at 7:30 PM" → ❌ "No table for 6, try Spice Garden..."
///
/// SCENARIO 4 – Single-turn complete resolve
///   → Party ≤ 5 AND valid time → goes straight to confirm (no extra turns)
///   → e.g. "book for 2 at 9 PM" → ✅ confirmed immediately

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

  // ── Available time slots ───────────────────────────────────────────────────
  static const _allSlots = [
    '6:00 PM', '6:30 PM', '7:00 PM', '7:30 PM',
    '8:00 PM', '8:30 PM', '9:00 PM', '9:30 PM',
    '10:00 PM', '10:30 PM',
  ];

  // Slots that are "fully booked" (trigger Scenario 2)
  static const _fullyBookedSlots = ['7:00 PM', '8:00 PM'];

  // Nearby restaurants shown in Scenario 3
  static const _nearbyRestaurants = [
    NearbyRestaurant(id: 'nb-1', name: 'Spice Garden',      cuisine: 'Indian',       area: 'Sitabuldi',   rating: 4.2),
    NearbyRestaurant(id: 'nb-2', name: 'Maharaja Dhaba',    cuisine: 'North Indian', area: 'Dharampeth',  rating: 4.5),
    NearbyRestaurant(id: 'nb-3', name: 'Hotel Centre Point',cuisine: 'Continental',  area: 'Sitabuldi',   rating: 4.6),
    NearbyRestaurant(id: 'nb-4', name: 'Savji Kohinoor',    cuisine: 'Multi-cuisine',area: 'Ramdaspeth',  rating: 4.3),
    NearbyRestaurant(id: 'nb-5', name: 'Umrao Restaurant',  cuisine: 'Mughlai',      area: 'Dharampeth',  rating: 4.1),
  ];

  // ── Check availability (pure client-side, instant) ─────────────────────────
  Future<DineAvailabilityResponse> checkAvailability({
    required String timeSlot,
    required int partySize,
    String? restaurantId,
    String? restaurantName,
  }) async {
    final name = (restaurantName?.isNotEmpty == true)
        ? restaurantName!
        : (_restaurantName.isNotEmpty ? _restaurantName : 'this restaurant');

    _state = DineInState.checking;
    notifyListeners();

    // Tiny delay so the UI shows "Checking..." state before flipping
    await Future.delayed(const Duration(milliseconds: 350));

    final normalized = _normalizeSlot(timeSlot);
    DineAvailabilityResponse result;

    // Check if the user selected one of the alternative nearby restaurants
    final isNearby = _nearbyRestaurants.any((r) => r.id == restaurantId || r.name.toLowerCase() == name.toLowerCase());

    if (partySize >= 6 && !isNearby) {
      // ── SCENARIO 3: large party, no table at main restaurant ──────────────
      // We ALWAYS show nearby restaurants, regardless of time.
      result = DineAvailabilityResponse(
        available:         false,
        confirmedSlot:     null,
        reason:            'seats_unavailable',
        alternativeSlots:  const [],
        nearbyRestaurants: _nearbyRestaurants.toList(),
        aiMessage:         _msgSeatsUnavailable(partySize, name),
      );

    } else if (normalized == null) {
      // ── Unknown time → treat as time_unavailable ──────────────────────────
      final alternatives = _openSlotsFor(partySize);
      result = DineAvailabilityResponse(
        available:         false,
        confirmedSlot:     null,
        reason:            'time_unavailable',
        alternativeSlots:  alternatives,
        nearbyRestaurants: const [],
        aiMessage:         _msgTimeUnavailable(timeSlot, name, alternatives),
      );

    } else if (_fullyBookedSlots.contains(normalized)) {
      // ── SCENARIO 2: time fully booked ─────────────────────────────────────
      final alternatives = _openSlotsFor(partySize);
      result = DineAvailabilityResponse(
        available:         false,
        confirmedSlot:     null,
        reason:            'time_unavailable',
        alternativeSlots:  alternatives,
        nearbyRestaurants: const [],
        aiMessage:         _msgTimeUnavailable(normalized, name, alternatives),
      );

    } else {
      // ── SCENARIO 1 & 4: available ─────────────────────────────────────────
      result = DineAvailabilityResponse(
        available:         true,
        confirmedSlot:     normalized,
        reason:            'ok',
        alternativeSlots:  const [],
        nearbyRestaurants: const [],
        aiMessage:         'Great! I found a table for $partySize at $name at $normalized. Let me confirm that for you.',
      );
    }

    _lastAvailability = result;
    _state = DineInState.idle;
    notifyListeners();
    return result;
  }

  // ── Confirm booking (client-side) ──────────────────────────────────────────
  Future<DineBookingConfirmation> confirmBooking({
    required String timeSlot,
    required int partySize,
    String? restaurantId,
    String? restaurantName,
  }) async {
    final name = (restaurantName?.isNotEmpty == true)
        ? restaurantName!
        : (_restaurantName.isNotEmpty ? _restaurantName : 'the restaurant');
    final id = restaurantId ?? _restaurantId;

    final bookingId = 'TBL${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final booking = DineBookingConfirmation(
      bookingId:      bookingId,
      restaurantId:   id,
      restaurantName: name,
      timeSlot:       _normalizeSlot(timeSlot) ?? timeSlot,
      partySize:      partySize,
      date:           _todayStr(),
      status:         'confirmed',
      aiMessage:
          'Your reservation has been made successfully! '
          'Table for $partySize at $name, ${_normalizeSlot(timeSlot) ?? timeSlot}. '
          'Booking ID: $bookingId. Enjoy your meal! 🥂',
    );

    _confirmedBooking = booking;
    _state = DineInState.confirmed;
    notifyListeners();
    return booking;
  }

  // ── Reset ──────────────────────────────────────────────────────────────────
  void reset() {
    _state            = DineInState.idle;
    _lastAvailability = null;
    _confirmedBooking = null;
    notifyListeners();
  }

  // ── Time slot normalization ────────────────────────────────────────────────
  /// Normalize user input like "7pm", "7:00pm", "7 pm", "19:00" → "7:00 PM"
  String? _normalizeSlot(String raw) {
    final s = raw.trim().toUpperCase().replaceAll(' ', '');

    // Try direct match first (case-insensitive, no spaces)
    for (final slot in _allSlots) {
      if (slot.replaceAll(' ', '').toUpperCase() == s) return slot;
    }

    // Pattern: "7PM", "7:30PM", or even "8:00 P"
    final re = RegExp(r'^(\d{1,2})(?::(\d{2}))?(A|P|AM|PM)$');
    final m = re.firstMatch(s);
    if (m != null) {
      int h = int.parse(m.group(1)!);
      int min = int.tryParse(m.group(2) ?? '0') ?? 0;
      final periodGroup = m.group(3)!;
      final period = periodGroup.startsWith('A') ? 'AM' : 'PM';

      // Snap minutes to nearest 30
      min = min < 15 ? 0 : (min < 45 ? 30 : 0);
      if (min == 0 && (int.tryParse(m.group(2) ?? '0') ?? 0) >= 45) h++;

      final candidate = '$h:${min.toString().padLeft(2, '0')} $period';
      if (_allSlots.contains(candidate)) return candidate;
    }

    // 24h format or naked time: "19:00", "19:30", "9:00", "7:30"
    final re24 = RegExp(r'^(\d{1,2}):(\d{2})$');
    final m24 = re24.firstMatch(raw.trim());
    if (m24 != null) {
      int h = int.parse(m24.group(1)!);
      final min = int.parse(m24.group(2)!);
      // Dinner is in the evening, default to PM for 1-11
      String period = 'PM';
      if (h >= 12) {
        period = 'PM';
        if (h > 12) h -= 12;
      } else if (h == 0) {
        period = 'AM';
        h = 12;
      }
      final candidate = '$h:${min.toString().padLeft(2, '0')} $period';
      if (_allSlots.contains(candidate)) return candidate;
    }

    return null;
  }

  List<String> _openSlotsFor(int partySize) {
    // All slots except fully-booked ones are "open" for small parties
    if (partySize < 6) {
      return _allSlots.where((s) => !_fullyBookedSlots.contains(s)).toList();
    }
    // Large parties: no open slots at this restaurant
    return [];
  }

  // ── Voice message builders ─────────────────────────────────────────────────
  String _msgTimeUnavailable(String slot, String name, List<String> alts) {
    if (alts.isEmpty) {
      return "Sorry, $slot is not available at $name and there are no other open slots today.";
    }
    final first = alts.first;
    final others = alts.skip(1).take(3).join(', ');
    return "Sorry, $slot is fully booked at $name. "
        "Can I book it for $first instead? Other available times: $others.";
  }

  String _msgSeatsUnavailable(int partySize, String name) {
    final names = _nearbyRestaurants.take(3).map((r) => r.name).join(', ');
    return "Sorry, there's no table for $partySize people available at $name right now. "
        "Would you like me to book at one of these nearby restaurants instead? $names.";
  }

  String _todayStr() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
