import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_service.dart';

enum AuthState { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _roleKey = 'user_role';

  AuthState _state = AuthState.idle;
  AuthState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _userId;
  String? get userId => _userId;

  String? _role;
  String? get role => _role;

  /// Restores session on app startup
  Future<void> init() async {
    final token = await _storage.read(key: _tokenKey);
    final uid = await _storage.read(key: _userIdKey);
    final r = await _storage.read(key: _roleKey);

    if (token != null && uid != null && r != null) {
      _api.setAuthToken(token);
      _userId = uid;
      _role = r;
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password, String expectedRole) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.login(email, password, expectedRole);
      
      final token = res['access_token'];
      final uid = res['user_id'];
      final r = res['role'];

      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userIdKey, value: uid);
      await _storage.write(key: _roleKey, value: r);

      _api.setAuthToken(token);
      _userId = uid;
      _role = r;
      _isLoggedIn = true;

      _state = AuthState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String roleParam) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.register(email, password, roleParam);
      _state = AuthState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _roleKey);
    
    _api.setAuthToken(null);
    _userId = null;
    _role = null;
    _isLoggedIn = false;
    
    notifyListeners();
  }
}
