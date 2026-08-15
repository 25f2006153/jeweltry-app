import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../services/try_on_state_manager.dart';
import '../widgets/ai_pulse_animation.dart';
import 'result_screen.dart';

class GeneratingScreen extends StatefulWidget {
  const GeneratingScreen({super.key});

  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen> {
  @override
  void initState() {
    super.initState();
    // Add listener to auto-navigate when state completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stateManager = Provider.of<TryOnStateManager>(context, listen: false);
      stateManager.addListener(_onStateChange);
    });
  }

  @override
  void dispose() {
    // Remove state listener safely
    try {
      final stateManager = Provider.of<TryOnStateManager>(context, listen: false);
      stateManager.removeListener(_onStateChange);
    } catch (_) {}
    super.dispose();
  }

  void _onStateChange() {
    final stateManager = Provider.of<TryOnStateManager>(context, listen: false);
    if (!stateManager.isGenerating && stateManager.lastResult != null && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ResultScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else if (stateManager.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(stateManager.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildUserAvatar(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    } else if (kIsWeb || path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    } else {
      return Image.file(File(path), fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateManager = Provider.of<TryOnStateManager>(context);
    final userPath = stateManager.userImagePath;
    final progress = stateManager.progress;
    final statusMsg = stateManager.statusMessage.isNotEmpty
        ? stateManager.statusMessage
        : 'AI is working on your perfect try-on...';

    return PopScope(
      canPop: !stateManager.isGenerating,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Top user photo preview pill
                if (userPath != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: _buildUserAvatar(userPath),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Target Category',
                              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                            Text(
                              stateManager.selectedJewelryType.displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.burgundy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Center AI Pulse Animation
                const AIPulseAnimation(size: 200),

                const SizedBox(height: 36),

                // Screen Title
                Text(
                  'Creating Your Look',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),

                // Status Message from AIService callback
                Text(
                  statusMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.burgundy,
                  ),
                ),

                const SizedBox(height: 28),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          minHeight: 8,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progress * 100).toInt()}% Complete',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Footer note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, color: AppColors.burgundy, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'This may take a few seconds for the best results.',
                        style: TextStyle(
                          color: AppColors.burgundy,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
