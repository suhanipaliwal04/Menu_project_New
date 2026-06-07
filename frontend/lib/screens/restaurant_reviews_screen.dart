import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/api_service.dart';

class RestaurantReviewsScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantReviewsScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<RestaurantReviewsScreen> createState() => _RestaurantReviewsScreenState();
}

class _RestaurantReviewsScreenState extends State<RestaurantReviewsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService().getRestaurantReviews(widget.restaurantId);
      setState(() {
        _reviews = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reviews for ${widget.restaurantName}',
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load reviews',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.outfit(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchReviews,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review ${widget.restaurantName}!',
              style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
        final reviewText = review['review_text'] as String?;
        final customerName = review['customer_name'] as String? ?? 'Anonymous';
        final createdAtStr = review['created_at'] as String?;
        String dateFormatted = '';
        if (createdAtStr != null) {
          try {
            final dt = DateTime.parse(createdAtStr).toLocal();
            dateFormatted = '${dt.day}/${dt.month}/${dt.year}';
          } catch (_) {}
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    customerName,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
                  ),
                  if (dateFormatted.isNotEmpty)
                    Text(
                      dateFormatted,
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (starIndex) {
                  return Icon(
                    starIndex < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppTheme.accent,
                    size: 18,
                  );
                }),
              ),
              if (reviewText != null && reviewText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  reviewText,
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14, height: 1.4),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
