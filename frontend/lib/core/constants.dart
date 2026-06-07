class AppConstants {
  // ── API ─────────────────────────────────────────────────────────────────────
  Searched for "Phone Number"
Viewed table_booking_screen.dart:350-400
Searched for "prefixText"
Edited table_booking_screen.dart
Searched for "VoiceCartFab"
Searched for "floatingActionButton"
Viewed home_screen.dart:430-500
Edited home_screen.dart
Ran command: `flutter analyze`
Used tool: manage_task
Viewed home_screen.dart:430-500
Edited home_screen.dart
Viewed home_screen.dart:435-520
Ran command: `flutter analyze`
Used tool: manage_task
Used tool: schedule
Edited category_results_screen.dart
Ran command: `git restore frontend\lib\screens\category_results_screen.dart`
Viewed category_results_screen.dart:30-100
Edited category_results_screen.dart
Viewed results_screen.dart:50-110
Edited results_screen.dart
Viewed restaurant_detail_screen.dart:60-115
Edited restaurant_detail_screen.dart
Viewed customer_bookings_provider.dart:1-60
Searched for "addOrderId"
Viewed cart_provider.dart:120-165
Viewed cart_provider.dart:165-200
Searched for "addOrderId"
Viewed customer_bookings_provider.dart:90-120
Viewed orders.py:100-140
Viewed orders.py:15-50
Viewed orders.py:130-160
Searched for "createTakeawayOrder"
Viewed api_service.dart:375-410
Searched for "ordersTakeawayEndpoint"
Viewed cart_screen.dart:400-450
Viewed cart_screen.dart:440-480
Viewed cart_screen.dart:60-100
Viewed api_service.dart:400-440
Searched for "getCustomerOrders"
Viewed api_service.dart:350-380
Ran command: `type schema.sql`
Used tool: manage_task
Viewed my_bookings_screen.dart:90-140
Viewed my_bookings_screen.dart:1-60
Viewed main.py:1-137
Ran command: `python -c "from app.core.database import SessionLocal; from sqlalchemy import text; db = SessionLocal(); print(db.execute(text('SELECT table_name FROM information_schema.tables WHERE table_schema=\'public\'')).fetchall())"`
Edited main.py
Read URL: http://127.0.0.1:8000/run-migration
// Ran command: `Invoke-WebRequest -Uri "http://127.0.0.1:8000/run-migration" -UseBasicParsing` static const String _renderBase = 'http://127.0.0.1:8000/api/v1';
    static const String _renderBase = 'https://eatbot-lifa.onrender.com/api/v1';

  static String get baseUrl => _renderBase;

  // ── API Endpoints ────────────────────────────────────────────────────────────
  static const String chatEndpoint = '/chat';
  static const String areasEndpoint = '/areas';
  static const String restaurantsEndpoint = '/restaurants';
  static const String menusUploadEndpoint = '/menus/upload';
  static const String menusUploadsEndpoint = '/menus/uploads';

  // ── Voice AI Endpoints ───────────────────────────────────────────────────────
  static const String voiceChatEndpoint = '/voice/chat';
  static const String voiceSessionEndpoint = '/voice/session';

  // ── Dine-In Booking Endpoints ─────────────────────────────────────────────
  static const String dineCheckEndpoint = '/dine/check-availability';
  static const String dineConfirmEndpoint = '/dine/confirm-booking';

  // ── Orders (Takeaway) Endpoints ──────────────────────────────────────────────
  static const String ordersTakeawayEndpoint = '/orders/takeaway';
  static const String adminOrdersEndpoint    = '/orders/admin/restaurants';
  
  // ── Admin Endpoints ──────────────────────────────────────────────────────────
  static const String authLoginEndpoint = '/auth/login';
  static const String authRegisterEndpoint = '/auth/register';
  static const String adminEndpoint = '/admin';

  // ── Timeouts ────────────────────────────────────────────────────────────────
  static const int connectTimeoutSeconds = 15;
  static const int receiveTimeoutSeconds = 60; // RAG can take a moment

  // ── UI Constants ─────────────────────────────────────────────────────────────
  static const List<Map<String, String>> quickChips = [
    {'emoji': '🥗', 'label': 'Healthy'},
    {'emoji': '🍬', 'label': 'Sweet'},
    {'emoji': '🌶️', 'label': 'Spicy'},
    {'emoji': '💰', 'label': 'Budget'},
    {'emoji': '🥦', 'label': 'Veg only'},
    {'emoji': '🍗', 'label': 'Non-veg'},
  ];
}
