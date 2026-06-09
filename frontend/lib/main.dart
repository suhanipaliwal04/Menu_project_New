// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/customer_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/retailer_dashboard_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/browse_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/dine_in_provider.dart';
import 'providers/takeaway_provider.dart';
import 'providers/voice_agent_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/retailer_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/customer_bookings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/reviews_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MenuIntelligenceApp());
}

class MenuIntelligenceApp extends StatelessWidget {
  const MenuIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => BrowseProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => RetailerProvider()),
        ChangeNotifierProvider(create: (_) => CustomerBookingsProvider()..loadBookings()),
        ChangeNotifierProvider(create: (_) => DineInProvider()),
        ChangeNotifierProvider(create: (_) => TakeawayProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
        ChangeNotifierProxyProvider3<CartProvider, DineInProvider, TakeawayProvider, VoiceAgentProvider>(
          create: (ctx) => VoiceAgentProvider(
            ctx.read<CartProvider>(),
            ctx.read<DineInProvider>(),
            ctx.read<TakeawayProvider>(),
          ),
          update: (_, cart, dine, takeaway, previous) =>
              previous ?? VoiceAgentProvider(cart, dine, takeaway),
        ),
      ],
      child: MaterialApp(
        title: 'eatbot',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context);
          final bool isMobile = mediaQueryData.size.width < 600;

          if (isMobile) {
            // Force optical scaling so layout matches exactly 100% proportion of a 411px wide device
            final double designWidth = 411.0; 
            final double scale = mediaQueryData.size.width / designWidth;
            final double scaledHeight = mediaQueryData.size.height / scale;

            return FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: designWidth,
                height: scaledHeight,
                child: MediaQuery(
                  data: mediaQueryData.copyWith(
                    size: Size(designWidth, scaledHeight),
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: Consumer<AuthProvider>(
                    builder: (ctx, auth, _) {
                      String bgPath = 'assets/images/eatbot_bg.png';
                      if (auth.role == 'restaurant_admin') {
                        bgPath = 'assets/images/restaurant_bg.png';
                      } else if (auth.role == 'system_admin') {
                        bgPath = 'assets/images/admin_bg.png';
                      }

                      return Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(bgPath),
                            fit: BoxFit.cover,
                            colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.lighten),
                            opacity: 0.40,
                          ),
                        ),
                        child: child,
                      );
                    },
                  ),
                ),
              ),
            );
          } else {
            // Laptop / Web Behavior
            return MediaQuery(
              data: mediaQueryData.copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Consumer<AuthProvider>(
                builder: (ctx, auth, _) {
                  String bgPath = 'assets/images/eatbot_bg.png';
                  if (auth.role == 'restaurant_admin') {
                    bgPath = 'assets/images/restaurant_bg.png';
                  } else if (auth.role == 'system_admin') {
                    bgPath = 'assets/images/admin_bg.png';
                  }

                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(bgPath),
                        fit: BoxFit.cover,
                        colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.lighten),
                        opacity: 0.40,
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await context.read<AuthProvider>().init();
    
    // Also init retailer provider if role is retailer, so it loads dashboard stats etc.
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.role == 'RESTAURANT_ADMIN') {
      await context.read<RetailerProvider>().init();
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return const CustomerLoginScreen();
    }

    switch (auth.role) {
      case 'SYSTEM_ADMIN':
        return const AdminDashboardScreen();
      case 'RESTAURANT_ADMIN':
        return const RetailerDashboardScreen();
      case 'CUSTOMER':
      default:
        return const HomeScreen();
    }
  }
}
