import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/admin_provider.dart';
import 'admin_areas_screen.dart';
import 'admin_restaurants_screen.dart';
import 'admin_menu_items_screen.dart';
import 'admin_approvals_screen.dart';
import 'upload_screen.dart';
import 'customer_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchRestaurants();
    });
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Logout', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out of the admin panel?',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              context.read<AdminProvider>().logout();
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
                (route) => false,
              );
            },
            child: Text('Logout', style: GoogleFonts.outfit(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text('Admin Dashboard',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
            onPressed: () => _confirmLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFFE0873A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
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
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Welcome, Admin',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          if (provider.adminEmail != null)
                            Text(provider.adminEmail!,
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                        ]),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                const SizedBox(height: 20),

                // Restaurant Selector
                Text('Select Restaurant', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold))
                    .animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 10),

                provider.state == AdminState.loading && provider.restaurants.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.selectedRestaurant?.restaurantId,
                            hint: Text('Choose a restaurant…', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                            isExpanded: true,
                            dropdownColor: AppTheme.surface,
                            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 15),
                            items: provider.restaurants.map((r) {
                              return DropdownMenuItem<String>(
                                value: r.restaurantId,
                                child: Text(r.restaurantName),
                              );
                            }).toList(),
                            onChanged: (id) {
                              if (id == null) return;
                              final r = provider.restaurants.firstWhere((r) => r.restaurantId == id);
                              provider.selectRestaurant(r);
                              provider.fetchDashboardStats();
                            },
                          ),
                        ),
                      ).animate().fadeIn(delay: 150.ms),

                // Stats Cards (shown only when restaurant is selected)
                if (provider.selectedRestaurant != null) ...[
                  const SizedBox(height: 20),
                  Text('Live Statistics', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold))
                      .animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),

                  provider.state == AdminState.loading && provider.dashboardStats == null
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: AppTheme.primary),
                        ))
                      : provider.dashboardStats != null
                          ? _buildStatsGrid(provider.dashboardStats!)
                          : Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Text(
                                provider.errorMessage ?? 'Could not load stats.',
                                style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                              ),
                            ),
                ],

                const SizedBox(height: 28),

                // Modules
                Text('Modules', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold))
                    .animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 12),

                _buildModuleCard(
                  context: context,
                  title: 'Areas Management',
                  subtitle: 'View and create neighborhoods and cities',
                  icon: Icons.map_rounded,
                  color: const Color(0xFF3498DB),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAreasScreen())),
                  delay: 350,
                ),
                const SizedBox(height: 12),
                _buildModuleCard(
                  context: context,
                  title: 'Restaurant Management',
                  subtitle: 'Add new restaurants and assign them to areas',
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF2ECC71),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRestaurantsScreen())),
                  delay: 400,
                ),
                const SizedBox(height: 12),
                _buildModuleCard(
                  context: context,
                  title: 'Menu Items',
                  subtitle: 'View, edit, and delete menu items for a restaurant',
                  icon: Icons.restaurant_menu_rounded,
                  color: const Color(0xFFE67E22),
                  onTap: provider.selectedRestaurant == null
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Select a restaurant first', style: GoogleFonts.outfit()),
                              backgroundColor: AppTheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          )
                      : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMenuItemsScreen())),
                  delay: 450,
                ),
                const SizedBox(height: 12),
                _buildModuleCard(
                  context: context,
                  title: 'Menu Digitization',
                  subtitle: 'Upload menu images for OCR processing',
                  icon: Icons.document_scanner_rounded,
                  color: const Color(0xFF9B59B6),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen())),
                  delay: 500,
                ),
                const SizedBox(height: 12),
                _buildModuleCard(
                  context: context,
                  title: 'Pending Approvals',
                  subtitle: 'Approve new restaurant registrations',
                  icon: Icons.verified_user_rounded,
                  color: const Color(0xFFE74C3C),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminApprovalsScreen())),
                  delay: 550,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(AdminDashboardStats stats) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _statCard('Total Items', '${stats.totalItems}', Icons.fastfood_rounded, const Color(0xFF3498DB))),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Sections', '${stats.totalSections}', Icons.category_rounded, const Color(0xFF2ECC71))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statCard('Uploads', '${stats.totalUploads}', Icons.cloud_upload_rounded, const Color(0xFF9B59B6))),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Avg Price', stats.avgPrice != null ? '₹${stats.avgPrice!.toStringAsFixed(0)}' : '—', Icons.currency_rupee_rounded, const Color(0xFFE67E22))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statCard('🥦 Veg', '${stats.vegItems}', Icons.eco_rounded, const Color(0xFF27AE60))),
          const SizedBox(width: 12),
          Expanded(child: _statCard('🍗 Non-Veg', '${stats.nonVegItems}', Icons.set_meal_rounded, const Color(0xFFE74C3C))),
        ]),
      ],
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.05, end: 0);
  }
}
