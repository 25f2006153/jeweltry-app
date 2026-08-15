import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/credit_topup_sheet.dart';
import '../widgets/feature_card.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';
import 'upload_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showProfileSheet(BuildContext context, AuthService auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.burgundy,
              backgroundImage: auth.userAvatar != null
                  ? NetworkImage(auth.userAvatar!)
                  : null,
              child: auth.userAvatar == null
                  ? Text(
                      (auth.userName ?? auth.userEmail ?? 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              auth.userName ?? 'JewelTry User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              auth.userEmail ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            // Buy Credits button in profile
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                CreditTopupSheet.show(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.burgundyGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, color: AppColors.gold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Get More Credits',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.burgundy,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'JewelTry',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  // User profile + logout
                  Consumer<AuthService>(
                    builder: (context, auth, _) => GestureDetector(
                      onTap: () => _showProfileSheet(context, auth),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.burgundySurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.goldLight),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: AppColors.burgundy,
                              backgroundImage: auth.userAvatar != null
                                  ? NetworkImage(auth.userAvatar!)
                                  : null,
                              child: auth.userAvatar == null
                                  ? Text(
                                      (auth.userName ?? auth.userEmail ?? 'U')
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          color: AppColors.gold,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              auth.userName?.split(' ').first ?? 'You',
                              style: const TextStyle(
                                color: AppColors.burgundy,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 28),

              // Hero Banner Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.burgundy.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge tag
                    Text(
                      'VIRTUAL TRY-ON STUDIO',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldDark,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'See It On You\nBefore You Buy',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload your photo and any jewelry photo to see how it looks on you realistically.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 20),
                    // Showcase Thumbnail Preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          border: Border.all(color: AppColors.goldLight),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              AppAssets.resultEarrings,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Live Preview',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // CTA Button
                    PrimaryButton(
                      text: 'Start Try-On',
                      icon: Icons.auto_awesome,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UploadScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms).moveY(begin: 20, end: 0),

              const SizedBox(height: 32),

              // Feature Cards Section Header
              Text(
                'How JewelTry Works',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              // 3 Feature Cards
              Row(
                children: [
                  Expanded(
                    child: const FeatureCard(
                      title: 'Any Jewelry',
                      subtitle: 'Upload any piece from phone gallery',
                      icon: Icons.diamond_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: const FeatureCard(
                      title: 'Any Photo',
                      subtitle: 'Use selfie or camera portrait',
                      icon: Icons.person_outline,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 12),

              const FeatureCard(
                title: 'Instant AI Try-On',
                subtitle: 'Get realistic fitting with accurate ear, neck, and finger anatomical positioning in seconds.',
                icon: Icons.auto_awesome,
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
