import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/customer_bookings_provider.dart';
import '../providers/reviews_provider.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We already load bookings when app starts, but let's refresh to be sure
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerBookingsProvider>().loadBookings();
    });

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Bookings', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_rate_rounded, color: Colors.orange),
            tooltip: 'Rate the App',
            onPressed: () {
              _showAppRatingDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error),
            tooltip: 'Clear All Bookings',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Clear All Bookings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  content: Text('Are you sure you want to clear all your bookings history from this device?', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      onPressed: () {
                        context.read<CustomerBookingsProvider>().clearAll();
                        Navigator.pop(context);
                      },
                      child: Text('Clear All', style: GoogleFonts.outfit(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CustomerBookingsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load bookings', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 16)),
                  Text(provider.error!, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadBookings(),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final bookings = provider.bookings;
          final orders = provider.orders;
          final allItems = [...bookings, ...orders];

          if (allItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text('No Bookings Yet', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Your table reservations and takeaway orders will appear here.', style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary)),
                ],
              ),
            ).animate().fadeIn();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final item = allItems[index];
              final isTakeaway = item.containsKey('order_id');
              final status = item['status'] as String;
              final color = status == 'CONFIRMED' ? AppTheme.success : (status == 'REJECTED' ? AppTheme.error : AppTheme.primary);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                        Expanded(
                          child: Text(
                            isTakeaway ? 'Takeaway Order' : (item['restaurant_name'] ?? 'Restaurant'),
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(status, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(isTakeaway ? Icons.shopping_bag_rounded : Icons.people_alt_rounded, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(isTakeaway ? 'Takeaway' : '${item['party_size']} Guests', style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(isTakeaway ? 'Time Slot: ${item['time_slot']}' : '${item['booking_date']} at ${item['time_slot']}', style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary)),
                      ],
                    ),
                    if (status == 'CONFIRMED' && isTakeaway) ...[
                       const SizedBox(height: 8),
                       Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                         child: Row(
                           children: [
                             const Icon(Icons.mark_email_read_rounded, size: 16, color: AppTheme.success),
                             const SizedBox(width: 8),
                             Expanded(child: Text('Message: "thanks for placing the order"', style: GoogleFonts.outfit(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold))),
                           ],
                         ),
                       ),
                    ],
                    if (status == 'CONFIRMED' && !isTakeaway) ...[
                       const SizedBox(height: 8),
                       Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                         child: Row(
                           children: [
                             const Icon(Icons.mark_email_read_rounded, size: 16, color: AppTheme.success),
                             const SizedBox(width: 8),
                             Expanded(child: Text('Message: "your table has been reserved successfully"', style: GoogleFonts.outfit(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold))),
                           ],
                         ),
                       ),
                    ],
                    if (status == 'REJECTED' && isTakeaway) ...[
                       const SizedBox(height: 8),
                       Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                         child: Row(
                           children: [
                             const Icon(Icons.cancel_presentation_rounded, size: 16, color: AppTheme.error),
                             const SizedBox(width: 8),
                             Expanded(child: Text('Message: "sorry restaurant is not currently accepting any order"', style: GoogleFonts.outfit(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.bold))),
                           ],
                         ),
                       ),
                    ],
                    const Divider(height: 24, color: AppTheme.divider),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ID: ${isTakeaway ? item['order_id'].toString().substring(0, 8) : item['booking_id'].toString().substring(0, 8)}', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
                        if (status == 'CONFIRMED')
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  _showRatingDialog(
                                    context, 
                                    item['restaurant_id'], 
                                    item['restaurant_name'] ?? 'Restaurant',
                                    item['customer_name'] ?? 'Customer'
                                  );
                                },
                                icon: const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                                label: Text('Rate', style: GoogleFonts.outfit(color: Colors.orange, fontWeight: FontWeight.bold)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.success),
                              const SizedBox(width: 4),
                              Text(isTakeaway ? 'Order Accepted' : 'Table Reserved', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.bold)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String restaurantId, String restaurantName, String customerName) {
    double selectedRating = 0.0;
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Rate $restaurantName', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.orange,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedRating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textCtrl,
                  maxLines: 3,
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Write your review here (optional)...',
                    hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final provider = context.read<ReviewsProvider>();
                  final success = await provider.submitRestaurantReview(
                    restaurantId: restaurantId,
                    rating: selectedRating,
                    reviewText: textCtrl.text.trim(),
                    customerName: customerName,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Review submitted successfully!' : 'Failed to submit review.', style: GoogleFonts.outfit()),
                        backgroundColor: success ? AppTheme.success : AppTheme.error,
                      ),
                    );
                  }
                },
                child: Text('Submit', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showAppRatingDialog(BuildContext context) {
    double selectedRating = 0.0;
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Rate Menu Intelligence', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.orange,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedRating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textCtrl,
                  maxLines: 3,
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'What do you think about our app?',
                    hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final provider = context.read<ReviewsProvider>();
                  final success = await provider.submitAppReview(
                    rating: selectedRating,
                    reviewText: textCtrl.text.trim(),
                    customerName: 'Customer',
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Thank you for your feedback!' : 'Failed to submit review.', style: GoogleFonts.outfit()),
                        backgroundColor: success ? AppTheme.success : AppTheme.error,
                      ),
                    );
                  }
                },
                child: Text('Submit', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }
}
