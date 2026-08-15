import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/mock_ai_service.dart';
import 'services/try_on_state_manager.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ldzzgenjjukaoqgvfasz.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxkenpnZW5qanVrYW9xZ3ZmYXN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY3MTg0ODYsImV4cCI6MjEwMjI5NDQ4Nn0.9TU2c3Zjtp5OlDkns_TzEPPhy9ktkM_IpMkArWfkRQM',
  );

  runApp(const JewelTryApp());
}

class JewelTryApp extends StatelessWidget {
  const JewelTryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<TryOnStateManager>(
          create: (_) => TryOnStateManager(
            aiService: MockAIService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'JewelTry',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
