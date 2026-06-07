import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
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
      success = await auth.register(_emailCtrl.text.trim(), _passCtrl.text, 'customer');
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
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 48),
  
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
