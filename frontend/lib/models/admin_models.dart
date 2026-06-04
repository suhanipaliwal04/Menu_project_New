/// Data models for the Admin Dashboard — corresponds to backend admin schemas.

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
