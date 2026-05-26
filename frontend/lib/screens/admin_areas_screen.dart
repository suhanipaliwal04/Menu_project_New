import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/admin_provider.dart';

class AdminAreasScreen extends StatefulWidget {
  const AdminAreasScreen({super.key});

  @override
  State<AdminAreasScreen> createState() => _AdminAreasScreenState();
}

class _AdminAreasScreenState extends State<AdminAreasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAreas();
    });
  }

  void _showAddAreaSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddAreaBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text('Areas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAreaSheet,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('New Area', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.state == AdminState.loading && provider.areas.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (provider.state == AdminState.error && provider.areas.isEmpty) {
            return Center(child: Text(provider.errorMessage ?? 'Failed to load', style: GoogleFonts.outfit(color: AppTheme.error)));
          }
          if (provider.areas.isEmpty) {
            return Center(child: Text('No areas found. Add your first area.', style: GoogleFonts.outfit(color: AppTheme.textSecondary)));
          }

          return RefreshIndicator(
            onRefresh: provider.fetchAreas,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
              itemCount: provider.areas.length,
              itemBuilder: (context, index) {
                final area = provider.areas[index];
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
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(area.areaName, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 4),
                            Text('${area.city}${area.state != null ? ', ${area.state}' : ''}${area.pincode != null ? ' - ${area.pincode}' : ''}', 
                                 style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
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

class _AddAreaBottomSheet extends StatefulWidget {
  const _AddAreaBottomSheet();

  @override
  State<_AddAreaBottomSheet> createState() => _AddAreaBottomSheetState();
}

class _AddAreaBottomSheetState extends State<_AddAreaBottomSheet> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Nagpur');
  final _stateCtrl = TextEditingController(text: 'Maharashtra');
  final _pincodeCtrl = TextEditingController();

  Future<void> _submit() async {
    final provider = context.read<AdminProvider>();
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();

    if (name.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and City are required')));
      return;
    }

    final success = await provider.createArea(
      name,
      city,
      state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context); // Close sheet on success
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Area created successfully!'), backgroundColor: AppTheme.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create New Area', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 24),
            
            _buildField('Area Name *', 'e.g. Dharampeth', _nameCtrl),
            const SizedBox(height: 16),
            _buildField('City *', 'e.g. Nagpur', _cityCtrl),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildField('State', 'e.g. Maharashtra', _stateCtrl)),
                const SizedBox(width: 16),
                Expanded(child: _buildField('Pincode', 'e.g. 440010', _pincodeCtrl, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 32),

            Consumer<AdminProvider>(
              builder: (ctx, provider, child) => ElevatedButton(
                onPressed: provider.state == AdminState.loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: provider.state == AdminState.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Create Area', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
