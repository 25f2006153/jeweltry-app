import 'dart:async';

import '../core/constants/app_assets.dart';
import '../models/jewelry_type.dart';
import '../models/try_on_request.dart';
import '../models/try_on_result.dart';
import 'ai_service.dart';

/// Development & Testing Mock AI Service implementation.
/// Emits progress events and returns sample rendered results for UI evaluation.
class MockAIService implements AIService {
  @override
  Future<TryOnResult> generateTryOn(
    TryOnRequest request, {
    TryOnProgressCallback? onProgress,
  }) async {
    final startTime = DateTime.now();

    void updateProgress(double progress, String status) {
      if (onProgress != null) {
        onProgress(progress, status);
      }
    }

    // Step 1: Uploading
    updateProgress(0.15, 'Uploading images...');
    await Future.delayed(const Duration(milliseconds: 600));

    // Step 2: Analyzing Anatomical Anchors
    updateProgress(
      0.35,
      'Analyzing face & ${request.jewelryType.targetAnchor} anchor...',
    );
    await Future.delayed(const Duration(milliseconds: 800));

    // Step 3: Processing Jewelry
    updateProgress(
      0.60,
      'Processing ${request.jewelryType.displayName} placement...',
    );
    await Future.delayed(const Duration(milliseconds: 900));

    // Step 4: AI Generation
    updateProgress(0.85, 'Generating AI virtual try-on...');
    await Future.delayed(const Duration(milliseconds: 900));

    // Step 5: Finalizing
    updateProgress(1.00, 'Finalizing high-resolution result...');
    await Future.delayed(const Duration(milliseconds: 400));

    // Select result image based on jewelry type
    String resultPath;
    switch (request.jewelryType) {
      case JewelryType.earrings:
        resultPath = AppAssets.resultEarrings;
        break;
      case JewelryType.necklace:
        resultPath = AppAssets.resultNecklace;
        break;
      default:
        // For other types in mock mode, use earrings or user photo as fallback
        resultPath = request.userImagePath.isNotEmpty 
            ? request.userImagePath 
            : AppAssets.resultEarrings;
    }

    final duration = DateTime.now().difference(startTime).inMilliseconds;

    return TryOnResult(
      id: 'mock_res_${DateTime.now().millisecondsSinceEpoch}',
      resultImagePath: resultPath,
      request: request,
      isSuccess: true,
      processingTimeMs: duration,
    );
  }
}
