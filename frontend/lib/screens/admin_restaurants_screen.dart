import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/admin_provider.dart';
import '../models/area_model.dart';

class AdminRestaurantsScreen extends StatefulWidget {
  const AdminRestaurantsScreen({super.key});

  @override
  State<AdminRestaurantsScreen> createState() => _AdminRestaurantsScreenState();
}

class _AdminRestaurantsScreenState extends State<AdminRestaurantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchRestaurants();
      // Ensure we have areas loaded for the dropdown when creating a new restaurant
      if (context.read<AdminProvider>().areas.isEmpty) {
        context.read<AdminProvider>().fetchAreas();
      }
    });
  }

  void _showAddRestaurantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddRestaurantBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text('Restaurants', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRestaurantSheet,
        backgroundColor: const Color(0xFF2ECC71),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('New Rest', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.state == AdminState.loading && provider.restaurants.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
          }
          if (provider.state == AdminState.error && provider.restaurants.isEmpty) {
            return Center(child: Text(provider.errorMessage ?? 'Failed to load', style: GoogleFonts.outfit(color: AppTheme.error)));
          }
          if (provider.restaurants.isEmpty) {
            return Center(child: Text('No restaurants found. Add your first one.', style: GoogleFonts.outfit(color: AppTheme.textSecondary)));
          }

          return RefreshIndicator(
            onRefresh: provider.fetchRestaurants,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
              itemCount: provider.restaurants.length,
              itemBuilder: (context, index) {
                final r = provider.restaurants[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                          color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Color(0xFF2ECC71)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.restaurantName, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 4),
                            Text('Cuisine: ${r.cuisineType?.join(', ') ?? 'Any'} • ${r.priceCategory}', 
                                 style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: r.isActive ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(r.isActive ? 'Active' : 'Offline', style: GoogleFonts.outfit(fontSize: 10, color: r.isActive ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 50 * index.clamp(0, 10))).slideX(begin: 0.05, end: 0);
              },
            ),
          );
        },
      ),
    );
  }
}

class _AddRestaurantBottomSheet extends StatefulWidget {
  const _AddRestaurantBottomSheet();

  @override
  State<_AddRestaurantBottomSheet> createState() => _AddRestaurantBottomSheetState();
}

class _AddRestaurantBottomSheetState extends State<_AddRestaurantBottomSheet> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cuisinesCtrl = TextEditingController();
  
  String _selectedPriceCategory = 'mid-range';
  AreaModel? _selectedArea;

  Future<void> _submit() async {
    final provider = context.read<AdminProvider>();
    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant Name is required')));
      return;
    }
    if (_selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an Area')));
      return;
    }

    final cuisinesList = _cuisinesCtrl.text.trim().isNotEmpty 
        ? _cuisinesCtrl.text.trim().split(',').map((e) => e.trim()).toList()
        : null;

    final success = await provider.createRestaurant(
      name,
      _selectedArea!.areaId,
      _selectedPriceCategory,
      cuisines: cuisinesList,
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant created!'), backgroundColor: AppTheme.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8, // Make it tall enough constraints
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Text('Add New Restaurant', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildField('Restaurant Name *', 'e.g. Subways', _nameCtrl),
                    const SizedBox(height: 16),
                    
                    // Area Dropdown
                    Consumer<AdminProvider>(
                      builder: (ctx, provider, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<AreaModel>(
                              value: _selectedArea,
                              hint: Text('Select Area *', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                              isExpanded: true,
                              dropdownColor: AppTheme.surface,
                              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                              items: provider.areas.map((area) {
                                return DropdownMenuItem<AreaModel>(
                                  value: area,
                                  child: Text('${area.areaName}, ${area.city}'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedArea = val);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price Category Dropdown
                    Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPriceCategory,
                              isExpanded: true,
                              dropdownColor: AppTheme.surface,
                              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                              items: const [
                                DropdownMenuItem(value: 'budget', child: Text('Budget (₹)')),
                                DropdownMenuItem(value: 'mid-range', child: Text('Mid-Range (₹₹)')),
                                DropdownMenuItem(value: 'premium', child: Text('Premium (₹₹₹)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedPriceCategory = val);
                              },
                            ),
                          ),
                        ),
                    const SizedBox(height: 16),

                    _buildField('Cuisines (comma separated)', 'e.g. Italian, Fast Food', _cuisinesCtrl),
                    const SizedBox(height: 16),
                    _buildField('Address', 'Full street address', _addressCtrl),
                    const SizedBox(height: 16),
                    _buildField('Phone', 'e.g. 9876543210', _phoneCtrl, 
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        prefixText: '+91 ',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Consumer<AdminProvider>(
              builder: (ctx, provider, child) => ElevatedButton(
                onPressed: provider.state == AdminState.loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: provider.state == AdminState.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Create Restaurant', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, String? prefixText}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.outfit(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefixText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
