import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/browse_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/browse_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/voice_agent_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/retailer_provider.dart';

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
        ChangeNotifierProxyProvider<CartProvider, VoiceAgentProvider>(
          create: (ctx) => VoiceAgentProvider(ctx.read<CartProvider>()),
          update: (_, cart, previous) => previous ?? VoiceAgentProvider(cart),
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

