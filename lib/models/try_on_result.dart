import 'try_on_request.dart';

class TryOnResult {
  final String id;
  final String resultImagePath;
  final TryOnRequest request;
  final bool isSuccess;
  final String? errorMessage;
  final DateTime timestamp;
  final int processingTimeMs;

  TryOnResult({
    required this.id,
    required this.resultImagePath,
    required this.request,
    this.isSuccess = true,
    this.errorMessage,
    DateTime? timestamp,
    this.processingTimeMs = 0,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TryOnResult.failure({
    required TryOnRequest request,
    required String errorMessage,
  }) {
    return TryOnResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      resultImagePath: '',
      request: request,
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}
