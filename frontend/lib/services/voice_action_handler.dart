/// Represents an in-app action that the Voice AI agent wants to perform.
class VoiceAction {
  final VoiceActionType type;
  final Map<String, dynamic> params;

  const VoiceAction({required this.type, this.params = const {}});

  bool get isComplete => missingParams.isEmpty;

  List<String> get missingParams {
    if (params['cancel'] == true) return [];

    if (type == VoiceActionType.bookTable) {
      final m = <String>[];
      // Step 1: need people count
      if (params['people'] == null) {
        m.add('people');
      }
      // Step 2: need time
      else if (params['time'] == null || (params['time'] as String).isEmpty) {
        m.add('time');
      }
      // Step 3: need confirmation (set externally after availability check)
      else if (params['confirm'] != true) {
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

    // TABLE BOOKING detection — must catch ALL natural phrasings
    if (_matchesAny(q, [
      // Explicit booking phrases
      'book a table', 'reserve a table', 'book table', 'book me a table',
      'reservation', 'i want to dine', 'want to dine', 'dining',
      // Natural/casual phrases (most common in practice)
      'table for', 'a table for', 'a table at', 'table at',
      'seats for', 'seat for',
      'dine in', 'dine at', 'eating at',
      'i want to book', 'want to book', 'can you book',
      'make a reservation', 'get a table',
    ])) {
      final time   = _extractTime(q);
      final people = _extractPeople(q);
      final rest   = _extractRestaurantName(q);
      var params = <String, dynamic>{};
      if (people != null) params['people'] = people;
      if (time.isNotEmpty) params['time'] = time;
      if (rest.isNotEmpty) params['restaurantName'] = rest;
      return VoiceAction(type: VoiceActionType.bookTable, params: params);
    }

    // TAKEAWAY detection
    if (_matchesAny(q, [
      'takeaway', 'take away', 'pick up', 'parcel', 'pack it',
      'ill pick', "i'll pick", 'collect',
    ])) {
      final time = _extractTime(q.isEmpty ? r : q);
      final item = _extractItem(q);
      final rest = _extractRestaurantName(q);
      var params = <String, dynamic>{};
      if (time.isNotEmpty) {
        params['time'] = time;
      }
      if (item.isNotEmpty) {
        params['item'] = item;
      }
      if (rest.isNotEmpty) {
        params['restaurantName'] = rest;
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

    if (curr == 'people') {
      final n = _extractPeople(q);
      if (n != null) updatedParams['people'] = n;
    } else if (curr == 'time') {
      final newTime = _extractTime(q);
      if (newTime.isNotEmpty) {
        updatedParams['time'] = newTime;
      }
    } else if (curr == 'alternative_time_confirm') {
      if (_isYes(q)) {
        updatedParams.remove('time_unavailable');
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

  // ── Public extraction helpers (called by VoiceAgentProvider) ──────────────

  /// Public wrapper — extracts people count from a raw utterance.
  int? extractPeople(String text) => _extractPeople(text);

  /// Public wrapper — extracts time string from a raw utterance.
  String extractTime(String text) => _extractTime(text);

  /// Public wrapper — extracts a phone number (e.g. 10 digits).
  String extractPhone(String text) => _extractPhone(text);

  /// Public wrapper — extracts a name.
  String extractName(String text) => _extractName(text);

  /// Public wrapper — extracts an item from a raw utterance.
  String extractItem(String text) => _extractItem(text);

  /// Public wrapper — extracts a restaurant name from a raw utterance.
  String extractRestaurantName(String text) => _extractRestaurantName(text);

  // ── Helpers ───────────────────────────────────────────────────────────────



  bool _isYes(String q) => _matchesAny(q, ['yes', 'yeah', 'yep', 'sure', 'ok', 'okay', 'proceed', 'go ahead', 'fine', 'alright', 'sounds good', 'great']);
  bool _isNo(String q)  => _matchesAny(q, ['no', 'nope', 'cancel', 'wait', 'stop', 'abort', "don't", 'nevermind']);

  bool _matchesAny(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw));

  String _detectPayment(String q) {
    if (q.contains('cash') || q.contains('cod')) return 'Cash on Delivery';
    if (q.contains('upi') || q.contains('gpay') || q.contains('phone pe')) return 'UPI';
    if (q.contains('card') || q.contains('credit') || q.contains('debit')) return 'Card';
    return 'Cash on Delivery';
  }

  /// Extracts a number of people/guests from [text].
  /// Handles: "5 people", "for 4", "3 guests", "six people", etc.
  int? _extractPeople(String text) {
    // Number words
    const words = {
      'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    };
    final lower = text.toLowerCase();
    for (final entry in words.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    // Numeric patterns: "5 people", "for 4", "party of 6"
    final re = RegExp(r'(\d+)\s*(people|persons?|guests?|pax|of us)?');
    final m = re.firstMatch(lower);
    if (m != null) {
      final n = int.tryParse(m.group(1)!);
      if (n != null && n >= 1 && n <= 50) return n;
    }
    return null;
  }

  /// Extracts a time string like "6:45 pm", "7 pm", "9:00 p.m." from [text].
  String _extractTime(String text) {
    // Strip dots out of p.m. / a.m. so regex easily matches
    final cleanText = text.replaceAll('.', '');
    final regexWithMinutes = RegExp(r'(\d{1,2}:\d{2})\s*(am|pm|p|a)?', caseSensitive: false);
    final regexHourOnly    = RegExp(r'(\d{1,2})\s*(am|pm|p|a)', caseSensitive: false);

    final mFull = regexWithMinutes.firstMatch(cleanText);
    if (mFull != null) {
      String suffix = mFull.group(2) ?? '';
      if (suffix.toLowerCase() == 'p') suffix = 'pm';
      if (suffix.toLowerCase() == 'a') suffix = 'am';
      return '${mFull.group(1)} ${suffix.toUpperCase()}'.trim();
    }

    final mHour = regexHourOnly.firstMatch(cleanText);
    if (mHour != null) {
      String suffix = mHour.group(2)!.toLowerCase();
      if (suffix == 'p') suffix = 'pm';
      if (suffix == 'a') suffix = 'am';
      return '${mHour.group(1)}:00 ${suffix.toUpperCase()}';
    }

    return '';
  }

  /// Extracts a 10-digit Indian phone number from [text].
  String _extractPhone(String text) {
    // Remove all non-digit characters for easier matching
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return '';
  }

  /// Extracts a name from [text] based on common patterns.
  String _extractName(String text) {
    final lower = text.toLowerCase();
    
    final nameTriggers = [
      'my name is ', 'im ', "i'm ", 'i am ', 'name is ', 'this is ',
    ];
    for (final t in nameTriggers) {
      if (lower.contains(t)) {
        final raw = text.substring(lower.indexOf(t) + t.length).trim();
        // Return the first word (usually the first name)
        if (raw.isNotEmpty) {
          return raw.split(' ').first;
        }
      }
    }
    
    // If no trigger words are found but text is short (1-2 words), assume it's just the name
    final words = text.trim().split(' ');
    if (words.isNotEmpty && words.length <= 2) {
      return words.first;
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
    
    // Truncate before prepositions that usually indicate the restaurant or time
    const cutOffWords = [' from ', ' at ', ' by ', ' i\'ll ', ' ill ', ' ill be '];
    for (final cw in cutOffWords) {
      if (result.contains(cw)) {
        result = result.substring(0, result.indexOf(cw));
      }
    }
    
    const stopWords = [
      'in cart', 'to cart', 'for me', 'please', 'and',
      'with', 'payment', 'cash on delivery', 'cod'
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
      "tell me the menu of ", 'what does ', 'book at ', 'book a table at ',
      'reserve at ', 'table at ', 'dine at ', 'eating at ',
      'people at ', 'guests at ', 'seats at ', 'person at ',
    ];
    for (final t in triggers) {
      if (text.contains(t)) {
        final after = text.substring(text.indexOf(t) + t.length);
        return after.split(RegExp(r'\b(menu|restaurant|show|tell|and|for|at)\b')).first.trim();
      }
    }
    return '';
  }
}
