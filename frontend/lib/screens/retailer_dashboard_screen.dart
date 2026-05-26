import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../providers/retailer_provider.dart';
import '../models/area_model.dart';

class RetailerDashboardScreen extends StatefulWidget {
  const RetailerDashboardScreen({super.key});

  @override
  State<RetailerDashboardScreen> createState() => _RetailerDashboardScreenState();
}

class _RetailerDashboardScreenState extends State<RetailerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RetailerProvider>().fetchAreas();
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
        title: Text('Sign Out', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to sign out of the restaurant portal?',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              context.read<RetailerProvider>().logout();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Sign Out', style: GoogleFonts.outfit(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _SetupTab(),
            _MenuUploadTab(),
            _DashboardOverviewTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool collapsed) {
    return Consumer<RetailerProvider>(
      builder: (context, provider, _) {
        final restaurantName = provider.myRestaurant?.restaurantName ?? 'My Restaurant';
        return SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppTheme.surface,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
              onPressed: _confirmLogout,
              tooltip: 'Sign Out',
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
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurantName,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  provider.myRestaurant != null
                                      ? 'Restaurant Portal • Active'
                                      : 'Restaurant Portal • Setup Required',
                                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: provider.myRestaurant != null
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.orange.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: provider.myRestaurant != null
                                    ? Colors.greenAccent.withValues(alpha: 0.5)
                                    : Colors.orangeAccent.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              provider.myRestaurant != null ? 'Live' : 'Setup',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: AppTheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
                tabs: const [
                  Tab(text: 'Setup'),
                  Tab(text: 'Menu Upload'),
                  Tab(text: 'Overview'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: SETUP — Name restaurant + select area
// ─────────────────────────────────────────────────────────────────────────────

class _SetupTab extends StatefulWidget {
  const _SetupTab();

  @override
  State<_SetupTab> createState() => _SetupTabState();
}

class _SetupTabState extends State<_SetupTab> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cuisinesCtrl = TextEditingController();
  String _priceCategory = 'mid-range';
  AreaModel? _selectedArea;
  bool _showSuccess = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _cuisinesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<RetailerProvider>();
    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      _showError('Restaurant name is required.');
      return;
    }
    if (_selectedArea == null) {
      _showError('Please select your area.');
      return;
    }

    final cuisines = _cuisinesCtrl.text.trim().isNotEmpty
        ? _cuisinesCtrl.text.trim().split(',').map((e) => e.trim()).toList()
        : null;

    final success = await provider.setupRestaurant(
      name: name,
      areaId: _selectedArea!.areaId,
      priceCategory: _priceCategory,
      cuisines: cuisines,
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );

    if (success && mounted) {
      setState(() => _showSuccess = true);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RetailerProvider>();

    // If already set up, show "already configured" view
    if (provider.myRestaurant != null) {
      return _buildAlreadySetupView(provider);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set Up Your Restaurant', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      Text('Name your restaurant and select its location area.', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          Text('Restaurant Details', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),

          // Restaurant Name
          _buildFormField(
            controller: _nameCtrl,
            label: 'Restaurant Name *',
            hint: 'e.g. Pranil Da Dhaba',
            icon: Icons.storefront_rounded,
            delay: 150,
          ),
          const SizedBox(height: 14),

          // Area Dropdown
          _buildAreaDropdown(provider).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 14),

          // Price Category
          _buildPriceCategorySelector().animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 22),

          Text('Additional Info (Optional)', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))
              .animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 12),

          _buildFormField(
            controller: _cuisinesCtrl,
            label: 'Cuisine Types',
            hint: 'e.g. North Indian, Chinese',
            icon: Icons.restaurant_menu_rounded,
            delay: 350,
          ),
          const SizedBox(height: 14),
          _buildFormField(
            controller: _addressCtrl,
            label: 'Street Address',
            hint: 'Full address of your restaurant',
            icon: Icons.location_on_rounded,
            delay: 400,
          ),
          const SizedBox(height: 14),
          _buildFormField(
            controller: _phoneCtrl,
            label: 'Contact Number',
            hint: 'e.g. 9876543210',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            delay: 450,
          ),
          const SizedBox(height: 30),

          // Submit Button
          Consumer<RetailerProvider>(
            builder: (ctx, prov, _) => SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: prov.state == RetailerState.loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: prov.state == RetailerState.loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text('Register Restaurant', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAlreadySetupView(RetailerProvider provider) {
    final r = provider.myRestaurant!;
    final area = provider.areas.where((a) => a.areaId == r.areaId).firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4E6E4D), Color(0xFF2D5A27)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4E6E4D).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
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
                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Restaurant Live!', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('Your restaurant is registered and active.', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 24),
          Text('Restaurant Profile', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),

          // Detail Cards
          _buildDetailCard('Restaurant Name', r.restaurantName, Icons.storefront_rounded, const Color(0xFFC19A6B), delay: 100),
          _buildDetailCard('Location', area != null ? '${area.areaName}, ${area.city}' : 'Area on file', Icons.location_on_rounded, const Color(0xFF3498DB), delay: 150),
          _buildDetailCard('Price Category', r.priceCategoryDisplay.isNotEmpty ? r.priceCategoryDisplay : 'Mid-Range', Icons.currency_rupee_rounded, const Color(0xFF2ECC71), delay: 200),
          if (r.cuisineDisplay.isNotEmpty && r.cuisineDisplay != 'Various Cuisines')
            _buildDetailCard('Cuisines', r.cuisineDisplay, Icons.restaurant_menu_rounded, const Color(0xFF9B59B6), delay: 250),
          if (r.address != null)
            _buildDetailCard('Address', r.address!, Icons.map_rounded, const Color(0xFFE67E22), delay: 300),
          if (r.phone != null)
            _buildDetailCard('Phone', r.phone!, Icons.phone_rounded, const Color(0xFF1ABC9C), delay: 350),

          const SizedBox(height: 20),
          // Update info note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_rounded, color: AppTheme.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'To update your restaurant details, please contact support or re-register below.',
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              context.read<RetailerProvider>().resetRestaurant();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('Re-Register Restaurant', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ).animate().fadeIn(delay: 450.ms),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, Color color, {required int delay}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                Text(value, style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.05, end: 0);
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int delay,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
          hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAreaDropdown(RetailerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_rounded, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AreaModel>(
                value: _selectedArea,
                hint: Text('Select Your Area *', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13)),
                isExpanded: true,
                dropdownColor: AppTheme.surface,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                items: provider.areas.map((area) {
                  return DropdownMenuItem<AreaModel>(
                    value: area,
                    child: Text('${area.areaName}, ${area.city}'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedArea = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCategorySelector() {
    final categories = [
      {'value': 'budget', 'label': '₹ Budget', 'color': const Color(0xFF2ECC71)},
      {'value': 'mid-range', 'label': '₹₹ Mid-Range', 'color': const Color(0xFFF39C12)},
      {'value': 'premium', 'label': '₹₹₹ Premium', 'color': const Color(0xFF9B59B6)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price Category', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: categories.map((cat) {
            final isSelected = _priceCategory == cat['value'];
            final color = cat['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _priceCategory = cat['value'] as String),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : AppTheme.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    cat['label'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: MENU UPLOAD
// ─────────────────────────────────────────────────────────────────────────────

class _MenuUploadTab extends StatefulWidget {
  const _MenuUploadTab();

  @override
  State<_MenuUploadTab> createState() => _MenuUploadTabState();
}

class _MenuUploadTabState extends State<_MenuUploadTab> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (picked != null && mounted) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Select Image Source', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            _buildSourceOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              color: const Color(0xFF3498DB),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const Divider(height: 1, color: AppTheme.divider, indent: 20, endIndent: 20),
            _buildSourceOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              color: const Color(0xFF2ECC71),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
    );
  }

  Future<void> _upload(RetailerProvider provider) async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a menu image first.', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (provider.myRestaurant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete restaurant setup first.', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final success = await provider.uploadMenu(_selectedImage!);
    if (success && mounted) {
      setState(() => _selectedImage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RetailerProvider>(
      builder: (context, provider, _) {
        final setupDone = provider.myRestaurant != null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Setup warning if not done
              if (!setupDone)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Complete restaurant setup before uploading your menu.',
                          style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // Image Picker Card
              GestureDetector(
                onTap: (provider.isUploading || provider.isProcessing) ? null : _showImageSourcePicker,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 220,
                  decoration: BoxDecoration(
                    color: _selectedImage == null ? AppTheme.surfaceAlt : null,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedImage != null ? AppTheme.primary : AppTheme.divider,
                      width: _selectedImage != null ? 2 : 1.5,
                      style: _selectedImage == null ? BorderStyle.solid : BorderStyle.solid,
                    ),
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null
                      ? _buildImagePlaceholder()
                      : _buildImageOverlay(),
                ),
              ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.97, 0.97)),

              const SizedBox(height: 20),

              // Status area
              if (provider.isUploading || provider.isProcessing)
                _buildStatusCard(provider)
              else if (provider.lastUploadStatus != null && provider.lastUploadStatus!.isCompleted)
                _buildSuccessCard(provider)
              else if (provider.errorMessage != null)
                _buildErrorCard(provider.errorMessage!),

              const SizedBox(height: 20),

              // Action buttons row
              if (!provider.isUploading && !provider.isProcessing) ...[
                if (_selectedImage != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showImageSourcePicker,
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: Text('Change', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.divider),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: setupDone ? () => _upload(provider) : null,
                          icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: Text('Upload Menu', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                ] else
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _showImageSourcePicker,
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                      label: Text('Select Menu Image', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
              ],

              const SizedBox(height: 28),

              // Upload History
              if (provider.uploadHistory.isNotEmpty) ...[
                Text('Upload History', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))
                    .animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 12),
                ...provider.uploadHistory.map((item) => _buildHistoryTile(item)).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.document_scanner_rounded, color: AppTheme.primary, size: 36),
        ),
        const SizedBox(height: 16),
        Text('Tap to add menu image', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 6),
        Text('Gallery or Camera • JPG, PNG', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildImageOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text('Tap to change image', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(RetailerProvider provider) {
    final isUploading = provider.isUploading;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUploading ? 'Uploading menu...' : 'AI Processing...',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  isUploading ? 'Sending image to server' : 'Extracting menu items with AI',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms);
  }

  Widget _buildSuccessCard(RetailerProvider provider) {
    final count = provider.lastUploadStatus?.itemsCount ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Menu Processed!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.success)),
                Text(count > 0 ? '$count menu items extracted successfully.' : 'Menu uploaded and processed.',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: AppTheme.error, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(error, style: GoogleFonts.outfit(color: AppTheme.error, fontSize: 13)),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildHistoryTile(dynamic item) {
    final isSuccess = item.status == 'Completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isSuccess ? AppTheme.success : AppTheme.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isSuccess ? Icons.check_rounded : Icons.close_rounded,
              color: isSuccess ? AppTheme.success : AppTheme.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSuccess ? '${item.itemsExtracted} items extracted' : 'Upload failed',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 13),
                ),
                Text(
                  _formatDate(item.timestamp),
                  style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isSuccess ? AppTheme.success : AppTheme.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.status,
              style: GoogleFonts.outfit(
                color: isSuccess ? AppTheme.success : AppTheme.error,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: OVERVIEW / DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardOverviewTab extends StatelessWidget {
  const _DashboardOverviewTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<RetailerProvider>(
      builder: (context, provider, _) {
        final r = provider.myRestaurant;
        final history = provider.uploadHistory;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats Row
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.upload_rounded,
                    label: 'Total Uploads',
                    value: '${history.length}',
                    color: const Color(0xFF3498DB),
                    delay: 0,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Items Extracted',
                    value: '${history.fold<int>(0, (s, e) => s + (e.itemsExtracted as int))}',
                    color: const Color(0xFF2ECC71),
                    delay: 100,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Successful',
                    value: '${history.where((e) => e.status == 'Completed').length}',
                    color: const Color(0xFF4E6E4D),
                    delay: 150,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.storefront_rounded,
                    label: 'Status',
                    value: r != null ? 'Live' : 'Setup',
                    color: r != null ? const Color(0xFF4E6E4D) : const Color(0xFFD4AC0D),
                    delay: 200,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text('Quick Actions', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))
                  .animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.document_scanner_rounded,
                title: 'Upload New Menu',
                subtitle: 'Scan and digitize your restaurant menu',
                color: const Color(0xFFC19A6B),
                onTap: () {
                  // Switch to upload tab
                  final tabController = context.findAncestorStateOfType<_RetailerDashboardScreenState>()?._tabController;
                  tabController?.animateTo(1);
                },
                delay: 300,
              ),
              _buildActionCard(
                icon: Icons.edit_rounded,
                title: 'Edit Restaurant Profile',
                subtitle: 'Update name, area, or cuisine details',
                color: const Color(0xFF3498DB),
                onTap: () {
                  final tabController = context.findAncestorStateOfType<_RetailerDashboardScreenState>()?._tabController;
                  tabController?.animateTo(0);
                },
                delay: 350,
              ),
              _buildActionCard(
                icon: Icons.history_rounded,
                title: 'Upload History',
                subtitle: 'View all previous menu uploads',
                color: const Color(0xFF9B59B6),
                onTap: () {
                  final tabController = context.findAncestorStateOfType<_RetailerDashboardScreenState>()?._tabController;
                  tabController?.animateTo(1);
                },
                delay: 400,
              ),

              const SizedBox(height: 24),

              if (r != null) ...[
                Text('Restaurant Info', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))
                    .animate().fadeIn(delay: 450.ms),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary.withValues(alpha: 0.1), AppTheme.accent.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.storefront_rounded, 'Name', r.restaurantName),
                      const Divider(height: 20, color: AppTheme.divider),
                      _buildInfoRow(Icons.currency_rupee_rounded, 'Price', r.priceCategoryDisplay),
                      if (r.cuisineDisplay != 'Various Cuisines') ...[
                        const Divider(height: 20, color: AppTheme.divider),
                        _buildInfoRow(Icons.restaurant_menu_rounded, 'Cuisines', r.cuisineDisplay),
                      ],
                      if (r.phone != null) ...[
                        const Divider(height: 20, color: AppTheme.divider),
                        _buildInfoRow(Icons.phone_rounded, 'Phone', r.phone!),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int delay,
  }) {
    return Expanded(
      child: Container(
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
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: delay)).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.05, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 16),
        const SizedBox(width: 10),
        Text('$label: ', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13)),
        Expanded(
          child: Text(value, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }
}
