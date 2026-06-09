// ignore_for_file: deprecated_member_use, unused_field, use_build_context_synchronously
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../providers/retailer_provider.dart';
import '../providers/auth_provider.dart';
import '../models/admin_models.dart';
import '../models/area_model.dart';
import '../models/restaurant_model.dart';
import 'customer_login_screen.dart';
import '../providers/reviews_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class RetailerDashboardScreen extends StatefulWidget {
  const RetailerDashboardScreen({super.key});

  @override
  State<RetailerDashboardScreen> createState() =>
      _RetailerDashboardScreenState();
}

class _RetailerDashboardScreenState extends State<RetailerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (icon: Icons.bar_chart_rounded, label: 'Overview'),
    (icon: Icons.restaurant_menu_rounded, label: 'Menu Items'),
    (icon: Icons.cloud_upload_rounded, label: 'Upload'),
    (icon: Icons.settings_rounded, label: 'Settings'),
    (icon: Icons.history_rounded, label: 'History'),
    (icon: Icons.book_online_rounded, label: 'Bookings'),
    (icon: Icons.shopping_bag_rounded, label: 'Takeaway'),
    (icon: Icons.star_rounded, label: 'Reviews'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<RetailerProvider>();
      final auth = context.read<AuthProvider>();
      await p.fetchAreas(city: auth.city);
      if (p.myRestaurant != null) {
        p.fetchDashboard();
        p.fetchMenuItems();
        p.fetchSections();
        p.fetchTakeawayOrders();
        p.fetchBookings();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: GoogleFonts.outfit(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await context.read<RetailerProvider>().logout();
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('Sign Out',
                style: GoogleFonts.outfit(
                    color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _OverviewTab(),
            _MenuItemsTab(),
            _UploadTab(),
            _SettingsTab(),
            _HistoryTab(),
            _BookingsTab(),
            _TakeawayTab(),
            _ReviewsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool collapsed) {
    return Consumer<RetailerProvider>(
      builder: (context, p, _) {
        final name = p.myRestaurant?.restaurantName ?? 'My Restaurant';
        final isLive = p.myRestaurant != null;

        return SliverAppBar(
          expandedHeight: 210,
          pinned: true,
          backgroundColor: AppTheme.surface,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC19A6B).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFC19A6B), size: 20),
                onPressed: _confirmLogout,
                tooltip: 'Sign Out',
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFC19A6B), Color(0xFF7B3F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 64),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.storefront_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(name,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('Restaurant Admin Portal',
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isLive
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isLive
                                ? Colors.greenAccent.withValues(alpha: 0.5)
                                : Colors.orangeAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          isLive ? '● Live' : '⚠ Setup',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: AppTheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 12),
                unselectedLabelStyle:
                    GoogleFonts.outfit(fontSize: 12),
                tabs: _tabs.map((t) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.icon, size: 15),
                        const SizedBox(width: 5),
                        Text(t.label),
                        if (t.label == 'Bookings' && p.bookings.where((b) => b.status == 'PENDING').isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '${p.bookings.where((b) => b.status == 'PENDING').length}',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        if (t.label == 'Takeaway' && p.takeawayOrders.where((o) => o.status == 'PENDING').isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '${p.takeawayOrders.where((o) => o.status == 'PENDING').length}',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 — OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<RetailerProvider>(builder: (context, p, _) {
      final r = p.myRestaurant;
      if (r == null) return _buildSetupPrompt(context);

      final s = p.dashboardStats;

      return RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => p.fetchDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              _welcomeCard(r.restaurantName, s?.isActive ?? true),
              const SizedBox(height: 20),

              // Stat cards row 1
              if (s != null) ...[
                _sectionLabel('Overview'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _statCard('Total Items', '${s.totalItems}',
                      Icons.fastfood_rounded, const Color(0xFFC19A6B))),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard('Sections', '${s.totalSections}',
                      Icons.category_rounded, const Color(0xFF3498DB))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _statCard(
                      'Avg. Price',
                      s.avgPrice != null ? '₹${s.avgPrice!.toStringAsFixed(0)}' : '—',
                      Icons.currency_rupee_rounded,
                      const Color(0xFF2ECC71))),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard('Uploads', '${s.totalUploads}',
                      Icons.cloud_upload_rounded, const Color(0xFF9B59B6))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _statCard('Total Bookings', '${s.totalBookings}',
                      Icons.book_online_rounded, const Color(0xFFE67E22))),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard('Pending Bookings', '${s.pendingBookings}',
                      Icons.pending_actions_rounded, const Color(0xFFE74C3C))),
                ]),
                const SizedBox(height: 20),

                // Quick Controls
                _sectionLabel('Quick Controls'),
                const SizedBox(height: 10),
                _buildQuickControls(context, p, r),

                const SizedBox(height: 20),

                // Veg breakdown
                _sectionLabel('Menu Breakdown'),
                const SizedBox(height: 10),
                _vegBreakdownCard(s),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),

              const SizedBox(height: 20),
              
              // Recent Bookings
              _sectionLabel('Recent Booking Activity'),
              const SizedBox(height: 10),
              _buildRecentBookings(p),

              const SizedBox(height: 20),
              _sectionLabel('Restaurant Info'),
              const SizedBox(height: 10),
              _infoCard(r),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRecentBookings(RetailerProvider p) {
    // Show top 3 most recent bookings (pending or confirmed)
    final recent = p.bookings.where((b) => b.status == 'PENDING' || b.status == 'CONFIRMED').take(3).toList();
    
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_available_rounded, color: AppTheme.textMuted, size: 20),
            const SizedBox(width: 12),
            Text('No recent booking activity.', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: recent.map((b) {
        final isPending = b.status == 'PENDING';
        final statusColor = isPending ? AppTheme.error : AppTheme.success;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking #${b.bookingId.substring(0, 8)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${b.partySize} Guests', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(b.timeSlot, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(b.status, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
        );
      }).toList(),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildSetupPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined,
                size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('No Restaurant Yet',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('Go to the Settings tab to register your restaurant.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary, fontSize: 13)),
            // Debug: show actual error if present
            Consumer<RetailerProvider>(
              builder: (_, p, __) => p.errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Debug: ${p.errorMessage}',
                          style: GoogleFonts.outfit(color: Colors.red, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard(String name, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC19A6B), Color(0xFF7B3F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC19A6B).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(isActive ? '✓ Live and discoverable' : '⚠ Deactivated',
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickControls(BuildContext context, RetailerProvider p, RestaurantModel r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _buildQuickToggle(
            'Accepting Dine-In',
            r.hasDineIn,
            AppTheme.primary,
            (val) => p.updateRestaurant(hasDineIn: val),
          ),
          const Divider(height: 24),
          _buildQuickToggle(
            'Accepting Takeaway',
            r.hasTakeaway,
            AppTheme.primary,
            (val) => p.updateRestaurant(hasTakeaway: val),
          ),
          const Divider(height: 24),
          _buildQuickToggle(
            'Store Open (Manual)',
            r.isOpenManually,
            AppTheme.success,
            (val) => p.updateRestaurant(isOpenManually: val),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.08, end: 0);
  }

  Widget _buildQuickToggle(String label, bool value, Color activeColor, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3));
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.08, end: 0);
  }

  Widget _vegBreakdownCard(DashboardStats s) {
    final vegPct = s.vegPercent;
    return Container(
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
              _vegBadge('🌿 Veg', s.vegItems, AppTheme.vegGreen),
              _vegBadge('🍗 Non-Veg', s.nonVegItems, AppTheme.nonVegRed),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: vegPct,
              minHeight: 10,
              backgroundColor: AppTheme.nonVegRed.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.vegGreen),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(vegPct * 100).toStringAsFixed(0)}% veg',
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.08, end: 0);
  }

  Widget _vegBadge(String label, int count, Color color) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label  ',
            style:
                GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary)),
        Text('$count',
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _infoCard(dynamic r) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          if (r.address != null)
            _infoRow(Icons.location_on_rounded, 'Address', r.address!,
                const Color(0xFFE67E22)),
          if (r.phone != null)
            _infoRow(Icons.phone_rounded, 'Phone', r.phone!,
                const Color(0xFF3498DB)),
          if (r.cuisineType != null && r.cuisineType!.isNotEmpty)
            _infoRow(Icons.restaurant_menu_rounded, 'Cuisine',
                r.cuisineType!.join(', '), const Color(0xFF9B59B6)),
          _infoRow(Icons.attach_money_rounded, 'Price Category',
              r.priceCategoryDisplay.isNotEmpty
                  ? r.priceCategoryDisplay
                  : 'Not set',
              const Color(0xFF2ECC71)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.08, end: 0);
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — MENU ITEMS (CRUD)
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItemsTab extends StatefulWidget {
  const _MenuItemsTab();

  @override
  State<_MenuItemsTab> createState() => _MenuItemsTabState();
}

class _MenuItemsTabState extends State<_MenuItemsTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AdminMenuItem> _filtered(List<AdminMenuItem> items) {
    if (_searchQuery.isEmpty) return items;
    return items
        .where((i) =>
            i.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            i.sectionName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RetailerProvider>(builder: (context, p, _) {
      if (p.myRestaurant == null) {
        return _noRestaurantPlaceholder();
      }

      final items = _filtered(p.menuItems);

      return Column(
        children: [
          // Search + Filter bar
          _buildFilterBar(p),

          // Items list
          Expanded(
            child: items.isEmpty && p.state != RetailerState.loading
                ? _emptyState()
                : RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: () => p.fetchMenuItems(
                        sectionName: p.sectionFilter, isVeg: p.vegFilter),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) =>
                          _MenuItemCard(item: items[i]).animate().fadeIn(
                              delay: Duration(milliseconds: i * 30)),
                    ),
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildFilterBar(RetailerProvider p) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          // Search box
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: GoogleFonts.outfit(
                color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppTheme.textMuted, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppTheme.textMuted, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  label: 'All',
                  selected: p.sectionFilter == null && p.vegFilter == null,
                  onTap: () => p.setFilter(clearAll: true),
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: '🌿 Veg',
                  selected: p.vegFilter == true,
                  onTap: () => p.setFilter(isVeg: p.vegFilter == true ? null : true),
                  color: AppTheme.vegGreen,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: '🍗 Non-Veg',
                  selected: p.vegFilter == false,
                  onTap: () =>
                      p.setFilter(isVeg: p.vegFilter == false ? null : false),
                  color: AppTheme.nonVegRed,
                ),
                const SizedBox(width: 8),
                ...p.sections.map((sec) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _filterChip(
                        label: sec.sectionName,
                        selected: p.sectionFilter == sec.sectionName,
                        onTap: () => p.setFilter(
                            section: p.sectionFilter == sec.sectionName
                                ? null
                                : sec.sectionName),
                        color: AppTheme.accent,
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('${_filtered(p.menuItems).length} items',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppTheme.textMuted)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _confirmClearAll(context, p),
                icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                label: Text('Clear All',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              ),
              TextButton.icon(
                onPressed: () => _showAddItemSheet(context, p),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text('Add Item',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : AppTheme.divider,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: selected ? color : AppTheme.textSecondary,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.restaurant_menu_rounded,
              size: 56, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text('No items found',
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text('Upload a menu image or add items manually.',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _noRestaurantPlaceholder() {
    return const Center(
      child: Text('Register your restaurant in Settings first.'),
    );
  }

  void _showAddItemSheet(BuildContext ctx, RetailerProvider p) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(provider: p, sections: p.sections),
    );
  }

  Future<void> _confirmClearAll(BuildContext ctx, RetailerProvider p) async {
    // First confirmation
    final sure1 = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear Entire Menu?',
            style: GoogleFonts.outfit(
                color: AppTheme.error, fontWeight: FontWeight.bold)),
        content: Text(
            'This will permanently delete all menu sections, items, and AI embeddings. Are you absolutely sure?',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text('Yes, proceed',
                  style: GoogleFonts.outfit(
                      color: AppTheme.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (sure1 != true) return;

    // Second confirmation (type 'confirm')
    final ctrl = TextEditingController();
    if (!ctx.mounted) return;
    final sure2 = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Final Confirmation',
            style: GoogleFonts.outfit(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Type "confirm" to permanently clear the menu.',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'confirm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(c, ctrl.text.trim().toLowerCase() == 'confirm'),
              child: Text('Clear Menu',
                  style: GoogleFonts.outfit(
                      color: AppTheme.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (sure2 == true) {
      final success = await p.clearAllMenuData();
      if (!ctx.mounted) return;
      if (success) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Menu completely cleared.', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.success,
        ));
      } else {
         ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(p.errorMessage ?? 'Failed to clear menu.', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }
}

// Item card with swipe-to-delete and tap-to-edit
class _MenuItemCard extends StatelessWidget {
  final AdminMenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.itemId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppTheme.error, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text('Delete Item',
                    style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold)),
                content: Text(
                    'Remove "${item.itemName}" from your menu?\nThis also removes its AI embedding.',
                    style:
                        GoogleFonts.outfit(color: AppTheme.textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel',
                          style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary))),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Delete',
                          style: GoogleFonts.outfit(
                              color: AppTheme.error,
                              fontWeight: FontWeight.bold))),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        context.read<RetailerProvider>().deleteMenuItem(item.itemId);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${item.itemName}" deleted',
              style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      },
      child: GestureDetector(
        onTap: () => _showEditSheet(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isAvailable ? AppTheme.surface : AppTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: item.isAvailable
                    ? AppTheme.divider
                    : AppTheme.divider.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              // Veg/Non-veg dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.itemName,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: item.isAvailable
                                ? AppTheme.textPrimary
                                : AppTheme.textMuted,
                            decoration: item.isAvailable
                                ? null
                                : TextDecoration.lineThrough)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.sectionName,
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (item.description != null) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(item.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppTheme.textMuted)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${item.price.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.error, size: 20),
                    padding: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final del = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.surface,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: Text('Delete Item',
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold)),
                          content: Text(
                              'Remove "${item.itemName}" from your menu?\nThis also removes its AI embedding.',
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textSecondary)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('Cancel',
                                    style: GoogleFonts.outfit(
                                        color: AppTheme.textSecondary))),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text('Delete',
                                    style: GoogleFonts.outfit(
                                        color: AppTheme.error,
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                      );
                      if (del == true && context.mounted) {
                        context.read<RetailerProvider>().deleteMenuItem(item.itemId);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('"${item.itemName}" deleted',
                              style: GoogleFonts.outfit()),
                          backgroundColor: AppTheme.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditItemSheet(item: item),
    );
  }
}

// ──────────────────────────────────────────
// Add Item Bottom Sheet
// ──────────────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  final RetailerProvider provider;
  final List<MenuSectionInfo> sections;
  const _AddItemSheet({required this.provider, required this.sections});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  bool _isVeg = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sectionCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _calCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final section = _sectionCtrl.text.trim();
    final priceStr = _priceCtrl.text.trim();

    if (name.isEmpty || section.isEmpty || priceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Name, section, and price are required.',
            style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    final price = double.tryParse(priceStr);
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enter a valid price.', style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _loading = true);
    final ok = await widget.provider.addMenuItem(
      itemName: name,
      sectionName: section,
      price: price,
      isVeg: _isVeg,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      calories:
          _calCtrl.text.trim().isEmpty ? null : int.tryParse(_calCtrl.text),
    );
    setState(() => _loading = false);

    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Item added!', style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('Add Menu Item',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          _field(_nameCtrl, 'Item Name *', Icons.label_rounded),
          const SizedBox(height: 10),
          // Section with autocomplete suggestions
          _sectionField(),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field(_priceCtrl, 'Price (₹) *', Icons.currency_rupee_rounded,
                type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field(_calCtrl, 'Calories', Icons.local_fire_department_rounded,
                type: TextInputType.number)),
          ]),
          const SizedBox(height: 10),
          _field(_descCtrl, 'Description (optional)', Icons.notes_rounded,
              maxLines: 2),
          const SizedBox(height: 12),
          // Veg toggle
          Row(children: [
            Text('Veg / Non-Veg',
                style:
                    GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13)),
            const Spacer(),
            _vegToggle(),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Add to Menu',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionField() {
    final names = widget.sections.map((s) => s.sectionName).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(_sectionCtrl, 'Section Name *', Icons.category_rounded),
        if (names.isNotEmpty) ...[
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: names
                  .map((n) => GestureDetector(
                        onTap: () =>
                            setState(() => _sectionCtrl.text = n),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Text(n,
                              style: GoogleFonts.outfit(
                                  fontSize: 11, color: AppTheme.primary)),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(
              color: AppTheme.textMuted, fontSize: 12),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _vegToggle() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isVeg = true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _isVeg
                  ? AppTheme.vegGreen.withValues(alpha: 0.12)
                  : AppTheme.background,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10)),
              border: Border.all(
                  color:
                      _isVeg ? AppTheme.vegGreen : AppTheme.divider),
            ),
            child: Text('🌿 Veg',
                style: GoogleFonts.outfit(
                    color: _isVeg ? AppTheme.vegGreen : AppTheme.textMuted,
                    fontWeight: _isVeg ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12)),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _isVeg = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: !_isVeg
                  ? AppTheme.nonVegRed.withValues(alpha: 0.12)
                  : AppTheme.background,
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(10)),
              border: Border.all(
                  color: !_isVeg ? AppTheme.nonVegRed : AppTheme.divider),
            ),
            child: Text('🍗 Non-Veg',
                style: GoogleFonts.outfit(
                    color: !_isVeg
                        ? AppTheme.nonVegRed
                        : AppTheme.textMuted,
                    fontWeight:
                        !_isVeg ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12)),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// Edit Item Bottom Sheet
// ──────────────────────────────────────────

class _EditItemSheet extends StatefulWidget {
  final AdminMenuItem item;
  const _EditItemSheet({required this.item});

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _calCtrl;
  late bool _isVeg;
  late bool _isAvailable;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.itemName);
    _priceCtrl =
        TextEditingController(text: widget.item.price.toStringAsFixed(0));
    _descCtrl =
        TextEditingController(text: widget.item.description ?? '');
    _calCtrl = TextEditingController(
        text: widget.item.calories?.toString() ?? '');
    _isVeg = widget.item.isVeg;
    _isAvailable = widget.item.isAvailable;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _calCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final updates = <String, dynamic>{};
    if (_nameCtrl.text.trim() != widget.item.itemName) {
      updates['item_name'] = _nameCtrl.text.trim();
    }
    final newPrice = double.tryParse(_priceCtrl.text);
    if (newPrice != null && newPrice != widget.item.price) {
      updates['price'] = newPrice;
    }
    if (_descCtrl.text.trim() != (widget.item.description ?? '')) {
      updates['description'] = _descCtrl.text.trim();
    }
    if (_isVeg != widget.item.isVeg) updates['is_veg'] = _isVeg;
    if (_isAvailable != widget.item.isAvailable) {
      updates['is_available'] = _isAvailable;
    }
    final cal = int.tryParse(_calCtrl.text);
    if (cal != widget.item.calories) updates['calories'] = cal;

    if (updates.isNotEmpty) {
      final ok = await context
          .read<RetailerProvider>()
          .updateMenuItem(widget.item.itemId, updates);
      setState(() => _loading = false);
      if (ok && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Item updated!', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    } else {
      setState(() => _loading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('Edit Item',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          _field(_nameCtrl, 'Item Name', Icons.label_rounded),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _field(_priceCtrl, 'Price (₹)',
                    Icons.currency_rupee_rounded,
                    type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(
                child: _field(_calCtrl, 'Calories',
                    Icons.local_fire_department_rounded,
                    type: TextInputType.number)),
          ]),
          const SizedBox(height: 10),
          _field(_descCtrl, 'Description', Icons.notes_rounded, maxLines: 2),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _toggleOption(
                  label: _isVeg ? '🌿 Veg' : '🍗 Non-Veg',
                  subtitle: 'Tap to toggle',
                  color: _isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed,
                  onTap: () => setState(() => _isVeg = !_isVeg),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _toggleOption(
                  label: _isAvailable ? 'Available' : 'Unavailable',
                  subtitle: 'Tap to toggle',
                  color: _isAvailable ? AppTheme.success : AppTheme.textMuted,
                  onTap: () =>
                      setState(() => _isAvailable = !_isAvailable),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Save Changes',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(
              color: AppTheme.textMuted, fontSize: 12),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(subtitle,
                style: GoogleFonts.outfit(
                    fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — UPLOAD
// ─────────────────────────────────────────────────────────────────────────────

class _UploadTab extends StatefulWidget {
  const _UploadTab();

  @override
  State<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<_UploadTab> {
  XFile? _image;
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource src) async {
    final picked = await _picker.pickImage(
        source: src, imageQuality: 85, maxWidth: 2048);
    if (picked != null && mounted) {
      setState(() => _image = picked);
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        child: Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Select Image Source',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFF3498DB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF3498DB), size: 22),
              ),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.gallery);
              },
            ),
            const Divider(height: 1, color: AppTheme.divider, indent: 20, endIndent: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppTheme.vegGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppTheme.vegGreen, size: 22),
              ),
              title: Text('Take a Photo',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.camera);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _upload(RetailerProvider p) async {
    if (_image == null) return;
    if (p.myRestaurant == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please register your restaurant first.',
            style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    final ok = await p.uploadMenuImage(_image!);
    if (mounted) {
      setState(() => _image = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            ok ? 'Menu processed successfully!' : (p.errorMessage ?? 'Upload failed'),
            style: GoogleFonts.outfit()),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RetailerProvider>(builder: (context, p, _) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Upload a photo of your physical menu. Our OCR + AI will extract and structure all items automatically.',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 20),

            // Mode selector
            Text('Upload Mode',
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            _modeSelector(p),
            const SizedBox(height: 20),

            // Extraction Method selector
            Text('Extraction Method',
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            _extractionSelector(p),
            const SizedBox(height: 20),

            // Image picker area
            GestureDetector(
              onTap: _showSourcePicker,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _image != null
                      ? Colors.transparent
                      : AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _image != null
                          ? AppTheme.primary.withValues(alpha: 0.3)
                          : AppTheme.divider,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            kIsWeb ? Image.network(_image!.path, fit: BoxFit.cover) : Image.file(File(_image!.path), fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _image = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 44,
                              color: AppTheme.textMuted
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 10),
                          Text('Tap to select menu image',
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textMuted,
                                  fontSize: 13)),
                          Text('JPG, PNG up to 10MB',
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textMuted
                                      .withValues(alpha: 0.6),
                                  fontSize: 11)),
                        ],
                      ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // Upload button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_image == null || p.isUploading)
                    ? null
                    : () => _upload(p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.divider,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: p.isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Text('Processing...',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text('Upload & Process Menu',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ],
                      ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            // Last upload result
            if (p.lastUploadResult != null) ...[
              const SizedBox(height: 20),
              _uploadResultCard(p.lastUploadResult!),
            ],
          ],
        ),
      );
    });
  }

  Widget _modeSelector(RetailerProvider p) {
    return Row(
      children: [
        Expanded(
          child: _modeOption(
            label: '🔄 Replace',
            subtitle: 'Clears existing menu',
            selected: p.uploadMode == 'replace',
            onTap: () => p.setUploadMode('replace'),
            color: AppTheme.error,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _modeOption(
            label: '➕ Append',
            subtitle: 'Adds to existing menu',
            selected: p.uploadMode == 'append',
            onTap: () => p.setUploadMode('append'),
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _extractionSelector(RetailerProvider p) {
    return Row(
      children: [
        Expanded(
          child: _modeOption(
            label: '📷 Standard OCR',
            subtitle: 'Fast, local processing',
            selected: p.extractionMethod == 'paddleocr',
            onTap: () => p.setExtractionMethod('paddleocr'),
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _modeOption(
            label: '✨ AI Vision',
            subtitle: 'Gemini Pro (Accurate)',
            selected: p.extractionMethod == 'vision',
            onTap: () => p.setExtractionMethod('vision'),
            color: const Color(0xFF9C27B0), // Purple for AI
          ),
        ),
      ],
    );
  }

  Widget _modeOption({
    required String label,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? color : AppTheme.divider,
              width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: selected ? color : AppTheme.textSecondary)),
            Text(subtitle,
                style: GoogleFonts.outfit(
                    fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _uploadResultCard(Map<String, dynamic> result) {
    final count = result['items_count'] ?? 0;
    final embedded = result['embedded_count'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.vegGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.vegGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.vegGreen, size: 18),
              const SizedBox(width: 8),
              Text('Upload Successful',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.vegGreen)),
            ],
          ),
          const SizedBox(height: 8),
          Text('$count items extracted  •  $embedded embeddings generated',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — SETTINGS
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cuisineCtrl = TextEditingController();
  String _priceCategory = 'mid-range';
  bool _dirty = false;
  final bool _showSetup = false;

  // Operational settings
  bool _hasDineIn = true;
  bool _hasTakeaway = true;
  bool _isOpenManually = true;
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  // Setup (new restaurant) fields
  final _setupNameCtrl = TextEditingController();
  final _setupAddressCtrl = TextEditingController();
  final _setupPhoneCtrl = TextEditingController();
  final _setupCuisineCtrl = TextEditingController();
  String _setupPriceCategory = 'mid-range';
  AreaModel? _selectedArea;

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}
    return null;
  }

  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = context.read<RetailerProvider>().myRestaurant;
    if (r != null && _nameCtrl.text.isEmpty) {
      _nameCtrl.text = r.restaurantName;
      _phoneCtrl.text = r.phone ?? '';
      _addressCtrl.text = r.address ?? '';
      _cuisineCtrl.text = r.cuisineType?.join(', ') ?? '';
      _priceCategory = r.priceCategory ?? 'mid-range';
      _hasDineIn = r.hasDineIn;
      _hasTakeaway = r.hasTakeaway;
      _isOpenManually = r.isOpenManually;
      _openingTime = _parseTime(r.openingTime);
      _closingTime = _parseTime(r.closingTime);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cuisineCtrl.dispose();
    _setupNameCtrl.dispose();
    _setupAddressCtrl.dispose();
    _setupPhoneCtrl.dispose();
    _setupCuisineCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(RetailerProvider p) async {
    final cuisines = _cuisineCtrl.text.trim().isNotEmpty
        ? _cuisineCtrl.text
            .trim()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : null;

    final ok = await p.updateRestaurant(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      cuisineType: cuisines,
      priceCategory: _priceCategory,
      hasDineIn: _hasDineIn,
      hasTakeaway: _hasTakeaway,
      isOpenManually: _isOpenManually,
      openingTime: _formatTime(_openingTime),
      closingTime: _formatTime(_closingTime),
    );

    if (mounted) {
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Settings saved!' : (p.errorMessage ?? 'Save failed'),
            style: GoogleFonts.outfit()),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _confirmClearMenu(RetailerProvider p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear All Menu Data',
            style: GoogleFonts.outfit(
                color: AppTheme.error, fontWeight: FontWeight.bold)),
        content: Text(
            'This will permanently delete ALL menu sections, items, and AI embeddings. This cannot be undone.',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style:
                      GoogleFonts.outfit(color: AppTheme.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Yes, Clear All',
                  style: GoogleFonts.outfit(
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (ok == true && mounted) {
      final cleared = await p.clearAllMenuData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            cleared ? 'All menu data cleared.' : (p.errorMessage ?? 'Failed'),
            style: GoogleFonts.outfit()),
        backgroundColor: cleared ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RetailerProvider>(builder: (context, p, _) {
      if (p.myRestaurant == null) {
        return _buildSetupForm(p);
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Restaurant Profile'),
            const SizedBox(height: 12),
            _formField(_nameCtrl, 'Restaurant Name',
                Icons.storefront_rounded),
            const SizedBox(height: 10),
            _formField(
                _phoneCtrl, 'Phone Number', Icons.phone_rounded,
                type: TextInputType.phone),
            const SizedBox(height: 10),
            _formField(
                _addressCtrl, 'Street Address', Icons.location_on_rounded,
                maxLines: 2),
            const SizedBox(height: 10),
            _formField(_cuisineCtrl, 'Cuisine Types (comma separated)',
                Icons.restaurant_menu_rounded),
            const SizedBox(height: 14),
            _priceSelector(),
            const SizedBox(height: 24),
            _buildOperationalSettings(),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: p.state == RetailerState.loading
                    ? null
                    : () => _save(p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: p.state == RetailerState.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Save Changes',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 32),
            _sectionLabel('Danger Zone'),
            const SizedBox(height: 12),

            // Clear menu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clear All Menu Data',
                      style: GoogleFonts.outfit(
                          color: AppTheme.error,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      'Deletes all menu sections, items, and AI embeddings. Use this before a complete re-upload.',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _confirmClearMenu(p),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: Text('Clear All Menu',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSetupForm(RetailerProvider p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Register your restaurant to unlock all dashboard features.',
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _formField(_setupNameCtrl, 'Restaurant Name *',
              Icons.storefront_rounded),
          const SizedBox(height: 10),
          _buildAreaDropdown(p),
          const SizedBox(height: 10),
          _formField(_setupPhoneCtrl, 'Phone', Icons.phone_rounded,
              type: TextInputType.phone),
          const SizedBox(height: 10),
          _formField(_setupAddressCtrl, 'Address', Icons.location_on_rounded,
              maxLines: 2),
          const SizedBox(height: 10),
          _formField(_setupCuisineCtrl, 'Cuisine Types (comma separated)',
              Icons.restaurant_menu_rounded),
          const SizedBox(height: 14),
          _setupPriceSelector(),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: p.state == RetailerState.loading
                  ? null
                  : () async {
                      final name = _setupNameCtrl.text.trim();
                      if (name.isEmpty || _selectedArea == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Name and area are required.',
                              style: GoogleFonts.outfit()),
                          backgroundColor: AppTheme.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                        return;
                      }
                      final cuisines = _setupCuisineCtrl.text.trim().isNotEmpty
                          ? _setupCuisineCtrl.text
                              .trim()
                              .split(',')
                              .map((e) => e.trim())
                              .toList()
                          : null;
                      await p.setupRestaurant(
                        name: name,
                        areaId: _selectedArea!.areaId,
                        priceCategory: _setupPriceCategory,
                        cuisines: cuisines,
                        address: _setupAddressCtrl.text.trim().isEmpty
                            ? null
                            : _setupAddressCtrl.text.trim(),
                        phone: _setupPhoneCtrl.text.trim().isEmpty
                            ? null
                            : _setupPhoneCtrl.text.trim(),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: p.state == RetailerState.loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Register Restaurant',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_rounded, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Operational Settings',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage booking options, takeaway availability, and store hours.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const Divider(height: 30),
          
          // Dine-In Switch
          _buildToggleOption(
            title: 'Dine-In Bookings',
            subtitle: 'Allow customers to reserve tables online',
            icon: Icons.deck_rounded,
            value: _hasDineIn,
            onChanged: (val) => setState(() {
              _hasDineIn = val;
              _dirty = true;
            }),
            activeColor: AppTheme.primary,
          ),
          const SizedBox(height: 16),

          // Takeaway Switch
          _buildToggleOption(
            title: 'Takeaway Orders',
            subtitle: 'Enable online ordering for self-pickup',
            icon: Icons.shopping_bag_rounded,
            value: _hasTakeaway,
            onChanged: (val) => setState(() {
              _hasTakeaway = val;
              _dirty = true;
            }),
            activeColor: AppTheme.primary,
          ),
          const SizedBox(height: 16),

          // Open Manually Switch
          _buildToggleOption(
            title: 'Store Status',
            subtitle: 'Force store status as open/closed (manual override)',
            icon: Icons.store_rounded,
            value: _isOpenManually,
            onChanged: (val) => setState(() {
              _isOpenManually = val;
              _dirty = true;
            }),
            activeColor: AppTheme.success,
          ),
          const Divider(height: 30),

          // Timing section
          Text(
            'Operational Hours',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTimePickerField(
                  label: 'Opening Time',
                  time: _openingTime,
                  onTap: () => _selectTime(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimePickerField(
                  label: 'Closing Time',
                  time: _closingTime,
                  onTap: () => _selectTime(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: activeColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
        ),
      ],
    );
  }

  Widget _buildTimePickerField({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: AppTheme.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time != null ? time.format(context) : 'Not Set',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: time != null ? AppTheme.textPrimary : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(bool isOpening) async {
    final initialTime = (isOpening ? _openingTime : _closingTime) ?? const TimeOfDay(hour: 9, minute: 0);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
        _dirty = true;
      });
    }
  }

  Widget _formField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        onChanged: (_) => setState(() => _dirty = true),
        style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(
              color: AppTheme.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary));
  }

  Widget _priceSelector() {
    return _buildPriceWidget(
      current: _priceCategory,
      onSelect: (v) => setState(() {
        _priceCategory = v;
        _dirty = true;
      }),
    );
  }

  Widget _setupPriceSelector() {
    return _buildPriceWidget(
      current: _setupPriceCategory,
      onSelect: (v) => setState(() => _setupPriceCategory = v),
    );
  }

  Widget _buildPriceWidget({
    required String current,
    required Function(String) onSelect,
  }) {
    final cats = [
      ('budget', '₹ Budget', const Color(0xFF2ECC71)),
      ('mid-range', '₹₹ Mid-Range', const Color(0xFFF39C12)),
      ('premium', '₹₹₹ Premium', const Color(0xFF9B59B6)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price Category',
            style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: cats.map((c) {
            final selected = current == c.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(c.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? c.$3.withValues(alpha: 0.12)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? c.$3 : AppTheme.divider,
                        width: selected ? 1.5 : 1),
                  ),
                  child: Text(c.$2,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected ? c.$3 : AppTheme.textSecondary)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAreaDropdown(RetailerProvider p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_rounded,
              color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AreaModel>(
                value: _selectedArea,
                hint: Text('Select Area *',
                    style: GoogleFonts.outfit(
                        color: AppTheme.textMuted, fontSize: 13)),
                isExpanded: true,
                dropdownColor: AppTheme.surface,
                style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary),
                items: p.areas
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text('${a.areaName}, ${a.city}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedArea = v),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — HISTORY
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<RetailerProvider>(builder: (context, p, _) {
      final history = p.uploadHistory;

      if (history.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_rounded,
                  size: 56, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text('No uploads yet',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text('Your menu upload history will appear here.',
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: history.length,
        itemBuilder: (ctx, i) {
          final h = history[i];
          final isOk = h.status == 'Completed';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: (isOk ? AppTheme.vegGreen : AppTheme.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isOk
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: isOk ? AppTheme.vegGreen : AppTheme.error,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOk
                            ? '${h.itemsExtracted} items extracted'
                            : 'Upload failed',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary),
                      ),
                      Text(
                        '${_formatDate(h.timestamp)}  •  ${h.mode == 'replace' ? 'Replace' : 'Append'} mode',
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isOk ? AppTheme.vegGreen : AppTheme.error)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(h.status,
                      style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: isOk ? AppTheme.vegGreen : AppTheme.error,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
        },
      );
    });
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 5 — BOOKINGS
// ─────────────────────────────────────────────────────────────────────────────

class _BookingsTab extends StatefulWidget {
  const _BookingsTab();

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RetailerProvider>().fetchBookings();
    });
  }

  void _updateStatus(String bookingId, String status) {
    context.read<RetailerProvider>().updateBookingStatus(bookingId, status).then((success) {
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status', style: GoogleFonts.outfit()), backgroundColor: AppTheme.error));
      }
    });

    String msg = status == 'CONFIRMED'
        ? 'Message sent to user: "your table has been booked successfully"'
        : 'Message sent to user: "sorry, restaurant is not currently accepting table bookings"';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Status Updated', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        content: Text('Dine-In Booking status updated to $status.\n\n$msg', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RetailerProvider>(
      builder: (context, provider, _) {
        final bookings = provider.bookings.where((b) => b.status == 'PENDING').toList();
        
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.deck_rounded, size: 56, color: AppTheme.textMuted),
                const SizedBox(height: 12),
                Text('No Bookings Yet', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text('Incoming table reservations will appear here.', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Clear All Bookings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      content: Text('Are you sure you want to delete all bookings for this restaurant?', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                          onPressed: () {
                            context.read<RetailerProvider>().clearAllBookings();
                            Navigator.pop(context);
                          },
                          child: Text('Clear All', style: GoogleFonts.outfit(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error, size: 20),
                label: Text('Clear All', style: GoogleFonts.outfit(color: AppTheme.error, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                itemCount: bookings.length,
                itemBuilder: (ctx, i) {
                  final b = bookings[i];
                  final status = b.status;
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
                            Text('Booking #${b.bookingId.substring(0, 8)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Text(status, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text('Party of ${b.partySize}', style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary)),
                            const SizedBox(width: 24),
                            const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(b.timeSlot, style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary)),
                          ],
                        ),
                        if (b.customerName != null || b.customerPhone != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (b.customerName != null) ...[
                                const Icon(Icons.badge_outlined, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Text(b.customerName!, style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary)),
                                const SizedBox(width: 16),
                              ],
                              if (b.customerPhone != null) ...[
                                const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Text(b.customerPhone!, style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary)),
                              ],
                            ],
                          ),
                        ],
                        if (status == 'PENDING') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _updateStatus(b.bookingId, 'REJECTED'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.error,
                                    side: const BorderSide(color: AppTheme.error),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text('Reject', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _updateStatus(b.bookingId, 'CONFIRMED'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.success,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: Text('Confirm', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 6 — TAKEAWAY ORDERS
// ─────────────────────────────────────────────────────────────────────────────

class _TakeawayTab extends StatefulWidget {
  const _TakeawayTab();

  @override
  State<_TakeawayTab> createState() => _TakeawayTabState();
}

class _TakeawayTabState extends State<_TakeawayTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RetailerProvider>().fetchTakeawayOrders();
    });
  }

  void _updateStatus(String orderId, String status) {
    context.read<RetailerProvider>().updateTakeawayOrderStatus(orderId, status).then((success) {
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status', style: GoogleFonts.outfit()), backgroundColor: AppTheme.error));
      }
    });

    String msg = status == 'CONFIRMED'
        ? 'Message sent to user: "thanks for placing the order"'
        : 'Message sent to user: "sorry restaurant is not currently accepting any order"';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Status Updated', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        content: Text('Takeaway Order status updated to $status.\n\n$msg', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RetailerProvider>(
      builder: (context, p, _) {
        if (p.myRestaurant == null) {
          return const Center(child: Text('Please setup your restaurant first.'));
        }

        final orders = p.takeawayOrders.where((o) => o.status == 'PENDING').toList();
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.textMuted),
                const SizedBox(height: 16),
                Text('No Takeaway Orders yet', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 16)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Clear All Orders', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      content: Text('Are you sure you want to delete all takeaway orders for this restaurant?', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                          onPressed: () {
                            context.read<RetailerProvider>().clearAllTakeawayOrders();
                            Navigator.pop(context);
                          },
                          child: Text('Clear All', style: GoogleFonts.outfit(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error, size: 20),
                label: Text('Clear All', style: GoogleFonts.outfit(color: AppTheme.error, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
            final o = orders[i];
            final status = o.status;
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
                      Text('Order #${o.orderId.substring(0, 8)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(status, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Text(o.timeSlot, style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary)),
                      const Spacer(),
                      Text('₹${o.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Text(o.customerName, style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary)),
                      const SizedBox(width: 16),
                      const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Text(o.customerPhone, style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Items:', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  ...o.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.quantity}x ${item.itemName}', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary)),
                        Text('₹${item.price.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )),
                  if (status == 'PENDING') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(o.orderId, 'REJECTED'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: const BorderSide(color: AppTheme.error),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('Reject', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(o.orderId, 'CONFIRMED'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: Text('Confirm', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewsTab extends StatefulWidget {
  const _ReviewsTab();

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<RetailerProvider>();
      if (p.myRestaurant != null) {
        context.read<ReviewsProvider>().fetchRestaurantReviews(p.myRestaurant!.restaurantId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        final reviews = provider.restaurantReviews;

        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_outline_rounded, size: 64, color: AppTheme.textMuted),
                const SizedBox(height: 16),
                Text('No Reviews Yet', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Text('Customer reviews will appear here.', style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final p = context.read<RetailerProvider>();
                    if (p.myRestaurant != null) {
                      await provider.clearRestaurantReviews(p.myRestaurant!.restaurantId);
                    }
                  },
                  icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error, size: 18),
                  label: Text('Clear All', style: GoogleFonts.outfit(color: AppTheme.error, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
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
              ),
            ),
          ],
        );
      },
    );
  }
}
