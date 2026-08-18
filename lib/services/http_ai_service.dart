import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/try_on_request.dart';
import '../models/try_on_result.dart';
import 'ai_service.dart';

/// Production HTTP AI Backend Service connecting Flutter frontend to FastAPI server.
class HttpAIService implements AIService {
  final String baseUrl;
  final String? authToken;

  HttpAIService({
    required this.baseUrl,
    this.authToken,
  });

  @override
  Future<TryOnResult> generateTryOn(
    TryOnRequest request, {
    TryOnProgressCallback? onProgress,
  }) async {
    final startTime = DateTime.now();

    onProgress?.call(0.15, 'Uploading images to server...');

    try {
      final uri = Uri.parse('$baseUrl/api/try-on');
      final httpRequest = http.MultipartRequest('POST', uri);

      // Get real Supabase token if available, fallback to provided authToken or mock-dev-token
      String token = authToken ?? 'mock-dev-token';
      try {
        final sessionToken = Supabase.instance.client.auth.currentSession?.accessToken;
        if (sessionToken != null && sessionToken.isNotEmpty) {
          token = sessionToken;
        }
      } catch (_) {}

      httpRequest.headers['Authorization'] = 'Bearer $token';
      httpRequest.fields['jewelry_type'] = request.jewelryType.name;
      httpRequest.fields['request_id'] = DateTime.now().millisecondsSinceEpoch.toString();

      // Read user image bytes (handles picked bytes, bundled asset, or file)
      Uint8List? userBytes = request.userImageBytes;
      if (userBytes == null && request.userImagePath.startsWith('assets/')) {
        final byteData = await rootBundle.load(request.userImagePath);
        userBytes = byteData.buffer.asUint8List();
      }

      // Read jewelry image bytes (handles picked bytes, bundled asset, or file)
      Uint8List? jewelryBytes = request.jewelryImageBytes;
      if (jewelryBytes == null && request.jewelryImagePath.startsWith('assets/')) {
        final byteData = await rootBundle.load(request.jewelryImagePath);
        jewelryBytes = byteData.buffer.asUint8List();
      }

      if (userBytes != null && userBytes.isNotEmpty) {
        httpRequest.files.add(http.MultipartFile.fromBytes(
          'user_image',
          userBytes,
          filename: 'user_photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (!kIsWeb && File(request.userImagePath).existsSync()) {
        httpRequest.files.add(
          await http.MultipartFile.fromPath('user_image', request.userImagePath),
        );
      }

      if (jewelryBytes != null && jewelryBytes.isNotEmpty) {
        httpRequest.files.add(http.MultipartFile.fromBytes(
          'jewelry_image',
          jewelryBytes,
          filename: 'jewelry_photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (!kIsWeb && File(request.jewelryImagePath).existsSync()) {
        httpRequest.files.add(
          await http.MultipartFile.fromPath('jewelry_image', request.jewelryImagePath),
        );
      }

      final streamedResponse = await httpRequest.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final requestId = data['request_id'];
        var currentStatus = data['status'];
        var resultUrl = data['result_image_url'];

        onProgress?.call(0.35, 'Analyzing face & anatomical anchor...');

        // Polling loop for GET /api/try-on/{request_id}
        int attempts = 0;
        const maxAttempts = 30; // 30 * 1.5s = 45s max
        while ((currentStatus == 'pending' || currentStatus == 'processing') && attempts < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 1500));
          attempts++;

          final double pollProgress = 0.35 + (attempts / maxAttempts) * 0.50;
          final String statusMsg = attempts < 5 
              ? 'Processing jewelry placement...'
              : (attempts < 15 ? 'Generating AI virtual try-on...' : 'Finalizing details...');

          onProgress?.call(pollProgress.clamp(0.35, 0.90), statusMsg);

          try {
            final pollResponse = await http.get(
              Uri.parse('$baseUrl/api/try-on/$requestId'),
              headers: {'Authorization': 'Bearer $token'},
            );
            if (pollResponse.statusCode == 200) {
              final pollData = jsonDecode(pollResponse.body);
              currentStatus = pollData['status'];
              resultUrl = pollData['result_image_url'];
              if (currentStatus == 'failed') {
                return TryOnResult.failure(
                  request: request,
                  errorMessage: pollData['error_message'] ?? 'AI try-on generation failed.',
                );
              }
            }
          } catch (_) {}
        }

        onProgress?.call(1.00, 'Finalizing high-resolution result...');

        return TryOnResult(
          id: requestId,
          resultImagePath: resultUrl ?? request.userImagePath,
          request: request,
          isSuccess: true,
          processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        );
      } else if (response.statusCode == 402) {
        return TryOnResult.failure(
          request: request,
          errorMessage: 'Insufficient credits balance. Please top up or upgrade plan.',
        );
      } else {
        return TryOnResult.failure(
          request: request,
          errorMessage: 'Server error (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return TryOnResult.failure(
        request: request,
        errorMessage: 'Network error connecting to backend: $e',
      );
    }
  }
}
