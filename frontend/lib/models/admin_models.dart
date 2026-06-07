/// Data models for the Admin Dashboard — corresponds to backend admin schemas.
library;

class DashboardStats {
  final String restaurantId;
  final String restaurantName;
  final String areaName;
  final String city;
  final bool isActive;
  final int totalSections;
  final int totalItems;
  final int totalUploads;
  final double? avgPrice;
  final int vegItems;
  final int nonVegItems;
  final int totalBookings;
  final int pendingBookings;
  final DateTime? createdAt;

  const DashboardStats({
    required this.restaurantId,
    required this.restaurantName,
    required this.areaName,
    required this.city,
    required this.isActive,
    required this.totalSections,
    required this.totalItems,
    required this.totalUploads,
    this.avgPrice,
    required this.vegItems,
    required this.nonVegItems,
    this.totalBookings = 0,
    this.pendingBookings = 0,
    this.createdAt,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        restaurantId: j['restaurant_id']?.toString() ?? '',
        restaurantName: j['restaurant_name'] as String? ?? '',
        areaName: j['area_name'] as String? ?? '',
        city: j['city'] as String? ?? '',
        isActive: j['is_active'] as bool? ?? true,
        totalSections: j['total_sections'] as int? ?? 0,
        totalItems: j['total_items'] as int? ?? 0,
        totalUploads: j['total_uploads'] as int? ?? 0,
        avgPrice: (j['avg_price'] as num?)?.toDouble(),
        vegItems: j['veg_items'] as int? ?? 0,
        nonVegItems: j['non_veg_items'] as int? ?? 0,
        totalBookings: j['total_bookings'] as int? ?? 0,
        pendingBookings: j['pending_bookings'] as int? ?? 0,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
      );

  double get vegPercent =>
      totalItems == 0 ? 0.0 : (vegItems / totalItems).clamp(0.0, 1.0);
}


class AdminMenuItem {
  final String itemId;
  final String itemName;
  final String sectionName;
  final double price;
  final bool isVeg;
  final bool isAvailable;
  final String? description;
  final int? calories;
  final int? healthScore;
  final String? healthLabel;
  final List<String>? tags;

  const AdminMenuItem({
    required this.itemId,
    required this.itemName,
    required this.sectionName,
    required this.price,
    required this.isVeg,
    required this.isAvailable,
    this.description,
    this.calories,
    this.healthScore,
    this.healthLabel,
    this.tags,
  });

  factory AdminMenuItem.fromJson(Map<String, dynamic> j) => AdminMenuItem(
        itemId: j['item_id']?.toString() ?? '',
        itemName: j['item_name'] as String? ?? '',
        sectionName: j['section_name'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0.0,
        isVeg: j['is_veg'] as bool? ?? true,
        isAvailable: j['is_available'] as bool? ?? true,
        description: j['description'] as String?,
        calories: j['calories'] as int?,
        healthScore: j['health_score'] as int?,
        healthLabel: j['health_label'] as String?,
        tags: (j['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      );

  AdminMenuItem copyWith({
    String? itemName,
    String? sectionName,
    double? price,
    bool? isVeg,
    bool? isAvailable,
    String? description,
    int? calories,
  }) {
    return AdminMenuItem(
      itemId: itemId,
      itemName: itemName ?? this.itemName,
      sectionName: sectionName ?? this.sectionName,
      price: price ?? this.price,
      isVeg: isVeg ?? this.isVeg,
      isAvailable: isAvailable ?? this.isAvailable,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      healthScore: healthScore,
      healthLabel: healthLabel,
      tags: tags,
    );
  }
}


class MenuSectionInfo {
  final String sectionId;
  final String sectionName;
  final int itemCount;

  const MenuSectionInfo({
    required this.sectionId,
    required this.sectionName,
    required this.itemCount,
  });

  factory MenuSectionInfo.fromJson(Map<String, dynamic> j) => MenuSectionInfo(
        sectionId: j['section_id']?.toString() ?? '',
        sectionName: j['section_name'] as String? ?? '',
        itemCount: j['item_count'] as int? ?? 0,
      );
}


class UploadHistoryItem {
  final String uploadId;
  final DateTime timestamp;
  final int itemsExtracted;
  final String status;
  final String mode;

  const UploadHistoryItem({
    required this.uploadId,
    required this.timestamp,
    required this.itemsExtracted,
    required this.status,
    this.mode = 'replace',
  });
}

class BookingModel {
  final String bookingId;
  final String restaurantId;
  final int partySize;
  final String timeSlot;
  final String status;
  final String? customerName;
  final String? customerPhone;
  final DateTime? createdAt;

  const BookingModel({
    required this.bookingId,
    required this.restaurantId,
    required this.partySize,
    required this.timeSlot,
    required this.status,
    this.customerName,
    this.customerPhone,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> j) => BookingModel(
        bookingId: j['booking_id']?.toString() ?? '',
        restaurantId: j['restaurant_id']?.toString() ?? '',
        partySize: j['party_size'] as int? ?? 0,
        timeSlot: j['time_slot'] as String? ?? '',
        status: j['status'] as String? ?? 'PENDING',
        customerName: j['customer_name'] as String?,
        customerPhone: j['customer_phone'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
      );
}

class OrderItemModel {
  final String orderItemId;
  final String orderId;
  final String itemName;
  final int quantity;
  final double price;

  const OrderItemModel({
    required this.orderItemId,
    required this.orderId,
    required this.itemName,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> j) => OrderItemModel(
        orderItemId: j['order_item_id']?.toString() ?? '',
        orderId: j['order_id']?.toString() ?? '',
        itemName: j['item_name']?.toString() ?? '',
        quantity: j['quantity'] as int? ?? 1,
        price: (j['price'] as num?)?.toDouble() ?? 0.0,
      );
}

class OrderModel {
  final String orderId;
  final String restaurantId;
  final String customerName;
  final String customerPhone;
  final String timeSlot;
  final double totalAmount;
  final String status;
  final DateTime? createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.orderId,
    required this.restaurantId,
    required this.customerName,
    required this.customerPhone,
    required this.timeSlot,
    required this.totalAmount,
    required this.status,
    this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    var itemsList = j['items'] as List<dynamic>? ?? [];
    return OrderModel(
      orderId: j['order_id']?.toString() ?? '',
      restaurantId: j['restaurant_id']?.toString() ?? '',
      customerName: j['customer_name']?.toString() ?? '',
      customerPhone: j['customer_phone']?.toString() ?? '',
      timeSlot: j['time_slot']?.toString() ?? '',
      totalAmount: (j['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: j['status']?.toString() ?? 'PENDING',
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null,
      items: itemsList.map((i) => OrderItemModel.fromJson(i)).toList(),
    );
  }
}
