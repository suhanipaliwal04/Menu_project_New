import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/retailer_provider.dart';
import 'retailer_dashboard_screen.dart';

class RetailerLoginScreen extends StatefulWidget {
  const RetailerLoginScreen({super.key});

  @override
  State<RetailerLoginScreen> createState() => _RetailerLoginScreenState();
}

class _RetailerLoginScreenState extends State<RetailerLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both email and password.', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isSignUp) {
      final success = await authProvider.register(email, pass, 'restaurant-admin');
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful! Please wait for System Admin approval before logging in.', style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isSignUp = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Registration failed', style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final success = await authProvider.login(email, pass, 'RESTAURANT_ADMIN');
      if (!mounted) return;

      if (success) {
        await context.read<RetailerProvider>().fetchMe();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RetailerDashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed', style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.textPrimary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Icon
              Center(
                  child: Image.asset(
                    'assets/images/restaurant_logo.png',
                    height: 280,
                    fit: BoxFit.contain,
                  ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 8),
              Text(
                _isSignUp ? 'Register to list your restaurant.' : 'Manage your restaurant, upload menus & more.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 48),

              // Email Field
              _buildInputField(
                controller: _emailCtrl,
                icon: Icons.email_rounded,
                hint: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                delay: 400,
              ),
              const SizedBox(height: 16),

              // Password Field
              _buildPasswordField(delay: 500),

              const SizedBox(height: 40),

              // Login/Signup Button
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  return SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.state == AuthState.loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: auth.state == AuthState.loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_isSignUp ? Icons.app_registration : Icons.login_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _isSignUp ? 'Request Approval' : 'Sign In to Dashboard',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
                },
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
                    _isSignUp ? 'Already approved? Sign In' : 'New restaurant? Sign Up',
                    style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms),
              
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'New registrations require System Admin approval before login.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: Colors.black, fontWeight: FontWeight.w900),
                ),
              ).animate().fadeIn(delay: 750.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    required int delay,
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
        style: GoogleFonts.outfit(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(icon, color: AppTheme.textSecondary, size: 20),
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPasswordField({required int delay}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _passCtrl,
        obscureText: _obscurePassword,
        style: GoogleFonts.outfit(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.lock_rounded, color: AppTheme.textSecondary, size: 20),
          hintText: 'Password',
          hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.2, end: 0);
  }
}
