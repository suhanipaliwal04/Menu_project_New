import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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

  // JWT token set after admin login
  String? _authToken;

  void setAuthToken(String? token) => _authToken = token;

  Duration get _timeout =>
      const Duration(seconds: AppConstants.receiveTimeoutSeconds);

  // ── Helper ───────────────────────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<dynamic> _get(String path, {Map<String, String?>? params, bool auth = false}) async {
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
    final response = await _client.get(uri, headers: auth ? _authHeaders : _headers).timeout(_timeout);
    return _handle(response);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body, {bool auth = false}) async {
    final uri = Uri.parse('$_base$path');
    final response = await _client
        .post(uri, headers: auth ? _authHeaders : _headers, body: jsonEncode(body))
        .timeout(_timeout);
    return _handle(response);
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_base$path');
    final response = await _client
        .put(uri, headers: _authHeaders, body: jsonEncode(body))
        .timeout(_timeout);
    return _handle(response);
  }

  Future<void> _deleteReq(String path) async {
    final uri = Uri.parse('$_base$path');
    final response = await _client.delete(uri, headers: _authHeaders).timeout(_timeout);
    _handle(response);
  }

  // Generic public wrappers
  Future<dynamic> get(String path, {Map<String, String?>? params, bool auth = false}) => _get(path, params: params, auth: auth);
  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = false}) => _post(path, body, auth: auth);
  Future<dynamic> put(String path, Map<String, dynamic> body) => _put(path, body);
  Future<void> deleteReq(String path) => _deleteReq(path);


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
    final data = await _post(AppConstants.restaurantsEndpoint, req.toJson(), auth: true);
    return RestaurantModel.fromJson(data as Map<String, dynamic>);
  }

  /// GET /restaurants — list restaurants with optional filters
  Future<List<RestaurantModel>> getRestaurants({
    String? areaId,
    String? city,
    String? cuisine,
    String? orderType,
    double? userLat,
    double? userLng,
  }) async {
    final params = <String, String>{};
    if (areaId != null) params['area_id'] = areaId;
    if (city != null) params['city'] = city;
    if (cuisine != null) params['cuisine'] = cuisine;
    if (orderType != null) params['order_type'] = orderType;
    if (userLat != null) params['user_lat'] = userLat.toString();
    if (userLng != null) params['user_lng'] = userLng.toString();

    final data = await _get(AppConstants.restaurantsEndpoint, params: params)
        as List<dynamic>;
    return data.map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /reviews/restaurant/{id}
  Future<List<Map<String, dynamic>>> getRestaurantReviews(String restaurantId) async {
    final data = await _get('/reviews/restaurant/$restaurantId') as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  // ── Bookings (REST API) ───────────────────────────────────────────────────────

  /// POST /bookings/
  Future<Map<String, dynamic>> createBooking({
    required String restaurantId,
    required int partySize,
    required String timeSlot,
    String? customerName,
    String? customerPhone,
  }) async {
    return await _post('/bookings/', {
      'restaurant_id': restaurantId,
      'party_size': partySize,
      'time_slot': timeSlot,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
    }) as Map<String, dynamic>;
  }

  /// GET /bookings/admin/restaurants/{id}/bookings
  Future<List<Map<String, dynamic>>> getAdminBookings(String restaurantId, {String? status}) async {
    final params = status != null ? {'status_filter': status} : null;
    final data = await _get('/bookings/admin/restaurants/$restaurantId/bookings', params: params, auth: true) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  /// PUT /bookings/admin/bookings/{id}
  Future<Map<String, dynamic>> updateBookingStatus(String bookingId, String status) async {
    return await _put('/bookings/admin/bookings/$bookingId', {'status': status}) as Map<String, dynamic>;
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
    required XFile imageFile,
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
    final ext = imageFile.name.split('.').last.toLowerCase();
    final contentType = ext == 'pdf'
        ? MediaType('application', 'pdf')
        : MediaType('image', ext == 'jpg' ? 'jpeg' : ext);

    final bytes = await imageFile.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: imageFile.name,
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
    double? userLat,
    double? userLng,
  }) async {
    final data = await _post(AppConstants.chatEndpoint, {
      'query': query,
      if (areaName != null && areaName.isNotEmpty) 'area_name': areaName,
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (userLat != null) 'user_lat': userLat,
      if (userLng != null) 'user_lng': userLng,
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

  // ── Dine-In Booking ───────────────────────────────────────────────────────────

  /// POST /dine/check-availability — Fast availability check (no LLM).
  /// Returns availability status, alternative slots, and nearby restaurants.
  Future<DineAvailabilityResponse> checkDineAvailability({
    required String restaurantId,
    required String restaurantName,
    required String timeSlot,
    required int partySize,
  }) async {
    final data = await _post(AppConstants.dineCheckEndpoint, {
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'time_slot': timeSlot,
      'party_size': partySize,
    });
    return DineAvailabilityResponse.fromJson(data as Map<String, dynamic>);
  }

  /// POST /dine/confirm-booking — Confirm a table reservation.
  /// Returns full booking details with a unique booking ID.
  Future<DineBookingConfirmation> confirmDineBooking({
    required String restaurantId,
    required String restaurantName,
    required String timeSlot,
    required int partySize,
    String? dateStr,
    String? customerName,
    String? customerPhone,
  }) async {
    final data = await _post(AppConstants.dineConfirmEndpoint, {
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'time_slot': timeSlot,
      'party_size': partySize,
      if (dateStr != null) 'date_str': dateStr,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
    });
    return DineBookingConfirmation.fromJson(data as Map<String, dynamic>);
  }

  /// GET /dine/slots/{restaurantId}
  Future<List<Map<String, dynamic>>> getAvailableSlots(String restaurantId, String date) async {
    final data = await _get('/dine/slots/$restaurantId?date=$date');
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// POST /bookings/customer
  Future<List<dynamic>> getCustomerBookings(List<String> bookingIds) async {
    final data = await _post('/bookings/customer', {
      'booking_ids': bookingIds,
    });
    return data as List<dynamic>;
  }

  /// POST /orders/customer
  Future<List<dynamic>> getCustomerOrders(List<String> orderIds) async {
    final data = await _post('/orders/customer', {
      'order_ids': orderIds,
    });
    return data as List<dynamic>;
  }


  // ── Orders (Takeaway) ────────────────────────────────────────────────────────

  /// POST /orders/takeaway
  Future<Map<String, dynamic>> createTakeawayOrder({
    required String restaurantId,
    required String customerName,
    required String customerPhone,
    required String timeSlot,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await _post(AppConstants.ordersTakeawayEndpoint, {
      'restaurant_id': restaurantId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'time_slot': timeSlot,
      'total_amount': totalAmount,
      'items': items,
    });
    return data as Map<String, dynamic>;
  }

  /// GET /orders/admin/restaurants/{id}/orders
  Future<List<Map<String, dynamic>>> getAdminOrders(String restaurantId) async {
    final data = await _get('${AppConstants.adminOrdersEndpoint}/$restaurantId/orders', auth: true);
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// PUT /admin/orders/{id}
  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    final data = await _put('/orders/admin/orders/$orderId', {'status': status});
    return data as Map<String, dynamic>;
  }

  // ── Admin Auth ────────────────────────────────────────────────────────────────

  /// POST /auth/login — Supabase sign-in with strict role checks.
  Future<Map<String, dynamic>> login(String email, String password, String expectedRole) async {
    final data = await _post(AppConstants.authLoginEndpoint, {
      'email': email,
      'password': password,
      'expected_role': expectedRole,
    });
    return data as Map<String, dynamic>;
  }

  /// POST /auth/register/{role}
  Future<Map<String, dynamic>> register(String email, String password, String role, String fullName, String phone, String state, String city) async {
    final data = await _post('${AppConstants.authRegisterEndpoint}/$role', {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone_number': phone,
      'state': state,
      'city': city,
    });
    return data as Map<String, dynamic>;
  }

  /// GET /auth/me — Returns logged-in user's info + restaurant_id (if any).
  Future<Map<String, dynamic>> getMe() async {
    final data = await _get('/auth/me', auth: true);
    return data as Map<String, dynamic>;
  }

  /// PUT /auth/me
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) async {
    final data = await _put('/auth/me', body);
    return data as Map<String, dynamic>;
  }

  // ── Locations ────────────────────────────────────────────────────────────────
  
  Future<List<dynamic>> getStates() async {
    final data = await _get('/locations/states');
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getCities(String stateName) async {
    final data = await _get('/locations/states/$stateName/cities');
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createState(String stateName) async {
    final data = await _post('/locations/states', {'state_name': stateName}, auth: true);
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createCity(String cityName, String stateId) async {
    final data = await _post('/locations/cities', {'city_name': cityName, 'state_id': stateId}, auth: true);
    return data as Map<String, dynamic>;
  }

  // ── Admin Dashboard ───────────────────────────────────────────────────────────

  /// GET /admin/dashboard/{restaurantId} — Live stats for a restaurant.
  Future<Map<String, dynamic>> getAdminDashboard(String restaurantId) async {
    final data = await _get(
      '${AppConstants.adminEndpoint}/dashboard/$restaurantId',
      auth: true,
    );
    return data as Map<String, dynamic>;
  }

  // ── System Admin ─────────────────────────────────────────────────────────────

  /// GET /system-admin/pending-restaurants
  Future<List<Map<String, dynamic>>> getPendingRestaurants() async {
    final data = await _get('/system-admin/pending-restaurants', auth: true);
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// POST /system-admin/approve-restaurant/{user_id}
  Future<Map<String, dynamic>> approveRestaurant(String userId) async {
    final data = await _post('/system-admin/approve-restaurant/$userId', {}, auth: true);
    return data as Map<String, dynamic>;
  }

  /// GET /system-admin/restaurants
  Future<List<Map<String, dynamic>>> getSystemAdminRestaurants() async {
    final data = await _get('/system-admin/restaurants', auth: true);
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// DELETE /system-admin/restaurants/{restaurant_id}
  Future<void> deleteSystemAdminRestaurant(String restaurantId) async {
    await _deleteReq('/system-admin/restaurants/$restaurantId');
  }

  // ── Admin Menu Items ─────────────────────────────────────────────────────────

  /// GET /admin/restaurants/{id}/items — All menu items for admin (with optional filters).
  Future<List<dynamic>> getAdminMenuItems(
    String restaurantId, {
    String? sectionName,
    bool? isVeg,
  }) async {
    final data = await _get(
      '${AppConstants.adminEndpoint}/restaurants/$restaurantId/items',
      params: {
        if (sectionName != null) 'section_name': sectionName,
        if (isVeg != null) 'is_veg': isVeg.toString(),
      },
      auth: true,
    );
    return data as List<dynamic>;
  }

  /// GET /admin/restaurants/{id}/sections — All sections with item counts.
  Future<List<dynamic>> getAdminSections(String restaurantId) async {
    final data = await _get(
      '${AppConstants.adminEndpoint}/restaurants/$restaurantId/sections',
      auth: true,
    );
    return data as List<dynamic>;
  }

  /// POST /admin/restaurants/{id}/items — Manually add a single item (no OCR).
  Future<Map<String, dynamic>> addAdminMenuItem(
    String restaurantId,
    Map<String, dynamic> itemData,
  ) async {
    final uri = Uri.parse('$_base${AppConstants.adminEndpoint}/restaurants/$restaurantId/items');
    final response = await _client
        .post(uri, headers: _authHeaders, body: jsonEncode(itemData))
        .timeout(_timeout);
    return _handle(response) as Map<String, dynamic>;
  }

  /// PUT /admin/restaurants/{id}/items/{itemId} — Partial update.
  Future<Map<String, dynamic>> updateAdminMenuItem(
    String restaurantId,
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    final data = await _put(
      '${AppConstants.adminEndpoint}/restaurants/$restaurantId/items/$itemId',
      updates,
    );
    return data as Map<String, dynamic>;
  }

  /// DELETE /admin/restaurants/{id}/items/{itemId}
  Future<void> deleteAdminMenuItem(String restaurantId, String itemId) async {
    await _deleteReq(
      '${AppConstants.adminEndpoint}/restaurants/$restaurantId/items/$itemId',
    );
  }

  /// POST /admin/restaurants/{id}/menu/upload — Upload menu image with replace/append mode.
  Future<Map<String, dynamic>> adminUploadMenuImage({
    required XFile imageFile,
    required String restaurantId,
    String mode = 'replace',
    String extractionMethod = 'paddleocr',
  }) async {
    final uri = Uri.parse(
        '$_base${AppConstants.adminEndpoint}/restaurants/$restaurantId/menu/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders..remove('Content-Type'));
    request.fields['mode'] = mode;
    request.fields['extraction_method'] = extractionMethod;

    final ext = imageFile.name.split('.').last.toLowerCase();
    final contentType = ext == 'pdf'
        ? MediaType('application', 'pdf')
        : MediaType('image', ext == 'jpg' ? 'jpeg' : ext);

    final bytes = await imageFile.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: imageFile.name,
      contentType: contentType,
    ));

    final streamedResponse =
        await request.send().timeout(const Duration(minutes: 5));
    final response = await http.Response.fromStream(streamedResponse);
    return _handle(response) as Map<String, dynamic>;
  }

  /// DELETE /admin/restaurants/{id}/menu/clear — Wipe all menu data.
  Future<Map<String, dynamic>> clearAdminMenu(String restaurantId) async {
    final uri = Uri.parse(
        '$_base${AppConstants.adminEndpoint}/restaurants/$restaurantId/menu/clear');
    final response =
        await _client.delete(uri, headers: _authHeaders).timeout(_timeout);
    return _handle(response) as Map<String, dynamic>;
  }

  /// DELETE /admin/restaurants/{id}/bookings — Clear all bookings.
  Future<Map<String, dynamic>> clearAdminBookings(String restaurantId) async {
    final uri = Uri.parse(
        '$_base/bookings/admin/restaurants/$restaurantId/bookings');
    final response =
        await _client.delete(uri, headers: _authHeaders).timeout(_timeout);
    return _handle(response) as Map<String, dynamic>;
  }

  /// DELETE /admin/restaurants/{id}/orders — Clear all orders.
  Future<Map<String, dynamic>> clearAdminOrders(String restaurantId) async {
    final uri = Uri.parse(
        '$_base/orders/admin/restaurants/$restaurantId/orders');
    final response =
        await _client.delete(uri, headers: _authHeaders).timeout(_timeout);
    return _handle(response) as Map<String, dynamic>;
  }

  /// PUT /restaurants/{id} — Update restaurant profile (name, phone, address, etc.)
  Future<Map<String, dynamic>> updateRestaurant(
    String restaurantId,
    Map<String, dynamic> updates,
  ) async {
    final data = await _put(
      '${AppConstants.restaurantsEndpoint}/$restaurantId',
      updates,
    );
    return data as Map<String, dynamic>;
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
