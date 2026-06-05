import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
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
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => BrowseProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => RetailerProvider()),
        ChangeNotifierProvider(create: (_) => CustomerBookingsProvider()..loadBookings()),
        ChangeNotifierProvider(create: (_) => DineInProvider()),
        ChangeNotifierProvider(create: (_) => TakeawayProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
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
        title: 'Menu Intelligence',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
