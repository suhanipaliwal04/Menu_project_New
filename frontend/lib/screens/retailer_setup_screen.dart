import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../models/area_model.dart';
import '../providers/retailer_provider.dart';
import '../services/location_service.dart';
import 'retailer_dashboard_screen.dart';

class RetailerSetupScreen extends StatefulWidget {
  const RetailerSetupScreen({super.key});

  @override
  State<RetailerSetupScreen> createState() => _RetailerSetupScreenState();
}

class _RetailerSetupScreenState extends State<RetailerSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cuisinesCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  AreaModel? _selectedArea;
  String _priceCategory = 'mid-range';
  int _step = 0;

  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RetailerProvider>().fetchAreas();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _cuisinesCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        _showSnack('Please enter your restaurant name.');
        return;
      }
    }
    if (_step == 1) {
      if (_selectedArea == null) {
        _showSnack('Please select an area for your restaurant.');
        return;
      }
    }

    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  Future<void> _submit() async {
    final provider = context.read<RetailerProvider>();
    final cuisinesList = _cuisinesCtrl.text.trim().isNotEmpty
        ? _cuisinesCtrl.text.trim().split(',').map((e) => e.trim()).toList()
        : null;

    final success = await provider.setupRestaurant(
      name: _nameCtrl.text.trim(),
      areaId: _selectedArea!.areaId,
      priceCategory: _priceCategory,
      cuisines: cuisinesList,
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      latitude: double.tryParse(_latCtrl.text.trim()),
      longitude: double.tryParse(_lngCtrl.text.trim()),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const RetailerDashboardScreen()));
    } else {
      _showSnack(provider.errorMessage ?? 'Setup failed. Try again.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                onPressed: _prevStep,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text('Set Up Your Restaurant',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(3, (i) {
                final isActive = i <= _step;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary : AppTheme.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Step ${_step + 1} of 3',
                    style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary, fontSize: 12)),
                Text(
                  ['Basic Info', 'Location', 'Details'][_step],
                  style: GoogleFonts.outfit(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep0(),
                _buildStep1(),
                _buildStep2(),
              ],
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // Step 0 — Restaurant Name
  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle('What\'s your restaurant called?',
              'This name will appear to customers on the app.'),
          const SizedBox(height: 32),
          _fieldLabel('Restaurant Name *'),
          _textField(
            controller: _nameCtrl,
            hint: 'e.g. Pranil Da Dhaba',
            icon: Icons.storefront_rounded,
          ),
          const SizedBox(height: 24),
          _fieldLabel('Cuisine Types'),
          _textField(
            controller: _cuisinesCtrl,
            hint: 'e.g. Indian, Fast Food, Chinese (comma separated)',
            icon: Icons.restaurant_rounded,
          ),
          const SizedBox(height: 24),
          _fieldLabel('Phone Number'),
          _textField(
            controller: _phoneCtrl,
            hint: 'e.g. 9876543210',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            prefixText: '+91 ',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // Step 1 — Location / Area
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle('Where is your restaurant located?',
              'Select the neighborhood area. Your menu will appear to customers browsing that area.'),
          const SizedBox(height: 32),
          _fieldLabel('Select Area *'),
          Consumer<RetailerProvider>(
            builder: (context, provider, _) {
              if (provider.areas.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AreaModel>(
                    value: _selectedArea,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Choose area...',
                          style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                    ),
                    isExpanded: true,
                    dropdownColor: AppTheme.surface,
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textSecondary),
                    ),
                    items: provider.areas.map((area) {
                      return DropdownMenuItem<AreaModel>(
                        value: area,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(area.areaName,
                                  style: GoogleFonts.outfit(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600)),
                              Text(area.city,
                                  style: GoogleFonts.outfit(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedArea = val),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _fieldLabel('Street Address (optional)'),
          _textField(
            controller: _addressCtrl,
            hint: 'e.g. 12 MG Road, Near Clock Tower',
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Latitude'),
                    _textField(
                      controller: _latCtrl,
                      hint: 'e.g. 18.5204',
                      icon: Icons.map_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Longitude'),
                    _textField(
                      controller: _lngCtrl,
                      hint: 'e.g. 73.8567',
                      icon: Icons.map_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                final pos = await LocationService.getCurrentLocation();
                if (pos != null) {
                  _latCtrl.text = pos.latitude.toString();
                  _lngCtrl.text = pos.longitude.toString();
                  _showSnack('Location updated successfully!');
                }
              } catch (e) {
                _showSnack(e.toString());
              }
            },
            icon: const Icon(Icons.my_location_rounded),
            label: Text('Use My Current Location', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // Step 2 — Price & Finishing Touches
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle('Almost done!',
              'Set your price range so customers know what to expect.'),
          const SizedBox(height: 32),
          _fieldLabel('Price Category *'),
          const SizedBox(height: 12),
          ...['budget', 'mid-range', 'premium'].map((cat) {
            final labels = {
              'budget': ('₹ Budget', 'Affordable meals under ₹200', Icons.savings_rounded),
              'mid-range': ('₹₹ Mid-Range', 'Family meals ₹200–₹600', Icons.restaurant_menu_rounded),
              'premium': ('₹₹₹ Premium', 'Fine dining above ₹600', Icons.star_rounded),
            };
            final info = labels[cat]!;
            final selected = _priceCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _priceCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary.withValues(alpha: 0.08) : AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.divider,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : AppTheme.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(info.$3,
                          color: selected ? AppTheme.primary : AppTheme.textSecondary,
                          size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(info.$1,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  color: selected ? AppTheme.primary : AppTheme.textPrimary)),
                          Text(info.$2,
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.primary, size: 22),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildBottomButton() {
    return Consumer<RetailerProvider>(
      builder: (context, provider, _) {
        final isLastStep = _step == 2;
        final isLoading = provider.state == RetailerState.loading;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'Launch My Restaurant 🚀' : 'Continue',
                          style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        if (!isLastStep) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _stepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5)),
      ],
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary)),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.outfit(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 14),
          prefixText: prefixText,
          icon: Icon(icon, color: AppTheme.textSecondary, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
