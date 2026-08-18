import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _googleClientId =
      '452179028273-lkhh0t19mm85gu09slimfvuar07sjip4.apps.googleusercontent.com';

  late final GoogleSignIn _googleSignIn = _createGoogleSignIn();

  GoogleSignIn _createGoogleSignIn() => GoogleSignIn(
        clientId: kIsWeb ? _googleClientId : null,
        serverClientId: kIsWeb ? null : _googleClientId,
        scopes: ['email', 'profile'],
      );

  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get userEmail => currentUser?.email;
  String? get userName => currentUser?.userMetadata?['full_name'] as String?;
  String? get userAvatar => currentUser?.userMetadata?['avatar_url'] as String?;
  String? get accessToken => _supabase.auth.currentSession?.accessToken;

  AuthService() {
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On Web, use Supabase OAuth which seamlessly handles redirect / popup
        return await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? Uri.base.origin : null,
          authScreenLaunchMode: LaunchMode.platformDefault,
        );
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false; // User cancelled

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        debugPrint('❌ Google Sign-In: No ID token received');
        return false;
      }

      // Sign in to Supabase with Google credentials
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        debugPrint('✅ Signed in: ${response.user!.email}');
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Google Sign-In error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Sign-out error: $e');
    }
  }

  /// Check if session is still valid
  Future<bool> refreshSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;
      // Supabase auto-refreshes, just check if we have a valid session
      return session.expiresAt != null &&
          DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
              .isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }
}
