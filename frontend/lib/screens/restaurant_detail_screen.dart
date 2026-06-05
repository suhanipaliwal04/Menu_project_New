import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/browse_provider.dart';
import '../models/menu_model.dart';
import '../widgets/health_badge.dart';
import '../widgets/veg_indicator.dart';
import '../core/api_service.dart';
import 'table_booking_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final TextEditingController _menuSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrowseProvider>().loadRestaurantMenu(widget.restaurantId);
    });
  }

  @override
  void dispose() {
    _menuSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<BrowseProvider>(
        builder: (context, provider, _) {
          if (provider.menuState == BrowseState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final menuResponse = provider.restaurantMenu;
          if (menuResponse == null) {
            return const Center(child: Text('Menu not found'));
          }

          final restaurant = menuResponse.restaurant;

          return Scaffold(
            backgroundColor: AppTheme.background,
            floatingActionButton: restaurant.hasDineIn
                ? FloatingActionButton.extended(
                    onPressed: () => _showBookingModal(context, restaurant),
                    backgroundColor: AppTheme.primary,
                    icon: const Icon(Icons.event_seat_rounded, color: Colors.white),
                    label: Text('Book a Table', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
                  )
                : null,
            body: CustomScrollView(
              slivers: [
                _buildAppBar(restaurant.restaurantName),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRestaurantInfo(restaurant),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: TextField(
                          controller: _menuSearchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search in menu...',
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                            fillColor: AppTheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.divider),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.divider),
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 32),
                    ],
                  ),
                ),
                if (menuResponse.sections.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 64, color: AppTheme.divider),
                          const SizedBox(height: 16),
                          Text('Menu coming soon!',
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          Text('This restaurant hasn\'t uploaded their menu yet.',
                              style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  )
                else
                  ...menuResponse.sections.map((section) => _buildMenuSection(section)),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBookingModal(BuildContext context, RestaurantMenuInfo restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TableBookingScreen(
          restaurantId: restaurant.restaurantId,
          restaurantName: restaurant.restaurantName,
        ),
      ),
    );
  }

  Widget _buildAppBar(String name) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: AppTheme.background,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1200',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [],
    );
  }

  Widget _buildRestaurantInfo(dynamic r) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.restaurantName, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    Text('${r.cuisineType?.join(', ') ?? 'Various'} • ${r.priceCategory ?? ''}',
                        style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('4.5', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.accent)),
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded, size: 18, color: AppTheme.accent),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('1k+ ratings', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.accent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('30-35 mins', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(width: 20),
                const Icon(Icons.delivery_dining_rounded, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('FREE DELIVERY', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(MenuSectionModel section) {
    return SliverMainAxisGroup(
      slivers: [
        SliverAppBar(
          pinned: true,
          primary: false,
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.background,
          elevation: 0,
          title: Text(section.sectionName,
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildMenuItem(section.items[i]),
              childCount: section.items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(MenuItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VegIndicator(isVeg: item.isVeg),
                const SizedBox(height: 8),
                Text(item.itemName,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(item.priceDisplay,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                if (item.healthScore != null)
                  HealthBadge(score: item.healthScore),
                if (item.description != null) ...[
                  const SizedBox(height: 8),
                  Text(item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildItemImage(item),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildItemImage(MenuItemModel item) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Text('ADD',
                style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}
