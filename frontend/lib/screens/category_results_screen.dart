import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/browse_provider.dart';
import '../models/restaurant_model.dart';
import '../widgets/voice_fab.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'restaurant_detail_screen.dart';

class CategoryResultsScreen extends StatelessWidget {
  final String categoryName;

  const CategoryResultsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$categoryName Options',
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const VoiceFab(),
            if (categoryName != 'Dine In') ...[
              const SizedBox(width: 16),
              Consumer<CartProvider>(
                builder: (context, cart, _) {
                  return FloatingActionButton(
                    heroTag: 'cart_fab_category',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                    backgroundColor: AppTheme.surfaceAlt,
                    elevation: 4,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: AppTheme.textPrimary, size: 26),
                        if (cart.items.isNotEmpty)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cart.items.length}',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
            if (categoryName != 'Takeaway') ...[
              const SizedBox(width: 16),
              FloatingActionButton.extended(
                heroTag: 'book_table_category',
                onPressed: () {
                  context.read<BrowseProvider>().loadRestaurants(orderType: 'Dine In');
                  context.read<CartProvider>().setOrderType('Dine In');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryResultsScreen(categoryName: 'Dine In'),
                    ),
                  );
                },
                backgroundColor: AppTheme.primary,
                elevation: 4,
                icon: const Icon(Icons.deck_rounded, color: Colors.white),
                label: Text('Book a Table', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Consumer<BrowseProvider>(
        builder: (context, provider, _) {
          if (provider.restaurantsState == BrowseState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.restaurants.isEmpty) {
            return Center(child: Text(provider.errorMessage!));
          }

          if (provider.restaurants.isEmpty) {
            return Center(
              child: Text(
                'No $categoryName restaurants found.',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary),
              ),
            );
          }

          // Simply list all available restaurants since there's no actual API distinction 
          // between Takeaway and Dine-In in the demo database schema. 
          // For a real app, you would filter them here: `where((r) => r.isTakeaway)`
          final filtered = provider.restaurants;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // padding for FAB
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final r = filtered[index];
              return _buildRestaurantCard(context, r);
            },
          );
        },
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, RestaurantModel r) {
    const String imageUrl =
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(restaurantId: r.restaurantId),
          ),
        );
      },
      child: Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: Image.network(
                imageUrl,
                width: 120,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      r.restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.cuisineDisplay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFE67E22), size: 16),
                        const SizedBox(width: 4),
                        Text(r.averageRating.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGlow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('25 min',
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
