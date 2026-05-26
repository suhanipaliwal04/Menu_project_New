/// Request body for POST /chat
class ChatRequest {
  final String query;
  final String areaName;
  final String? restaurantId;

  const ChatRequest({
    required this.query,
    required this.areaName,
    this.restaurantId,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'area_name': areaName,
        if (restaurantId != null) 'restaurant_id': restaurantId,
      };
}

/// A single food item returned by the RAG pipeline
class ChatMenuItem {
  final String itemName;
  final String restaurantName;
  final String? sectionName;
  final int? price;
  final bool? isVeg;
  final int? calories;
  final int? healthScore;
  final double? similarity;

  const ChatMenuItem({
    required this.itemName,
    required this.restaurantName,
    this.sectionName,
    this.price,
    this.isVeg,
    this.calories,
    this.healthScore,
    this.similarity,
  });

  factory ChatMenuItem.fromJson(Map<String, dynamic> json) => ChatMenuItem(
        itemName: json['item_name']?.toString() ?? '',
        restaurantName: json['restaurant_name']?.toString() ?? 'Unknown',
        sectionName: json['section_name']?.toString(),
        price: _parseInt(json['price']),
        isVeg: _parseBool(json['is_veg']),
        calories: _parseInt(json['calories']),
        healthScore: _parseInt(json['health_score']),
        similarity: _parseDouble(json['similarity']),
      );

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt();
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final str = value.toLowerCase();
      if (str == 'true' || str == '1') return true;
      if (str == 'false' || str == '0') return false;
    }
    if (value is num) {
      return value == 1;
    }
    return null;
  }

  String get priceDisplay => price != null ? '₹$price' : '—';
}

/// Parsed filters extracted by the query parser
class FiltersUsed {
  final bool? isVeg;
  final int? maxPrice;
  final int? minPrice;
  final int? maxCalories;
  final int? minHealthScore;
  final String? sectionName;
  final String semanticQuery;

  const FiltersUsed({
    this.isVeg,
    this.maxPrice,
    this.minPrice,
    this.maxCalories,
    this.minHealthScore,
    this.sectionName,
    required this.semanticQuery,
  });

  factory FiltersUsed.fromJson(Map<String, dynamic> json) => FiltersUsed(
        isVeg: ChatMenuItem._parseBool(json['is_veg']),
        maxPrice: ChatMenuItem._parseInt(json['max_price']),
        minPrice: ChatMenuItem._parseInt(json['min_price']),
        maxCalories: ChatMenuItem._parseInt(json['max_calories']),
        minHealthScore: ChatMenuItem._parseInt(json['min_health_score']),
        sectionName: json['section_name']?.toString(),
        semanticQuery: json['semantic_query']?.toString() ?? '',
      );

  List<String> get activeFilters {
    final f = <String>[];
    if (isVeg == true) f.add('Veg Only');
    if (isVeg == false) f.add('Non-Veg');
    if (maxPrice != null) f.add('Under ₹$maxPrice');
    if (minPrice != null) f.add('Over ₹$minPrice');
    if (minHealthScore != null) f.add('Health ≥ $minHealthScore/10');
    if (maxCalories != null) f.add('Max ${maxCalories}kcal');
    if (sectionName != null) f.add(sectionName!);
    return f;
  }
}

/// Full response from POST /chat
class ChatResponse {
  final String answer;
  final List<ChatMenuItem> items;
  final FiltersUsed filtersUsed;

  const ChatResponse({
    required this.answer,
    required this.items,
    required this.filtersUsed,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
        answer: json['answer'] ?? '',
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => ChatMenuItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        filtersUsed: FiltersUsed.fromJson(
            json['filters_used'] as Map<String, dynamic>? ?? {}),
      );
}

/// Full response from POST /voice/chat — includes session_id for continuity
class VoiceChatResponse {
  final String answer;
  final String sessionId;
  final List<ChatMenuItem> items;
  final FiltersUsed filtersUsed;

  const VoiceChatResponse({
    required this.answer,
    required this.sessionId,
    required this.items,
    required this.filtersUsed,
  });

  factory VoiceChatResponse.fromJson(Map<String, dynamic> json) =>
      VoiceChatResponse(
        answer: json['answer'] ?? '',
        sessionId: json['session_id'] ?? '',
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => ChatMenuItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        filtersUsed: FiltersUsed.fromJson(
            json['filters_used'] as Map<String, dynamic>? ?? {}),
      );
}
