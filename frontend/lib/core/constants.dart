
class AppConstants {
  // ── API ─────────────────────────────────────────────────────────────────────
  static const String _renderBase = 'https://eatbot-lifa.onrender.com/api/v1';

  static String get baseUrl => _renderBase;

  // ── API Endpoints ────────────────────────────────────────────────────────────
  static const String chatEndpoint          = '/chat';
  static const String areasEndpoint         = '/areas';
  static const String restaurantsEndpoint   = '/restaurants';
  static const String menusUploadEndpoint   = '/menus/upload';
  static const String menusUploadsEndpoint  = '/menus/uploads';

  // ── Voice AI Endpoints ───────────────────────────────────────────────────────
  static const String voiceChatEndpoint     = '/voice/chat';
  static const String voiceSessionEndpoint  = '/voice/session';

  // ── Dine-In Booking Endpoints ─────────────────────────────────────────────
  static const String dineCheckEndpoint    = '/dine/check-availability';
  static const String dineConfirmEndpoint  = '/dine/confirm-booking';

  // ── Admin Endpoints ──────────────────────────────────────────────────────────
  static const String adminLoginEndpoint   = '/auth/admin-login';
  static const String adminEndpoint        = '/admin';

  // ── Timeouts ────────────────────────────────────────────────────────────────
  static const int connectTimeoutSeconds  = 15;
  static const int receiveTimeoutSeconds  = 60;  // RAG can take a moment

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
