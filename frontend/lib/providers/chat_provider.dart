import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/chat_models.dart';

enum ChatState { idle, loading, success, error }

class ChatProvider extends ChangeNotifier {
  ChatState _state = ChatState.idle;
  ChatResponse? _response;
  String? _errorMessage;
  String _lastQuery = '';
  String _lastArea = '';

  // Sorting/filtering state
  bool _vegOnly = false;
  String _sortBy = 'relevance';

  ChatState get state => _state;
  ChatResponse? get response => _response;
  String? get errorMessage => _errorMessage;
  String get lastQuery => _lastQuery;
  String get lastArea => _lastArea;
  bool get vegOnly => _vegOnly;
  String get sortBy => _sortBy;

  List<ChatMenuItem> get displayItems {
    if (_response == null) return [];
    var items = List<ChatMenuItem>.from(_response!.items);

    if (_vegOnly) {
      items = items.where((i) => i.isVeg == true).toList();
    }

    switch (_sortBy) {
      case 'price_asc':
        items.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      case 'price_desc':
        items.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'health':
        items.sort((a, b) => (b.healthScore ?? 0).compareTo(a.healthScore ?? 0));
        break;
      default:
        // Keep original (relevance/similarity order from backend)
        break;
    }

    return items;
  }

  Future<void> search({
    required String query,
    required String areaName,
    String? restaurantId,
    double? userLat,
    double? userLng,
  }) async {
    _state = ChatState.loading;
    _errorMessage = null;
    _lastQuery = query;
    _lastArea = areaName;
    _vegOnly = false;
    _sortBy = 'relevance';
    notifyListeners();

    try {
      _response = await ApiService().chat(
        query: query,
        areaName: areaName,
        restaurantId: restaurantId,
        userLat: userLat,
        userLng: userLng,
      );
      _state = ChatState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ChatState.error;
    } catch (e, st) {
      debugPrint('Chat error: $e\\n$st');
      _errorMessage = 'Could not connect to server or parsing failed. ($e)';
      _state = ChatState.error;
    }

    notifyListeners();
  }

  void setVegOnly(bool value) {
    _vegOnly = value;
    notifyListeners();
  }

  void setSortBy(String value) {
    _sortBy = value;
    notifyListeners();
  }

  void reset() {
    _state = ChatState.idle;
    _response = null;
    _errorMessage = null;
    notifyListeners();
  }
}
