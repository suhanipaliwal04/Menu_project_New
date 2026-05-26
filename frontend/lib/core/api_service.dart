import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'constants.dart';
import '../models/area_model.dart';
import '../models/restaurant_model.dart';
import '../models/menu_model.dart';
import '../models/chat_models.dart';
import '../models/upload_models.dart';
import '../models/create_models.dart';

/// Central HTTP service for all backend API calls.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _base = AppConstants.baseUrl;
  final http.Client _client = http.Client();

  Duration get _timeout =>
      const Duration(seconds: AppConstants.receiveTimeoutSeconds);

  // ── Helper ───────────────────────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<dynamic> _get(String path, {Map<String, String?>? params}) async {
    final uri = Uri.parse('$_base$path').replace(
      queryParameters: params
          ?.map((k, v) => MapEntry(k, v))
          .entries
          .where((e) => e.value != null)
          .fold<Map<String, String>>({}, (m, e) {
        m[e.key] = e.value!;
        return m;
      }),
    );
    final response = await _client.get(uri, headers: _headers).timeout(_timeout);
    return _handle(response);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_base$path');
    final response = await _client
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    return _handle(response);
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = res.body;
      if (body.isEmpty) return {};
      return jsonDecode(body);
    }
    String message = 'Request failed (${res.statusCode})';
    try {
      final data = jsonDecode(res.body);
      message = data['detail'] ?? data['message'] ?? message;
    } catch (_) {}
    throw ApiException(message, res.statusCode);
  }

  // ── Health ────────────────────────────────────────────────────────────────────

  /// GET /health — basic connectivity check
  Future<bool> healthCheck() async {
    try {
      // Health is at root /health, not under /api/v1
      final uri = Uri.parse(
          '${AppConstants.baseUrl.replaceAll('/api/v1', '')}/health');
      final response =
          await _client.get(uri, headers: _headers).timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Areas ────────────────────────────────────────────────────────────────────

  /// POST /areas/ — create a new area
  Future<AreaModel> createArea(CreateAreaRequest req) async {
    final data = await _post(AppConstants.areasEndpoint, req.toJson());
    return AreaModel.fromJson(data as Map<String, dynamic>);
  }

  /// GET /areas — list all areas, optionally filtered by city
  Future<List<AreaModel>> getAreas({String? city}) async {
    final data = await _get(AppConstants.areasEndpoint,
        params: {'city': city}) as List<dynamic>;
    return data.map((e) => AreaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /areas/{id} — single area
  Future<AreaModel> getArea(String areaId) async {
    final data = await _get('${AppConstants.areasEndpoint}/$areaId')
        as Map<String, dynamic>;
    return AreaModel.fromJson(data);
  }

  /// GET /areas/{id}/restaurants — restaurants in an area
  Future<AreaRestaurantsResponse> getAreaRestaurants(String areaId) async {
    final data = await _get('${AppConstants.areasEndpoint}/$areaId/restaurants')
        as Map<String, dynamic>;
    return AreaRestaurantsResponse.fromJson(data);
  }

  // ── Restaurants ───────────────────────────────────────────────────────────────

  /// POST /restaurants/ — create a new restaurant
  Future<RestaurantModel> createRestaurant(CreateRestaurantRequest req) async {
    final data = await _post(AppConstants.restaurantsEndpoint, req.toJson());
    return RestaurantModel.fromJson(data as Map<String, dynamic>);
  }

  /// GET /restaurants — list restaurants with optional filters
  Future<List<RestaurantModel>> getRestaurants({
    String? areaId,
    String? city,
    String? cuisine,
  }) async {
    final data = await _get(AppConstants.restaurantsEndpoint, params: {
      'area_id': areaId,
      'city': city,
      'cuisine': cuisine,
    }) as List<dynamic>;
    return data
        .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /restaurants/{id} — single restaurant by ID
  Future<RestaurantModel> getRestaurant(String restaurantId) async {
    final data =
        await _get('${AppConstants.restaurantsEndpoint}/$restaurantId')
            as Map<String, dynamic>;
    return RestaurantModel.fromJson(data);
  }

  /// GET /restaurants/{id}/menu — full menu for a restaurant
  Future<RestaurantMenuResponse> getRestaurantMenu(String restaurantId) async {
    final data = await _get(
        '${AppConstants.restaurantsEndpoint}/$restaurantId/menu')
        as Map<String, dynamic>;
    return RestaurantMenuResponse.fromJson(data);
  }

  // ── Menu Upload ───────────────────────────────────────────────────────────────

  /// POST /menus/upload — upload menu image (multipart)
  /// Note: all four fields are required by the API.
  Future<UploadResult> uploadMenu({
    required File imageFile,
    required String areaName,
    required String city,
    required String restaurantName,
  }) async {
    final uri = Uri.parse('$_base${AppConstants.menusUploadEndpoint}');
    final request = http.MultipartRequest('POST', uri);

    // Form fields — all required per API docs
    request.fields['area_name'] = areaName;
    request.fields['city'] = city;
    request.fields['restaurant_name'] = restaurantName;

    // File
    final ext = imageFile.path.split('.').last.toLowerCase();
    final contentType = ext == 'pdf'
        ? MediaType('application', 'pdf')
        : MediaType('image', ext == 'jpg' ? 'jpeg' : ext);

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: contentType,
    ));

    final streamedResponse =
        await request.send().timeout(const Duration(minutes: 3));
    final response = await http.Response.fromStream(streamedResponse);
    final data = _handle(response) as Map<String, dynamic>;
    return UploadResult.fromJson(data);
  }

  /// GET /menus/uploads/{id} — check upload/processing status
  Future<UploadStatus> getUploadStatus(String uploadId) async {
    final data = await _get('${AppConstants.menusUploadsEndpoint}/$uploadId')
        as Map<String, dynamic>;
    return UploadStatus.fromJson(data);
  }

  // ── Chat / RAG ───────────────────────────────────────────────────────────────

  /// POST /chat — Natural language food discovery
  Future<ChatResponse> chat({
    required String query,
    String? areaName,
    String? restaurantId,
  }) async {
    final data = await _post(AppConstants.chatEndpoint, {
      'query': query,
      if (areaName != null && areaName.isNotEmpty) 'area_name': areaName,
      if (restaurantId != null) 'restaurant_id': restaurantId,
    });
    return ChatResponse.fromJson(data as Map<String, dynamic>);
  }

  // ── Voice AI ──────────────────────────────────────────────────────────────────

  /// POST /voice/chat — Voice-optimized RAG with session continuity.
  /// Returns a TTS-ready short answer plus a session_id for multi-turn dialogue.
  Future<VoiceChatResponse> voiceChat({
    required String query,
    String? sessionId,
    String? areaName,
    String? restaurantId,
  }) async {
    final data = await _post(AppConstants.voiceChatEndpoint, {
      'query': query,
      if (sessionId != null) 'session_id': sessionId,
      if (areaName != null && areaName.isNotEmpty) 'area_name': areaName,
      if (restaurantId != null) 'restaurant_id': restaurantId,
    });
    return VoiceChatResponse.fromJson(data as Map<String, dynamic>);
  }

  /// POST /voice/session — Create a new voice session.
  /// Returns session_id to store and pass on subsequent voiceChat() calls.
  Future<String> createVoiceSession({String? areaName}) async {
    final data = await _post(AppConstants.voiceSessionEndpoint, {
      if (areaName != null && areaName.isNotEmpty) 'area_name': areaName,
    });
    return (data as Map<String, dynamic>)['session_id'] as String;
  }

  /// DELETE /voice/session/{id} — Clean up when user exits Voice Agent.
  Future<void> endVoiceSession(String sessionId) async {
    try {
      final uri = Uri.parse('$_base${AppConstants.voiceSessionEndpoint}/$sessionId');
      await _client.delete(uri, headers: _headers).timeout(_timeout);
    } catch (_) {
      // Best-effort — don't crash if session is already expired
    }
  }
}

// ── Exception ────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
