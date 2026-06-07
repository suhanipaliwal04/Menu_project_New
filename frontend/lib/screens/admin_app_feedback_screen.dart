import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/reviews_provider.dart';

class AdminAppFeedbackScreen extends StatefulWidget {
  const AdminAppFeedbackScreen({super.key});

  @override
  State<AdminAppFeedbackScreen> createState() => _AdminAppFeedbackScreenState();
}

class _AdminAppFeedbackScreenState extends State<AdminAppFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewsProvider>().fetchAppReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('App Feedback', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error),
            tooltip: 'Clear All Reviews',
            onPressed: () async {
              await context.read<ReviewsProvider>().clearAppReviews();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ReviewsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final reviews = provider.appReviews;

          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.feedback_rounded, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text('No Feedback Yet', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Customer feedback about the app will appear here.', style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(review.customerName ?? 'Customer', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(review.rating.toStringAsFixed(1), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(review.createdAt.toIso8601String().split('T').first, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
                    if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(review.reviewText!, style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
