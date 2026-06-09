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
  static const _fullNameKey = 'full_name';
  static const _phoneKey = 'phone_number';
  static const _stateKey = 'state';
  static const _cityKey = 'city';

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

  String? _fullName;
  String? get fullName => _fullName;

  String? _phone;
  String? get phone => _phone;

  String? _userState;
  String? get userState => _userState;

  String? _city;
  String? get city => _city;

  /// Restores session on app startup
  Future<void> init() async {
    final token = await _storage.read(key: _tokenKey);
    final uid = await _storage.read(key: _userIdKey);
    final r = await _storage.read(key: _roleKey);
    
    _fullName = await _storage.read(key: _fullNameKey);
    _phone = await _storage.read(key: _phoneKey);
    _userState = await _storage.read(key: _stateKey);
    _city = await _storage.read(key: _cityKey);

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

      // Fetch user profile to get city, state, etc.
      try {
        final me = await _api.getMe();
        _fullName = me['full_name'];
        _phone = me['phone_number'];
        _userState = me['state'];
        _city = me['city'];
        
        if (_fullName != null) await _storage.write(key: _fullNameKey, value: _fullName);
        if (_phone != null) await _storage.write(key: _phoneKey, value: _phone);
        if (_userState != null) await _storage.write(key: _stateKey, value: _userState);
        if (_city != null) await _storage.write(key: _cityKey, value: _city);
      } catch (e) {
        debugPrint('Failed to fetch user profile during login: $e');
      }

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

  Future<bool> register(String email, String password, String roleParam, String fullName, String phone, String state, String city) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.register(email, password, roleParam, fullName, phone, state, city);
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

  Future<bool> updateProfile(String fullName, String phone, String state, String city) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.updateMe({
        'full_name': fullName,
        'phone_number': phone,
        'state': state,
        'city': city,
      });

      _fullName = res['full_name'];
      _phone = res['phone_number'];
      _userState = res['state'];
      _city = res['city'];

      if (_fullName != null) await _storage.write(key: _fullNameKey, value: _fullName);
      if (_phone != null) await _storage.write(key: _phoneKey, value: _phone);
      if (_userState != null) await _storage.write(key: _stateKey, value: _userState);
      if (_city != null) await _storage.write(key: _cityKey, value: _city);

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
    await _storage.delete(key: _fullNameKey);
    await _storage.delete(key: _phoneKey);
    await _storage.delete(key: _stateKey);
    await _storage.delete(key: _cityKey);
    
    _api.setAuthToken(null);
    _userId = null;
    _role = null;
    _fullName = null;
    _phone = null;
    _userState = null;
    _city = null;
    _isLoggedIn = false;
    
    notifyListeners();
  }
}
