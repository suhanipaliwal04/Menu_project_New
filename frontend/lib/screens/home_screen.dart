import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import '../providers/chat_provider.dart';
import '../providers/browse_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/voice_agent_provider.dart';
import 'results_screen.dart';
import 'restaurant_detail_screen.dart';
import 'voice_agent_screen.dart';
import 'cart_screen.dart';
import 'admin_login_screen.dart';
import 'retailer_login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _queryCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  int _carouselIndex = 0;
  String _selectedTab = 'Order Online'; // Takeaway, Online, Dine In
  String _activePopularTab = 'Trending';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wake up Render server (free tier spins down after inactivity).
      // This silent ping runs in background so the server is ready
      // by the time the user makes their first real request.
      ApiService().healthCheck().catchError((_) => false);
      context.read<BrowseProvider>().loadRestaurants();
    });
  }


  // High-quality professional photography from Unsplash (Classic/Minimalist)
  final List<String> _banners = [
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=1200', // Pizza/Delivery
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1200', // Gourmet meal
    'https://images.unsplash.com/photo-1559339352-11d035aa65de?q=80&w=1200', // Healthy/Minimalist
  ];

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Pizza',
      'url':
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=200'
    },
    {
      'name': 'Burgers',
      'url':
          'https://images.unsplash.com/photo-1571091718767-18b5b1457add?q=80&w=200'
    },
    {
      'name': 'Sushi',
      'url':
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?q=80&w=200'
    },
    {
      'name': 'Coffee',
      'url':
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=200'
    },
    {
      'name': 'Healthy',
      'url':
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=200'
    },
    {
      'name': 'Desserts',
      'url':
          'https://images.unsplash.com/photo-1551024601-bec78aea704b?q=80&w=200'
    },
  ];

  @override
  void dispose() {
    _queryCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  void _showPortalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Portal',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text('Which portal would you like to access?',
                style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            // Restaurant Owner
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RetailerLoginScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFD35400), AppTheme.primary]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Restaurant Owner',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary)),
                          Text('Manage your restaurant, upload menus',
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // System Admin
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3498DB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: Color(0xFF2980B9), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('System Admin',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary)),
                          Text('Manage areas, restaurants & system',
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _search() {
    final query = _queryCtrl.text.trim();
    final area = _areaCtrl.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('What are you craving?', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = context.read<ChatProvider>();
    provider.search(query: query, areaName: area);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => const ResultsScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: 400.ms,
      ),
    );
  }

  void _showVoiceSearch() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        pageBuilder: (_, __, ___) => const VoiceAgentScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: _buildVoiceFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildAISearchCard(),
                ),
                _buildTypeSelector(),
                const SizedBox(height: 16),
                _buildCategories(),
                const SizedBox(height: 24),
                _buildCarousel(),
                const SizedBox(height: 32),
                _buildSearchBar(),
                const SizedBox(height: 32),
                _buildSectionHeader('Popular Near You'),
                _buildPopularTabs(),
                _buildPopularItems(),
                const SizedBox(height: 120), // Bottom padding for nav
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 80,
      backgroundColor: AppTheme.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: AppTheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text('Nagpur',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppTheme.textPrimary)),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18, color: AppTheme.textPrimary),
                        ],
                      ),
                      Text('Sitabuldi, Nagpur, Maharashtra',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showPortalSheet(context),
                  child: const CircleAvatar(
                    backgroundColor: AppTheme.surfaceAlt,
                    child: Icon(Icons.person_outline_rounded,
                        color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => _searchFocus.requestFocus(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search for food, restaurants...',
                style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 16),
              ),
            ),
            const VerticalDivider(
                width: 20, color: AppTheme.divider, indent: 18, endIndent: 18),
            const Icon(Icons.filter_list_rounded, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 340, // More square-ish height
            viewportFraction: 0.82,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayCurve: Curves.easeInOutQuart,
            autoPlayAnimationDuration: 1200.ms,
            onPageChanged: (index, reason) {
              setState(() => _carouselIndex = index);
            },
          ),
          items: _banners.map((url) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                image: DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        DotsIndicator(
          dotsCount: _banners.length,
          position: _carouselIndex.toDouble(),
          decorator: DotsDecorator(
            activeColor: AppTheme.primary,
            size: const Size.square(6),
            activeSize: const Size(18, 6),
            activeShape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            color: AppTheme.divider,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final List<Map<String, dynamic>> types = [
      {'name': 'Takeaway', 'icon': Icons.local_mall_rounded},
      {'name': 'Order Online', 'icon': Icons.delivery_dining_rounded},
      {'name': 'Dine In', 'icon': Icons.restaurant_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: types.map((t) {
          String name = t['name'];
          IconData icon = t['icon'];
          bool active = _selectedTab == name;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = name),
              child: AnimatedContainer(
                duration: 300.ms,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? AppTheme.primary : AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: active
                          ? AppTheme.primary
                          : AppTheme.divider),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, 
                      size: 20, 
                      color: active ? Colors.white : AppTheme.textSecondary),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('In the mood for?'),
        SizedBox(
          height: 100,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, i) {
              final cat = _categories[i];
              return GestureDetector(
                onTap: () {
                  _queryCtrl.text = cat['name'];
                  _search();
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        height: 68,
                        width: 68,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(cat['url']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['name'],
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().scale();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAISearchCard() {
    return GestureDetector(
      onTap: () => _searchFocus.requestFocus(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF5E6D3), Color(0xFFFDF5E6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined,
                    color: AppTheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'AI Menu Intelligence',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 18),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _queryCtrl,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              style:
                  GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Describe what you want...',
                fillColor: Colors.white.withValues(alpha: 0.85),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: IconButton(
                  icon: const Icon(Icons.mic_none_rounded, color: AppTheme.primary, size: 20),
                  onPressed: _showVoiceSearch,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.primary, size: 20),
                  onPressed: _search,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['Trending', 'Healthy', 'Offers', 'Budget'].map((tab) {
          bool active = _activePopularTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(tab),
              selected: active,
              onSelected: (val) => setState(() => _activePopularTab = tab),
              backgroundColor: AppTheme.surface,
              selectedColor: AppTheme.primary,
              labelStyle: GoogleFonts.outfit(
                color: active ? Colors.white : AppTheme.textSecondary,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(
                  color: active ? AppTheme.primary : AppTheme.divider),
            ).animate(target: active ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 200.ms),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPopularItems() {
    return Consumer<BrowseProvider>(
      builder: (context, provider, _) {
        if (provider.restaurantsState == BrowseState.loading) {
          return const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.errorMessage != null && provider.restaurants.isEmpty) {
          return SizedBox(
            height: 250,
            child: Center(child: Text(provider.errorMessage!)),
          );
        }

        if (provider.restaurants.isEmpty) {
          return const SizedBox(
            height: 250,
            child: Center(child: Text('No popular restaurants found.')),
          );
        }

        return SizedBox(
          height: 250,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: provider.restaurants.length,
            itemBuilder: (context, i) {
              final r = provider.restaurants[i];
              // Fallback image since API doesn't provide image_url yet
              const String imageUrl =
                  'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RestaurantDetailScreen(restaurantId: r.restaurantId),
                    ),
                  );
                },
                child: Container(
                  width: 190,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.favorite_border_rounded,
                                      color: AppTheme.primary,
                                      size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.restaurantName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Color(0xFFE67E22), size: 16),
                                  const SizedBox(width: 4),
                                  Text('4.8',
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
                      ],
                    ),
                  ),
                ).animate(delay: Duration(milliseconds: 100 * i)).fadeIn().slideX(
                    begin: 0.1, end: 0),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVoiceFab() {
    return Consumer2<VoiceAgentProvider, CartProvider>(
      builder: (context, vp, cart, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cart badge button
            if (cart.totalItems > 0)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 16, bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.divider),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_bag_rounded,
                          color: AppTheme.primary, size: 26),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cart.totalItems}',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1),
                  curve: Curves.elasticOut, duration: 500.ms),

            // Main voice mic FAB
            GestureDetector(
              onTap: _showVoiceSearch,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFFE0873A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 30),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.06, duration: 1500.ms, curve: Curves.easeInOut),
            ),
          ],
        );
      },
    );
  }
}
