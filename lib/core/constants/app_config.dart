import 'package:flutter/foundation.dart';

/// App-wide configuration constants
class AppConfig {
  // Live Backend API URL (Uses same-origin reverse proxy on web, Render URL on native)
  static String get backendBaseUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return 'https://jeweltry-backend.onrender.com';
  }
  
  // Supabase Configuration
  static const String supabaseUrl = 'https://ldzzgenjjukaoqgvfasz.supabase.co';
  static const String supabaseAnonKey = 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxkenpnZW5qanVrYW9xZ3ZmYXN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY3MTg0ODYsImV4cCI6MjEwMjI5NDQ4Nn0.9TU2c3Zjtp5OlDkns_TzEPPhy9ktkM_IpMkArWfkRQM';
}
