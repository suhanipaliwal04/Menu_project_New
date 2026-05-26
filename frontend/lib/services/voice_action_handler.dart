class VoiceAction {
  final VoiceActionType type;
  final Map<String, dynamic> params;

  const VoiceAction({required this.type, this.params = const {}});

  bool get isComplete => missingParams.isEmpty;

  List<String> get missingParams {
    if (params['cancel'] == true) return []; // Cancelled, no missing params, will be aborted downstream

    if (type == VoiceActionType.bookTable) {
      final m = <String>[];
      if (params['time'] == null || (params['time'] as String).isEmpty) {
        m.add('time');
      } else if (params['time_unavailable'] == true) {
        m.add('alternative_time_confirm');
      } else if (params['confirm'] != true) {
        m.add('confirm');
      }
      return m;
    }
    if (type == VoiceActionType.scheduleTakeaway) {
      final m = <String>[];
      if (params['item'] == null || (params['item'] as String).isEmpty) m.add('item');
      else if (params['time'] == null || (params['time'] as String).isEmpty) m.add('time');
      else if (params['time_unavailable'] == true) m.add('alternative_time_confirm');
      else if (params['confirm'] != true) m.add('confirm');
      return m;
    }
    if (type == VoiceActionType.placeOrder) {
      final m = <String>[];
      if (params['item'] == null || (params['item'] as String).isEmpty) m.add('item');
      else if (params['confirm'] != true) m.add('confirm');
      return m;
    }
    return [];
  }
}

enum VoiceActionType {
  none,
  search,
  openRestaurant,
  addToCart,
  placeOrder,
  bookTable,
  scheduleTakeaway,
}

/// Parses a plain text AI response (and the user's query) to detect
/// which in-app action should be performed automatically.
class VoiceActionHandler {
  static final VoiceActionHandler _instance = VoiceActionHandler._internal();
  factory VoiceActionHandler() => _instance;
  VoiceActionHandler._internal();

  /// Inspect [userQuery] and [aiReply] and return the best matching action.
  VoiceAction parse({
    required String userQuery,
    required String aiReply,
  }) {
    final q = userQuery.toLowerCase();
    final r = aiReply.toLowerCase();

    // CART OPEN detection
    if (_matchesAny(q, ['view cart', 'show cart', 'open cart', 'go to cart', 'what is in my cart'])) {
      return const VoiceAction(type: VoiceActionType.placeOrder);
    }

    // ORDER / PAYMENT detection (must be before cart check)
    if (_matchesAny(q, [
      'order it', 'place order', 'confirm order', 'buy it', 'checkout',
      'cash on delivery', 'cod', 'pay online', 'pay by upi',
      'order me'
    ])) {
      final paymentMethod = _detectPayment(q);
      final item = _extractItem(q);
      return VoiceAction(
        type: VoiceActionType.placeOrder,
        params: {'payment': paymentMethod, 'item': item},
      );
    }

    // TABLE BOOKING detection
    if (_matchesAny(q, [
      'book a table', 'reserve a table', 'book table', 'dine in',
      'reservation', 'book me a table',
    ])) {
      final time = _extractTime(q.isEmpty ? r : q);
      var params = <String, dynamic>{};
      if (time.isNotEmpty) {
        params['time'] = time;
        _checkMockAvailability(params);
      }
      return VoiceAction(
        type: VoiceActionType.bookTable,
        params: params,
      );
    }

    // TAKEAWAY detection
    if (_matchesAny(q, [
      'takeaway', 'take away', 'pick up', 'parcel', 'pack it',
      'ill pick', "i'll pick", 'collect',
    ])) {
      final time = _extractTime(q.isEmpty ? r : q);
      final item = _extractItem(q);
      var params = <String, dynamic>{};
      if (time.isNotEmpty) {
        params['time'] = time;
        _checkMockAvailability(params);
      }
      if (item.isNotEmpty) {
        params['item'] = item;
      }
      return VoiceAction(
        type: VoiceActionType.scheduleTakeaway,
        params: params,
      );
    }

    // ADD TO CART detection
    if (_matchesAny(q, [
      'add', 'put', 'cart', 'order', 'want to eat', 'i want',
      'get me', 'bring me',
    ])) {
      final item = _extractItem(q);
      if (item.isNotEmpty) {
        return VoiceAction(
          type: VoiceActionType.addToCart,
          params: {'item': item},
        );
      }
    }

    // OPEN RESTAURANT detection
    if (_matchesAny(q, [
      'menu of', 'show menu', "what's on the menu", 'open restaurant',
      'open ', "what does", 'tell me the menu', 'go to',
    ])) {
      final restaurant = _extractRestaurantName(q);
      return VoiceAction(
        type: VoiceActionType.openRestaurant,
        params: {'restaurantName': restaurant},
      );
    }

    // SEARCH detection (general food/cravings query)
    if (_matchesAny(q, [
      'want to eat', 'hungry', 'craving', 'looking for', 'find me',
      'search', 'suggest', 'recommend', 'healthy', 'spicy', 'sweet', 'veg',
      'what should i eat', 'something to eat',
    ])) {
      return VoiceAction(
        type: VoiceActionType.search,
        params: {'query': userQuery},
      );
    }

    // If AI reply mentions search results
    if (_matchesAny(r, [
      'here are', 'i found', 'results', 'options for', 'you might like',
      'recommended', 'available at',
    ])) {
      return VoiceAction(
        type: VoiceActionType.search,
        params: {'query': userQuery},
      );
    }

    return const VoiceAction(type: VoiceActionType.none);
  }

