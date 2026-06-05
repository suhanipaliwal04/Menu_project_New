import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/chat_models.dart';
import '../providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'health_badge.dart';
import 'veg_indicator.dart';

class FoodItemCard extends StatelessWidget {
  final ChatMenuItem item;
  final int index;
  final VoidCallback? onTap;

  const FoodItemCard({
    super.key,
    required this.item,
    this.index = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              VegIndicator(isVeg: item.isVeg),
                              const SizedBox(width: 8),
                              if (item.similarity != null && item.similarity! > 0.8)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGlow,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('BEST MATCH', 
                                    style: GoogleFonts.outfit(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w800)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.itemName,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.restaurantName,
                            style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                item.priceDisplay,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              if (item.healthScore != null)
                                HealthBadge(score: item.healthScore),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildImagePlaceholder(),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildImagePlaceholder() {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?q=80&w=200'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          child: GestureDetector(
            onTap: () {
              if (item.restaurantId != null) {
                context.read<CartProvider>().addItem(
                  id: item.itemId ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: item.itemName,
                  price: double.tryParse(item.priceDisplay.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
                  restaurantName: item.restaurantName,
                  restaurantId: item.restaurantId!,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.itemName} added to cart!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text('ADD', style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }

}
