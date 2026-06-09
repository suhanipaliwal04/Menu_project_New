import 'package:flutter/material.dart';
import '../core/api_service.dart';

enum LocationStateStatus { idle, loading, success, error }

class LocationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  LocationStateStatus _stateStatus = LocationStateStatus.idle;
  LocationStateStatus get stateStatus => _stateStatus;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<dynamic> _states = [];
  List<dynamic> get states => _states;

  List<dynamic> _cities = [];
  List<dynamic> get cities => _cities;

  Future<void> fetchStates() async {
    _stateStatus = LocationStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _states = await _api.getStates();
      _stateStatus = LocationStateStatus.success;
    } catch (e) {
      _stateStatus = LocationStateStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> fetchCities(String stateName) async {
    _stateStatus = LocationStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _cities = await _api.getCities(stateName);
      _stateStatus = LocationStateStatus.success;
    } catch (e) {
      _stateStatus = LocationStateStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> createState(String stateName) async {
    try {
      await _api.createState(stateName);
      await fetchStates();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createCity(String cityName, String stateId) async {
    try {
      await _api.createCity(cityName, stateId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearCities() {
    _cities = [];
    notifyListeners();
  }
}
