import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/browse_provider.dart';
import 'restaurant_detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _filters = [
    'Rating 4.0+',
    'Pure Veg',
    'Cuisines',
    'Fast Delivery',
    'Great Offers',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrowseProvider>().loadAreas();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text('Explore Nagpur',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 24)),
        
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search city (e.g. Nagpur)',
                    prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onSubmitted: (val) {
                    context.read<BrowseProvider>().loadAreas(city: val.trim());
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildFilterPills(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Consumer<BrowseProvider>(
        builder: (context, provider, _) {
          if (provider.areasState == BrowseState.loading || provider.areaRestaurantsState == BrowseState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }

          if (provider.selectedArea == null) {
            return _buildAreasList(provider);
          }

          return _buildRestaurantsList(provider);
        },
      ),
    );
  }

  Widget _buildFilterPills() {
    return Consumer<BrowseProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: 44,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, i) {
              final filter = _filters[i];
              bool active = provider.selectedFilters.contains(filter);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: active,
                  onSelected: (_) => provider.toggleFilter(filter),
                  backgroundColor: AppTheme.surface,
                  selectedColor: AppTheme.primary,
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? Colors.white : AppTheme.textSecondary,
                  ),
                  side: BorderSide(color: active ? AppTheme.primary : AppTheme.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ).animate(target: active ? 1 : 0).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 200.ms,
                      curve: Curves.easeOutBack,
                    ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAreasList(BrowseProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.areas.length,
      itemBuilder: (context, i) {
        final area = provider.areas[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(area.areaName, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17)),
            subtitle: Text(area.city, style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            onTap: () => provider.loadAreaRestaurants(area.areaId),
          ),
        ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildRestaurantsList(BrowseProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => provider.clearSelectedArea(),
              ),
              Text(
                'Restaurants in ${provider.selectedArea!.areaName}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: provider.areaRestaurants.length,
            itemBuilder: (context, i) {
              final r = provider.areaRestaurants[i];
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
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          image: DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=800'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: const Stack(
                          children: [
                            Positioned(
                              top: 12,
                              right: 12,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 18,
                                child: Icon(Icons.favorite_border_rounded, size: 20, color: AppTheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r.restaurantName, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Text('4.2', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppTheme.accent, fontSize: 13)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.star_rounded, size: 14, color: AppTheme.accent),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${r.cuisineType} • ${r.priceCategory}',
                              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Text('30-35 mins', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13)),
                                const Spacer(),
                                Text('FREE DELIVERY', style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: 100 * i)).fadeIn().slideY(begin: 0.1, end: 0),
              );
            },
          ),
        ),
      ],
    );
  }
}
