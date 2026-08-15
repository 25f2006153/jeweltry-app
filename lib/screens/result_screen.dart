import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants/app_colors.dart';
import '../services/try_on_state_manager.dart';
import '../widgets/luxury_app_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/result_image_card.dart';
import 'home_screen.dart';
import 'upload_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  void _shareResult(BuildContext context, String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return;

    if (imagePath.startsWith('assets/')) {
      Share.share('Check out my AI jewelry try-on with JewelTry!');
    } else {
      Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Check out my AI jewelry try-on with JewelTry!',
      );
    }
  }

  void _saveToGallery(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Saved to Gallery successfully!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _onTryAnother(BuildContext context, TryOnStateManager stateManager) {
    // Preserve user photo, reset jewelry photo & state
    stateManager.prepareTryAnother();

    // Navigate to Upload screen where user photo remains pre-filled
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UploadScreen()),
      (route) => route.isFirst,
    );
  }

  void _goToHome(BuildContext context, TryOnStateManager stateManager) {
    stateManager.resetAll();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateManager = Provider.of<TryOnStateManager>(context);
    final result = stateManager.lastResult;
    final resultPath = result?.resultImagePath ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: LuxuryAppBar(
        title: 'Your Look',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.textDark),
            onPressed: () => _goToHome(context, stateManager),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Result Image Frame
              ResultImageCard(
                imagePath: resultPath,
                onTapZoom: () {
                  // Fullscreen dialog view
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: InteractiveViewer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            resultPath.startsWith('assets/') ? resultPath : resultPath,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => Image.network(resultPath),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Title and category badge
              Text(
                'AI Try-On Complete',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Category: ${stateManager.selectedJewelryType.displayName} (${stateManager.selectedJewelryType.targetAnchor} placement)',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 24),

              // Primary Action Buttons: Share & Save
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Share',
                      icon: Icons.share_outlined,
                      isSecondary: true,
                      onPressed: () => _shareResult(context, resultPath),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Save',
                      icon: Icons.download_outlined,
                      onPressed: () => _saveToGallery(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Try Another Button (Preserves User Photo!)
              PrimaryButton(
                text: 'Try Another Jewelry',
                icon: Icons.replay,
                isSecondary: true,
                onPressed: () => _onTryAnother(context, stateManager),
              ),

              const SizedBox(height: 16),

              // Go to Home text link
              TextButton.icon(
                onPressed: () => _goToHome(context, stateManager),
                icon: const Icon(Icons.home_outlined, size: 18, color: AppColors.textMuted),
                label: const Text(
                  'Go to Home',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
