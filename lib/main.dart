import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_config.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/http_ai_service.dart';
import 'services/try_on_state_manager.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
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
            aiService: HttpAIService(
              baseUrl: AppConfig.backendBaseUrl,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'JewelTry - AI Virtual Jewelry Try-On',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
