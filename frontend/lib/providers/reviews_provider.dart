import 'package:flutter/foundation.dart';
import '../core/api_service.dart';

class ReviewModel {
  final String reviewId;
  final String? restaurantId;
  final double rating;
  final String? reviewText;
  final String? customerName;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    this.restaurantId,
    required this.rating,
    this.reviewText,
    this.customerName,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['review_id'],
      restaurantId: json['restaurant_id'],
      rating: (json['rating'] as num).toDouble(),
      reviewText: json['review_text'],
      customerName: json['customer_name'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}

class ReviewsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ReviewModel> _restaurantReviews = [];
  List<ReviewModel> get restaurantReviews => _restaurantReviews;

  List<ReviewModel> _appReviews = [];
  List<ReviewModel> get appReviews => _appReviews;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchRestaurantReviews(String restaurantId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get('reviews/restaurant/$restaurantId');
      _restaurantReviews = (res as List).map((r) => ReviewModel.fromJson(r)).toList();
    } catch (e) {
      debugPrint('Error fetching restaurant reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitRestaurantReview({
    required String restaurantId,
    required double rating,
    required String reviewText,
    required String customerName,
  }) async {
    try {
      await _api.post('reviews/restaurant', {
        'restaurant_id': restaurantId,
        'rating': rating,
        'review_text': reviewText,
        'customer_name': customerName,
      });
      // Optionally re-fetch after submitting
      await fetchRestaurantReviews(restaurantId);
      return true;
    } catch (e) {
      debugPrint('Error submitting restaurant review: $e');
      return false;
    }
  }

  Future<void> fetchAppReviews() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get('reviews/app');
      _appReviews = (res as List).map((r) => ReviewModel.fromJson(r)).toList();
    } catch (e) {
      debugPrint('Error fetching app reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitAppReview({
    required double rating,
    required String reviewText,
    required String customerName,
  }) async {
    try {
      await _api.post('reviews/app', {
        'rating': rating,
        'review_text': reviewText,
        'customer_name': customerName,
      });
      return true;
    } catch (e) {
      debugPrint('Error submitting app review: $e');
      return false;
    }
  }
}
