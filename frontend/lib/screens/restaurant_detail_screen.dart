import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/browse_provider.dart';
import '../models/menu_model.dart';
import '../widgets/health_badge.dart';
import '../widgets/veg_indicator.dart';
import '../widgets/voice_fab.dart';
import '../providers/cart_provider.dart';
import 'table_booking_screen.dart';
import 'cart_screen.dart';
import 'restaurant_reviews_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final TextEditingController _menuSearchCtrl = TextEditingController();
  String _searchQuery = '';

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
            
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VoiceFab(),
                      const SizedBox(width: 16),
                      Consumer<CartProvider>(
                        builder: (context, cart, _) {
                          return FloatingActionButton(
                            heroTag: 'cart_fab',
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
                  ),
                  const SizedBox(width: 16),
                  if (restaurant.hasDineIn)
                    FloatingActionButton.extended(
                      heroTag: 'book_table_${widget.restaurantId}',
                      onPressed: () => _showBookingModal(context, restaurant),
                      backgroundColor: AppTheme.primary,
                      icon: const Icon(Icons.deck_rounded, color: Colors.white),
                      label: Text('Book a Table', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                ],
              ),
            ),
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
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
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
                  ...(() {
                    if (_searchQuery.isEmpty) {
                      return menuResponse.sections.map((section) => _buildMenuSection(section, restaurant.restaurantName));
                    }
                    final filteredSections = <MenuSectionModel>[];
                    for (final section in menuResponse.sections) {
                      final filteredItems = section.items.where((item) {
                        return item.itemName.toLowerCase().contains(_searchQuery) ||
                            (item.description?.toLowerCase().contains(_searchQuery) ?? false);
                      }).toList();
                      if (filteredItems.isNotEmpty) {
                        filteredSections.add(
                          MenuSectionModel(
                            sectionId: section.sectionId,
                            sectionName: section.sectionName,
                            items: filteredItems,
                          ),
                        );
                      }
                    }
                    if (filteredSections.isEmpty) {
                      return [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text('No matching items found.',
                                style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textSecondary)),
                          ),
                        )
                      ];
                    }
                    return filteredSections.map((section) => _buildMenuSection(section, restaurant.restaurantName));
                  })(),
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
      
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/aesthetic_header.png',
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
      actions: const [],
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RestaurantReviewsScreen(
                        restaurantId: r.restaurantId,
                        restaurantName: r.restaurantName,
                      ),
                    ),
                  );
                },
                child: Container(
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
                          Text(r.averageRating.toStringAsFixed(1), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.accent)),
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded, size: 18, color: AppTheme.accent),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${r.totalReviews} ratings', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.accent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(MenuSectionModel section, String restaurantName) {
    return SliverMainAxisGroup(
      slivers: [
        SliverAppBar(
          pinned: true,
          primary: false,
          automaticallyImplyLeading: false,
          
          elevation: 0,
          title: Text(section.sectionName,
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildMenuItem(section.items[i], restaurantName),
              childCount: section.items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(MenuItemModel item, String restaurantName) {
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
          _buildItemImage(item, restaurantName),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildItemImage(MenuItemModel item, String restaurantName) {
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
          child: Consumer<CartProvider>(
            builder: (context, cart, _) {
              final cartItems = cart.items.where((i) => i.id == item.itemId).toList();
              final qty = cartItems.isNotEmpty ? cartItems.first.quantity : 0;
              
              if (qty == 0) {
                return GestureDetector(
                  onTap: () {
                    cart.addItem(
                      id: item.itemId,
                      name: item.itemName,
                      price: item.price,
                      restaurantName: restaurantName,
                      restaurantId: widget.restaurantId,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.itemName} added to cart', style: GoogleFonts.outfit()),
                        backgroundColor: AppTheme.primary,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
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
                );
              } else {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => cart.decrementItem(item.itemId),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.remove_rounded, color: AppTheme.primary, size: 20),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('$qty', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary)),
                      ),
                      GestureDetector(
                        onTap: () => cart.addItem(
                          id: item.itemId,
                          name: item.itemName,
                          price: item.price,
                          restaurantName: restaurantName,
                          restaurantId: widget.restaurantId,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 20),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
