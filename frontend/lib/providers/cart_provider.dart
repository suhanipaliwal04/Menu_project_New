import 'package:flutter/foundation.dart';
import '../core/api_service.dart';

/// A single item in the cart.
class CartItem {
  final String id;
  final String name;
  final double price;
  final String restaurantName;
  final String restaurantId;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.restaurantName,
    required this.restaurantId,
    this.quantity = 1,
  });
}

/// Supported payment methods.
enum PaymentMethod { cashOnDelivery, upi, card }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cashOnDelivery: return 'Cash on Delivery';
      case PaymentMethod.upi:            return 'UPI / GPay';
      case PaymentMethod.card:           return 'Credit / Debit Card';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.cashOnDelivery: return '💵';
      case PaymentMethod.upi:            return '📲';
      case PaymentMethod.card:           return '💳';
    }
  }
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  bool _orderPlaced = false;
  String? _lastOrderId;
  String _orderType = 'Takeaway';

  List<CartItem> get items => List.unmodifiable(_items);
  PaymentMethod get paymentMethod => _paymentMethod;
  bool get orderPlaced => _orderPlaced;
  String? get lastOrderId => _lastOrderId;
  String get orderType => _orderType;
  int get totalItems => _items.fold(0, (sum, i) => sum + i.quantity);
  double get totalPrice => _items.fold(0, (sum, i) => sum + i.price * i.quantity);

  void setOrderType(String type) {
    _orderType = type;
    if (type.toLowerCase() == 'takeaway') {
      _paymentMethod = PaymentMethod.cashOnDelivery;
    }
    notifyListeners();
  }

  // ── Cart Operations ───────────────────────────────────────────────────────

  void addItem({
    required String id,
    required String name,
    required double price,
    required String restaurantName,
    required String restaurantId,
  }) {
    final existing = _items.where((i) => i.id == id).firstOrNull;
    if (existing != null) {
      existing.quantity++;
    } else {
      _items.add(CartItem(
        id: id,
        name: name,
        price: price,
        restaurantName: restaurantName,
        restaurantId: restaurantId,
      ));
    }
    notifyListeners();
  }

  /// Add by voice — name-only match (fuzzy: toLowerCase, trim).
  CartItem? addItemByName({
    required String name,
    required String restaurantName,
    required String restaurantId,
    double price = 0.0,
  }) {
    // Try to find an existing entry for the same name
    final normalised = name.toLowerCase().trim();
    final existing = _items.where(
      (i) => i.name.toLowerCase().trim() == normalised,
    ).firstOrNull;

    if (existing != null) {
      existing.quantity++;
      notifyListeners();
      return existing;
    }

    final item = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      price: price,
      restaurantName: restaurantName,
      restaurantId: restaurantId,
    );
    _items.add(item);
    notifyListeners();
    return item;
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void decrementItem(String id) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item == null) return;
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setPaymentMethodFromString(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('cash') || lower.contains('cod')) {
      _paymentMethod = PaymentMethod.cashOnDelivery;
    } else if (lower.contains('upi') || lower.contains('gpay')) {
      _paymentMethod = PaymentMethod.upi;
    } else if (lower.contains('card')) {
      _paymentMethod = PaymentMethod.card;
    }
    notifyListeners();
  }

  // ── Order Flow ────────────────────────────────────────────────────────────

  Future<void> placeOrder({String? customerName, String? customerPhone, String? timeSlot}) async {
    if (_items.isEmpty) return;
    
    if (_orderType.toLowerCase() == 'takeaway') {
      try {
        final res = await ApiService().createTakeawayOrder(
          restaurantId: _items.first.restaurantId,
          customerName: customerName ?? 'Guest',
          customerPhone: customerPhone ?? 'Unknown',
          timeSlot: timeSlot ?? 'ASAP',
          totalAmount: totalPrice * 1.05,
          items: _items.map((i) => {
             'item_name': i.name,
             'quantity': i.quantity,
             'price': i.price,
          }).toList(),
        );
        _lastOrderId = res['order_id'] ?? 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      } catch (e) {
        debugPrint('Failed to place order: $e');
        _lastOrderId = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      }
    } else {
      _lastOrderId = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }

    _orderPlaced = true;
    notifyListeners();
  }

  void resetOrder() {
    _items.clear();
    _orderPlaced = false;
    _lastOrderId = null;
    _paymentMethod = PaymentMethod.cashOnDelivery;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
