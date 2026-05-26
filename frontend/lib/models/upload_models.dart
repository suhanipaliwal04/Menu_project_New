/// Response from POST /menus/upload
class UploadResult {
  final String uploadId;
  final String status;
  final String message;
  final String? restaurantName;
  final String? restaurantId;
  final int? itemsCount;
  final int? embeddedCount;

  const UploadResult({
    required this.uploadId,
    required this.status,
    required this.message,
    this.restaurantName,
    this.restaurantId,
    this.itemsCount,
    this.embeddedCount,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) => UploadResult(
        uploadId: json['upload_id']?.toString() ?? '',
        status: json['status'] ?? '',
        message: json['message'] ?? '',
        restaurantName: json['restaurant_name'],
        restaurantId: json['restaurant_id']?.toString(),
        itemsCount: (json['items_count'] as num?)?.toInt(),
        embeddedCount: (json['embedded_count'] as num?)?.toInt(),
      );

  bool get isSuccess => status == 'completed';
}

/// Response from GET /menus/uploads/{id}
class UploadStatus {
  final String uploadId;
  final String status;
  final String? restaurantId;
  final String imagePath;
  final String? errorMessage;
  final String uploadedAt;
  final String? processedAt;
  final int? itemsCount;

  const UploadStatus({
    required this.uploadId,
    required this.status,
    this.restaurantId,
    required this.imagePath,
    this.errorMessage,
    required this.uploadedAt,
    this.processedAt,
    this.itemsCount,
  });

  factory UploadStatus.fromJson(Map<String, dynamic> json) => UploadStatus(
        uploadId: json['upload_id']?.toString() ?? '',
        status: json['ocr_status'] ?? json['status'] ?? '',
        restaurantId: json['restaurant_id']?.toString(),
        imagePath: json['image_path'] ?? '',
        errorMessage: json['error_message'],
        uploadedAt: json['uploaded_at'] ?? '',
        processedAt: json['processed_at'],
        itemsCount: (json['items_count'] as num?)?.toInt(),
      );

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing';
}
