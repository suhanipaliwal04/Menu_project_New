import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';

class CustomerSettingsScreen extends StatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  State<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends State<CustomerSettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  
  String? _selectedStateId;
  String? _selectedStateName;
  String? _selectedCityId;
  String? _selectedCityName;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    final auth = context.read<AuthProvider>();
    final loc = context.read<LocationProvider>();
    
    _nameCtrl.text = auth.fullName ?? '';
    _phoneCtrl.text = auth.phone ?? '';
    
    await loc.fetchStates();
    
    if (auth.userState != null) {
      final stateMatch = loc.states.where((s) => s['state_name'] == auth.userState).toList();
      if (stateMatch.isNotEmpty) {
        _selectedStateId = stateMatch.first['state_id'];
        _selectedStateName = stateMatch.first['state_name'];
        await loc.fetchCities(_selectedStateName!);
        
        if (auth.city != null) {
          final cityMatch = loc.cities.where((c) => c['city_name'] == auth.city).toList();
          if (cityMatch.isNotEmpty) {
            _selectedCityId = cityMatch.first['city_id'];
            _selectedCityName = cityMatch.first['city_name'];
          }
        }
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _selectedStateName == null || _selectedCityName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppTheme.error));
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(_nameCtrl.text.trim(), _phoneCtrl.text.trim(), _selectedStateName!, _selectedCityName!);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppTheme.success));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage ?? 'Failed to update profile'), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person, color: Colors.grey),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixText: '+91 ',
                      prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Consumer<LocationProvider>(
                    builder: (context, locationProv, child) {
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStateId,
                                hint: Text('State', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                                isExpanded: true,
                                dropdownColor: AppTheme.surface,
                                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                                items: locationProv.states.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s['state_id'],
                                    child: Text(s['state_name']),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedStateId = val;
                                    _selectedStateName = locationProv.states.firstWhere((s) => s['state_id'] == val)['state_name'];
                                    _selectedCityId = null;
                                    _selectedCityName = null;
                                  });
                                  if (_selectedStateName != null) {
                                    locationProv.fetchCities(_selectedStateName!);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCityId,
                                hint: Text('City', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                                isExpanded: true,
                                dropdownColor: AppTheme.surface,
                                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                                items: locationProv.cities.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c['city_id'],
                                    child: Text(c['city_name']),
                                  );
                                }).toList(),
                                onChanged: locationProv.cities.isEmpty ? null : (val) {
                                  setState(() {
                                    _selectedCityId = val;
                                    _selectedCityName = locationProv.cities.firstWhere((c) => c['city_id'] == val)['city_name'];
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return ElevatedButton(
                        onPressed: auth.state == AuthState.loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: auth.state == AuthState.loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Save Changes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      );
                    }
                  ),
                ],
              ),
            ),
    );
  }
}
