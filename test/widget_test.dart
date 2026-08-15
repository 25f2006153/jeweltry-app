import 'package:flutter_test/flutter_test.dart';
import 'package:jewel_try/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://ldzzgenjjukaoqgvfasz.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxkenpnZW5qanVrYW9xZ3ZmYXN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY3MTg0ODYsImV4cCI6MjEwMjI5NDQ4Nn0.9TU2c3Zjtp5OlDkns_TzEPPhy9ktkM_IpMkArWfkRQM',
    );
  });

  testWidgets('JewelTry app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JewelTryApp());
    await tester.pump();

    // Verify JewelTry title appears on Splash screen
    expect(find.text('JewelTry'), findsWidgets);

    // Fast-forward splash delay and transition
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 700));
  });
}
