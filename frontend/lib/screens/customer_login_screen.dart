// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import 'home_screen.dart';
import 'retailer_login_screen.dart';
import 'admin_login_screen.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  String? _selectedStateId;
  String? _selectedStateName;
  String? _selectedCityId;
  String? _selectedCityName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().fetchStates();
    });
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    bool success;
    if (_isSignUp) {
      if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _selectedStateName == null || _selectedCityName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields for sign up'), backgroundColor: AppTheme.error),
        );
        return;
      }
      success = await auth.register(_emailCtrl.text.trim(), _passCtrl.text, 'customer', _nameCtrl.text.trim(), _phoneCtrl.text.trim(), _selectedStateName!, _selectedCityName!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.'), backgroundColor: AppTheme.primary),
        );
        setState(() => _isSignUp = false);
      }
    } else {
      success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text, 'CUSTOMER');
      if (success && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Authentication failed'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().state == AuthState.loading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/eatbot_logo.png',
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
  
                // Title
                Text(
                  _isSignUp ? 'Create an Account' : 'Welcome Back',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 24),
  
                // Form
                TextField(
                  controller: _emailCtrl,
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                    filled: true,
                    fillColor: AppTheme.surface.withOpacity(0.9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppTheme.surface.withOpacity(0.9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                      filled: true,
                      fillColor: AppTheme.surface.withOpacity(0.9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneCtrl,
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                      filled: true,
                      fillColor: AppTheme.surface.withOpacity(0.9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<LocationProvider>(
                    builder: (context, locationProv, child) {
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedStateId,
                            decoration: InputDecoration(
                              labelText: 'State',
                              prefixIcon: const Icon(Icons.map_outlined, color: Colors.grey),
                              filled: true,
                              fillColor: AppTheme.surface.withOpacity(0.9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
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
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCityId,
                            decoration: InputDecoration(
                              labelText: 'City',
                              prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.grey),
                              filled: true,
                              fillColor: AppTheme.surface.withOpacity(0.9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
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
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
  
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isSignUp ? 'Sign Up' : 'Login', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 16),
  
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp ? 'Already have an account? Login' : 'Don\'t have an account? Sign Up',
                      style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
  
                const Divider(height: 48, color: Colors.black12),
  
                // Links to other portals
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RetailerLoginScreen())),
                        child: Text('Restaurant Portal', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
                        child: Text('System Admin', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                )
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          ),
        ),
      );
  }
}
