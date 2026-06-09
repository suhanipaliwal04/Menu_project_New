import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/chat_provider.dart';
import '../providers/voice_agent_provider.dart';
import '../widgets/food_item_card.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/typewriter_text.dart';
import '../widgets/voice_fab.dart';
import '../providers/cart_provider.dart';
import '../providers/browse_provider.dart';
import 'restaurant_detail_screen.dart';
import 'category_results_screen.dart';
import 'cart_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late VoiceAgentProvider _voiceAgentProvider;

  @override
  void initState() {
    super.initState();
    _voiceAgentProvider = context.read<VoiceAgentProvider>();
  }

  @override
  void dispose() {
    _voiceAgentProvider.stopEverything();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Consumer<ChatProvider>(
        builder: (_, provider, __) {
          if (provider.state == ChatState.loading) {
            return _buildLoading();
          }
          if (provider.state == ChatState.error) {
            return _buildError(context, provider.errorMessage);
          }
          if (provider.state == ChatState.success &&
              provider.response != null) {
            return _buildResults(context, provider);
          }
          return const SizedBox.shrink();
        },
      ),
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
                      heroTag: 'cart_fab_results',
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
            FloatingActionButton(
              heroTag: 'book_table_results',
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
              child: const Icon(Icons.deck_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLoading() {
    return _LoadingView();
  }

  Widget _buildError(BuildContext context, String? message) {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.wifi_off_rounded,
                          color: AppTheme.error, size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text('Oops!',
                        style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      message ?? 'Something went wrong.',
                      style: GoogleFonts.outfit(
                          color: AppTheme.textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, ChatProvider provider) {
    final response = provider.response!;
    final displayItems = provider.displayItems;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppTheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider.lastQuery,
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (provider.lastArea.isNotEmpty)
                Text(provider.lastArea,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          actions: [
            Consumer<VoiceAgentProvider>(
              builder: (context, vp, _) => IconButton(
                icon: Icon(
                  vp.voiceReplyEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: vp.voiceReplyEnabled
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                ),
                onPressed: () {
                  vp.toggleVoiceReply();
                  if (vp.voiceReplyEnabled) {
                    final response = context.read<ChatProvider>().response;
                    if (response != null && response.answer.isNotEmpty) {
                      vp.speakAsync(response.answer);
                    }
                  }
                },
                tooltip: vp.voiceReplyEnabled ? 'Mute AI Voice' : 'Unmute AI Voice',
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverToBoxAdapter(
          child: _buildAnswerCard(context, response.answer),
        ),
        SliverToBoxAdapter(
          child: _buildFilterBar(context, provider),
        ),
        SliverToBoxAdapter(
          child: _buildFiltersUsedChips(provider),
        ),
        if (displayItems.isEmpty)
          SliverToBoxAdapter(child: _buildEmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final item = displayItems[i];
                  return FoodItemCard(
                    item: item,
                    index: i,
                    onTap: () {
                      if (item.restaurantId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantDetailScreen(
                              restaurantId: item.restaurantId!,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Restaurant details not available')),
                        );
                      }
                    },
                  );
                },
                childCount: displayItems.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(BuildContext context, String answer) {
    // Auto-speak when this card first appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vp = context.read<VoiceAgentProvider>();
      if (vp.voiceReplyEnabled) vp.speakAsync(answer);
    });
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5E6D3), Color(0xFFFDF5E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TypewriterText(text: answer),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFilterBar(BuildContext context, ChatProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Text(
            '${provider.displayItems.length} items found',
            style:
                GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          // Veg toggle
          _FilterToggle(
            label: '🥦 Veg Only',
            active: provider.vegOnly,
            onTap: () => provider.setVegOnly(!provider.vegOnly),
          ),
          const SizedBox(width: 8),
          // Sort dropdown
          _SortMenu(
            current: provider.sortBy,
            onSelect: provider.setSortBy,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersUsedChips(ChatProvider provider) {
    final filters = provider.response?.filtersUsed.activeFilters ?? [];
    if (filters.isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: filters
            .map((f) => Chip(
                  label: Text(f,
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: AppTheme.accent)),
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                  side: BorderSide(
                      color: AppTheme.accent.withValues(alpha: 0.3), width: 1),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No matches found',
              style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Try broadening your search or pick a different area.',
              style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterToggle(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary
              : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: active ? AppTheme.primary : AppTheme.divider),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                color: active ? Colors.white : AppTheme.textSecondary,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                fontSize: 12)),
      ).animate(target: active ? 1 : 0).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 200.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  final String current;
  final void Function(String) onSelect;
  const _SortMenu({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelect,
      color: AppTheme.surfaceAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded,
                size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text('Sort',
                style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
      itemBuilder: (_) => [
        _popItem('relevance', '⭐ Relevance'),
        _popItem('price_asc', '₹ Price: Low to High'),
        _popItem('price_desc', '₹ Price: High to Low'),
        _popItem('health', '💚 Health Score'),
      ],
    );
  }

  PopupMenuItem<String> _popItem(String value, String label) => PopupMenuItem(
        value: value,
        child: Text(label,
            style: GoogleFonts.outfit(
                color:
                    current == value ? AppTheme.primary : AppTheme.textPrimary,
                fontSize: 14)),
      );
}

class _LoadingView extends StatefulWidget {
  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView> {
  final List<String> _tips = [
    'Reading local menus...',
    'Analyzing ingredients...',
    'Checking ratings...',
    'Finding the best matches...',
    'Calculating prices...',
  ];
  int _tipIndex = 0;
  late final Stream<int> _tipStream;

  @override
  void initState() {
    super.initState();
    _tipStream = Stream.periodic(const Duration(milliseconds: 1800), (i) => i);
    _tipStream.listen((_) {
      if (mounted) {
        setState(() {
          _tipIndex = (_tipIndex + 1) % _tips.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppTheme.primary, size: 16),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 800.ms),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
                    child: child,
                  )),
                  child: Text(
                    _tips[_tipIndex],
                    key: ValueKey<int>(_tipIndex),
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: 4,
              itemBuilder: (context, index) => const SkeletonCard(),
            ),
          ),
        ],
      ),
    );
  }
}
