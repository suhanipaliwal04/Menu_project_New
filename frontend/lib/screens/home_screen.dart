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
import '../providers/favorites_provider.dart';
import '../models/restaurant_model.dart';
import 'results_screen.dart';
import 'restaurant_detail_screen.dart';
import 'voice_agent_screen.dart';
import 'cart_screen.dart';
import 'admin_login_screen.dart';
import 'retailer_login_screen.dart';
import '../widgets/voice_fab.dart';

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
  String _selectedTab = 'Dine In'; // Takeaway, Dine In
  String _activePopularTab = 'Trending';
  String _selectedCity = 'Nagpur';
  String _selectedArea = 'Sitabuldi';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wake up Render server (free tier spins down after inactivity).
      // This silent ping runs in background so the server is ready
      // by the time the user makes their first real request.
      ApiService().healthCheck().catchError((_) => false);
      final provider = context.read<BrowseProvider>();
      provider.loadRestaurants();
      provider.loadAreas();
    });
  }


  final List<Map<String, dynamic>> _banners = [
    {
      'image': 'assets/images/poster_1.png',
      'quote': "Confused what to eat?\nTell me your budget & cravings!",
      'align': Alignment.bottomRight,
      'font': GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
    },
    {
      'image': 'assets/images/poster_2.png',
      'quote': "\"Spicy & vegan under ₹1000?\"\nJust ask me!",
      'align': Alignment.bottomLeft,
      'font': GoogleFonts.outfit(color: const Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.w900, height: 1.1),
    },
    {
      'image': 'assets/images/poster_3.png',
      'quote': "Healthy, cheesy, or sweet?\nLet AI find your perfect meal.",
      'align': Alignment.center,
      'font': GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'North Indian',
      'url':
          'https://images.unsplash.com/photo-1585937421612-70a008356fbe?q=80&w=200'
    },
    {
      'name': 'Thali',
      'url':
          'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=200' // Better Indian thali
    },
    {
      'name': 'Snacks',
      'url':
          'https://images.unsplash.com/photo-1601050690597-df0568f70950?q=80&w=200'
    },
    {
      'name': 'Chinese',
      'url':
          'https://images.unsplash.com/photo-1585032226651-759b368d7246?q=80&w=200'
    },
    {
      'name': 'Curries',
      'url':
          'https://images.unsplash.com/photo-1565557623262-b51c2513a641?q=80&w=200' // Better Indian curry
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

  void _showLocationPicker(BuildContext context) {
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
            Text('Select Area',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text('Nagpur locations',
                style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            Consumer<BrowseProvider>(
              builder: (context, provider, _) {
                if (provider.areasState == BrowseState.loading) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (provider.areas.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('No areas found.')),
                  );
                }
                return SizedBox(
                  height: 300,
                  child: ListView.separated(
                    itemCount: provider.areas.length,
                    separatorBuilder: (context, index) => const Divider(color: AppTheme.divider, height: 1),
                    itemBuilder: (context, index) {
                      final area = provider.areas[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGlow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20),
                        ),
                        title: Text(area.areaName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(area.city, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                        onTap: () {
                          setState(() {
                            _selectedArea = area.areaName;
                            _selectedCity = area.city;
                          });
                          Navigator.pop(ctx);
                          // Refresh restaurants based on city
                          provider.loadRestaurants(city: area.city);
                        },
                      );
                    },
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: const VoiceFab(),
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

                // Favorites section - only visible if user has favorites
                Consumer<FavoritesProvider>(
                  builder: (_, fav, __) => fav.favorites.isEmpty
                      ? const SizedBox.shrink()
                      : _buildFavoritesSection(fav.favorites),
                ),

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
                  child: GestureDetector(
                    onTap: () => _showLocationPicker(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(_selectedCity,
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: AppTheme.textPrimary)),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: AppTheme.textPrimary),
                          ],
                        ),
                        Text('$_selectedArea, $_selectedCity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
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
          items: _banners.map((banner) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                image: DecorationImage(
                  image: AssetImage(banner['image']!),
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
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Align(
                      alignment: banner['align'] as Alignment,
                      child: Text(
                        banner['quote'] as String,
                        textAlign: banner['align'] == Alignment.center
                            ? TextAlign.center
                            : (banner['align'] == Alignment.bottomRight ? TextAlign.right : TextAlign.left),
                        style: banner['font'] as TextStyle,
                      ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
                    ),
                  ),
                ],
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
              onTap: () {
                setState(() => _selectedTab = name);
              },
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

  // ── Favorites Section ──────────────────────────────────────────────────────
  Widget _buildFavoritesSection(List<RestaurantModel> favorites) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('❤️ Your Favourites'),
        SizedBox(
          height: 250,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            itemBuilder: (context, i) {
              final r = favorites[i];
              return _buildRestaurantCard(r, isFavorited: true);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Restaurant Card (shared by Favorites and Popular sections) ─────────────
  Widget _buildRestaurantCard(RestaurantModel r, {bool isFavorited = false}) {
    const String imageUrl =
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400';

    return Consumer<FavoritesProvider>(
      builder: (context, fav, _) {
        final isFav = fav.isFavorite(r.restaurantId);
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
            width: 190,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
                          child: GestureDetector(
                            onTap: () {
                              fav.toggleFavorite(r);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.elasticOut,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isFav
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isFav ? Colors.red.withValues(alpha: 0.4) : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? Colors.red : AppTheme.primary,
                                size: 18,
                              ),
                            ).animate(target: isFav ? 1 : 0)
                              .scale(begin: const Offset(1,1), end: const Offset(1.35,1.35), duration: 200.ms, curve: Curves.elasticOut)
                              .then(delay: 50.ms)
                              .scale(begin: const Offset(1.35,1.35), end: const Offset(1,1), duration: 150.ms),
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
          ).animate(delay: Duration(milliseconds: 50)).fadeIn().slideX(begin: 0.1, end: 0),
        );
      },
    );
  }



  Widget _buildPopularItems() {
    return Consumer2<BrowseProvider, FavoritesProvider>(
      builder: (context, provider, fav, _) {
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

        // --- Tab-based filtering ---
        List<RestaurantModel> filtered;
        switch (_activePopularTab) {
          case 'Healthy':
            filtered = provider.restaurants.where((r) {
              final cuisines = r.cuisineType?.join(' ').toLowerCase() ?? '';
              return cuisines.contains('salad') ||
                  cuisines.contains('healthy') ||
                  cuisines.contains('juice') ||
                  cuisines.contains('vegan') ||
                  cuisines.contains('vegetarian');
            }).toList();
            if (filtered.isEmpty) filtered = provider.restaurants;
            break;
          case 'Budget':
            filtered = provider.restaurants
                .where((r) => r.priceCategory == 'budget' || r.priceCategory == null)
                .toList();
            if (filtered.isEmpty) filtered = provider.restaurants;
            break;
          case 'Offers':
            filtered = provider.restaurants
                .take((provider.restaurants.length / 2).ceil())
                .toList();
            if (filtered.isEmpty) filtered = provider.restaurants;
            break;
          default:
            filtered = provider.restaurants;
        }

        return SizedBox(
          height: 250,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            itemBuilder: (context, i) => _buildRestaurantCard(filtered[i]),
          ),
        );
      },
    );
  }

}
