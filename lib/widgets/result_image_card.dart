import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ResultImageCard extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onTapZoom;

  const ResultImageCard({
    super.key,
    required this.imagePath,
    this.onTapZoom,
  });

  Widget _buildImageWidget(String path) {
    if (path.isEmpty) {
      return _buildErrorWidget();
    }
    
    // 1. Base64 Data URI from AI Backend
    if (path.startsWith('data:image')) {
      try {
        final commaIndex = path.indexOf(',');
        final base64Data = commaIndex != -1 ? path.substring(commaIndex + 1) : path;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      } catch (e) {
        return _buildErrorWidget();
      }
    }

    // 2. Bundled Asset
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } 
    
    // 3. Network URL / Web Blob
    if (path.startsWith('http://') || path.startsWith('https://') || (kIsWeb && path.startsWith('blob:'))) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } 
    
    // 4. Local File (Mobile/Desktop)
    if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      }
    }

    return _buildErrorWidget();
  }

  Widget _buildErrorWidget() {
    return Container(
      color: AppColors.border,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, color: AppColors.burgundy, size: 48),
            SizedBox(height: 8),
            Text(
              'Could not render try-on image',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 0.85,
              child: _buildImageWidget(imagePath),
            ),
          ),
          // Top Left Gold Sparkle Accent
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.burgundy.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.goldLight, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.gold, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'AI Try-On Result',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Zoom Tap Badge
          if (onTapZoom != null)
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: onTapZoom,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.goldLight),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
