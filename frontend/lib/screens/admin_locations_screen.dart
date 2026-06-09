import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/location_provider.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  final _stateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  String? _selectedStateId;
  String? _selectedCityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().fetchStates();
    });
  }

  @override
  void dispose() {
    _stateCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  void _addState() async {
    final name = _stateCtrl.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<LocationProvider>();
    final success = await provider.createState(name);
    if (!mounted) return;

    if (success) {
      _stateCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('State added successfully'), backgroundColor: AppTheme.success));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to add state'), backgroundColor: AppTheme.error));
    }
  }

  void _addCity() async {
    final name = _cityCtrl.text.trim();
    if (name.isEmpty || _selectedStateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a city name and select a state'), backgroundColor: AppTheme.error));
      return;
    }

    final provider = context.read<LocationProvider>();
    final success = await provider.createCity(name, _selectedStateId!);
    if (!mounted) return;

    if (success) {
      _cityCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('City added successfully'), backgroundColor: AppTheme.success));
      // Refresh cities for selected state
      final selectedState = provider.states.firstWhere((s) => s['state_id'] == _selectedStateId, orElse: () => null);
      if (selectedState != null) {
        provider.fetchCities(selectedState['state_name']);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to add city'), backgroundColor: AppTheme.error));
    }
  }

  void _addArea() async {
    final name = _areaCtrl.text.trim();
    if (name.isEmpty || _selectedStateId == null || _selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an area name and select state & city'), backgroundColor: AppTheme.error));
      return;
    }

    final provider = context.read<LocationProvider>();
    final cityData = provider.cities.firstWhere((c) => c['city_id'] == _selectedCityId, orElse: () => null);
    final stateData = provider.states.firstWhere((s) => s['state_id'] == _selectedStateId, orElse: () => null);
    
    if (cityData == null) return;

    final success = await provider.createArea(name, cityData['city_name'], state: stateData?['state_name']);
    if (!mounted) return;

    if (success) {
      _areaCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Area added successfully'), backgroundColor: AppTheme.success));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to add area'), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Locations Management', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surface,
      ),
      body: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          if (provider.stateStatus == LocationStateStatus.loading && provider.states.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add New State', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _stateCtrl,
                        style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'State Name',
                          filled: true,
                          fillColor: AppTheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addState,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                Text('Add New City', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStateId,
                      hint: Text('Select State', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                      isExpanded: true,
                      dropdownColor: AppTheme.surface,
                      style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                      items: provider.states.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['state_id'],
                          child: Text(s['state_name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedStateId = val;
                          _selectedCityId = null; // Reset city when state changes
                        });
                        if (val != null) {
                          final st = provider.states.firstWhere((s) => s['state_id'] == val);
                          provider.fetchCities(st['state_name']);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityCtrl,
                        style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'City Name',
                          filled: true,
                          fillColor: AppTheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addCity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Text('Add New Area', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                // City Dropdown for Area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCityId,
                      hint: Text('Select City', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                      isExpanded: true,
                      dropdownColor: AppTheme.surface,
                      style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                      items: provider.cities.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['city_id'],
                          child: Text(c['city_name']),
                        );
                      }).toList(),
                      onChanged: provider.cities.isEmpty ? null : (val) {
                        setState(() {
                          _selectedCityId = val;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _areaCtrl,
                        style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Area Name',
                          filled: true,
                          fillColor: AppTheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addArea,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                if (_selectedStateId != null) ...[
                  Text('Cities in Selected State', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  if (provider.stateStatus == LocationStateStatus.loading)
                    const Center(child: CircularProgressIndicator())
                  else if (provider.cities.isEmpty)
                    Text('No cities found.', style: GoogleFonts.outfit(color: AppTheme.textSecondary))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.cities.length,
                      itemBuilder: (ctx, i) {
                        final c = provider.cities[i];
                        return Card(
                          color: AppTheme.surface,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(c['city_name'], style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
                            leading: const Icon(Icons.location_city, color: AppTheme.primary),
                          ),
                        );
                      },
                    ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
