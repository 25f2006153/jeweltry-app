import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../services/image_picker_service.dart';
import '../services/try_on_state_manager.dart';
import '../widgets/luxury_app_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/upload_card.dart';
import 'jewelry_type_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePickerService _pickerService = ImagePickerService();

  Future<void> _pickUserImageFromGallery(TryOnStateManager stateManager) async {
    final xfile = await _pickerService.pickImageFromGallery();
    if (xfile != null) {
      await stateManager.setUserImageFromXFile(xfile);
    }
  }

  Future<void> _captureUserImageFromCamera(TryOnStateManager stateManager) async {
    final xfile = await _pickerService.captureImageFromCamera();
    if (xfile != null) {
      await stateManager.setUserImageFromXFile(xfile);
    }
  }

  Future<void> _pickJewelryImageFromGallery(TryOnStateManager stateManager) async {
    final xfile = await _pickerService.pickImageFromGallery();
    if (xfile != null) {
      await stateManager.setJewelryImageFromXFile(xfile);
    }
  }

  void _validateAndContinue(BuildContext context, TryOnStateManager stateManager) {
    if (!stateManager.canContinueUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please upload both your photo and a jewelry photo to proceed.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.burgundy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JewelryTypeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateManager = Provider.of<TryOnStateManager>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const LuxuryAppBar(title: 'Upload Photos'),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload your photo & jewelry piece',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: User Photo
              UploadCard(
                title: 'Your Photo',
                imagePath: stateManager.userImagePath,
                onPickGallery: () => _pickUserImageFromGallery(stateManager),
                onPickCamera: () => _captureUserImageFromCamera(stateManager),
                showCameraOption: true,
              ),

              const SizedBox(height: 20),

              // Section 2: Jewelry Photo
              UploadCard(
                title: 'Jewelry Photo',
                imagePath: stateManager.jewelryImagePath,
                onPickGallery: () => _pickJewelryImageFromGallery(stateManager),
                showCameraOption: false,
              ),

              const SizedBox(height: 28),

              // Primary Continue Button
              PrimaryButton(
                text: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: () => _validateAndContinue(context, stateManager),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