  /// Attempts to fill missing constraints of a `pendingAction` from a new user utterance.
  VoiceAction fillMissingParams(VoiceAction pendingAction, String newQuery) {
    var updatedParams = Map<String, dynamic>.from(pendingAction.params);
    final q = newQuery.toLowerCase();
    final missing = pendingAction.missingParams;

    if (missing.isEmpty) return pendingAction;
    final curr = missing.first; // handle one at a time

    if (curr == 'time') {
      final newTime = _extractTime(q);
      if (newTime.isNotEmpty) {
        updatedParams['time'] = newTime;
        _checkMockAvailability(updatedParams);
      }
    } else if (curr == 'alternative_time_confirm') {
      if (_isYes(q)) {
        updatedParams.remove('time_unavailable'); // Accepted!
      } else if (_isNo(q)) {
        updatedParams.remove('time');
        updatedParams.remove('time_unavailable');
      }
    } else if (curr == 'item') {
      final newItem = _extractItem(q);
      if (newItem.isNotEmpty) updatedParams['item'] = newItem;
    } else if (curr == 'confirm') {
      if (_isYes(q)) {
        updatedParams['confirm'] = true;
      } else if (_isNo(q)) {
        updatedParams['cancel'] = true;
      }
    }

    return VoiceAction(type: pendingAction.type, params: updatedParams);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _checkMockAvailability(Map<String, dynamic> params) {
    final t = params['time'] as String;
    // Mock: if they ask for exactly the top of the hour 7, 8, or 9
    if (t.contains('7:00') || t.contains('8:00') || t.contains('9:00')) {
      params['time_unavailable'] = true;
      params['original_time'] = t;
      params['time'] = t.replaceAll(':00', ':30'); // Suggest half-hour later
    }
  }

  bool _isYes(String q) => _matchesAny(q, ['yes', 'yeah', 'yep', 'sure', 'ok', 'okay', 'proceed', 'go ahead', 'fine', 'alright']);
  bool _isNo(String q) => _matchesAny(q, ['no', 'nope', 'cancel', 'wait', 'stop', 'abort', 'don\'t', 'nevermind']);

  bool _matchesAny(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw));

  String _detectPayment(String q) {
    if (q.contains('cash') || q.contains('cod')) return 'Cash on Delivery';
    if (q.contains('upi') || q.contains('gpay') || q.contains('phone pe')) return 'UPI';
    if (q.contains('card') || q.contains('credit') || q.contains('debit')) return 'Card';
    return 'Cash on Delivery'; // default
  }

  /// Extracts a time string like "6:45 pm", "7 pm" from [text].
  String _extractTime(String text) {
    // Look for patterns like 6:45 pm / 7pm / 18:30
    final regexWithMinutes = RegExp(r'(\d{1,2}:\d{2})\s*(am|pm)?', caseSensitive: false);
    final regexHourOnly   = RegExp(r'(\d{1,2})\s*(am|pm)', caseSensitive: false);

    final mFull = regexWithMinutes.firstMatch(text);
    if (mFull != null) {
      final suffix = mFull.group(2) ?? '';
      return '${mFull.group(1)} ${suffix.toUpperCase()}'.trim();
    }

    final mHour = regexHourOnly.firstMatch(text);
    if (mHour != null) {
      return '${mHour.group(1)}:00 ${mHour.group(2)!.toUpperCase()}';
    }

    return '';
  }

  /// Tries to extract a food item name from [text].
  String _extractItem(String text) {
    const triggers = [
      'add ', 'put ', 'order ', 'get me ', 'bring me ', 'want ', 'a ',
      'of ', 'takeaway of ', 'takeaway ',
    ];
    String result = text;
    for (final t in triggers) {
      if (result.contains(t)) {
        result = result.substring(result.indexOf(t) + t.length);
        break;
      }
    }
    // Remove trailing noise words
    const stopWords = [
      'in cart', 'to cart', 'for me', 'please', 'and', 'from',
      'pranil da dhaba', 'with', 'payment', 'cash on delivery', 'cod'
    ];
    for (final sw in stopWords) {
      result = result.replaceAll(sw, '');
    }
    
    result = result.trim();
    if (result == 'takeaway' || result == 'take away') return '';
    result = result.replaceAll('takeaway', '').replaceAll('take away', '');

    return result.trim();
  }

  /// Tries to extract a restaurant name from [text].
  String _extractRestaurantName(String text) {
    const triggers = [
      'menu of ', 'show menu of ', 'open ', 'go to ', 'at ',
      "tell me the menu of ", 'what does ',
    ];
    for (final t in triggers) {
      if (text.contains(t)) {
        final after = text.substring(text.indexOf(t) + t.length);
        return after.split(RegExp(r"\b(menu|restaurant|show|tell|and)\b")).first.trim();
      }
    }
    return '';
  }
}
