import '../models/try_on_request.dart';
import '../models/try_on_result.dart';

typedef TryOnProgressCallback = void Function(double progress, String statusMessage);

abstract class AIService {
  Future<TryOnResult> generateTryOn(
    TryOnRequest request, {
    TryOnProgressCallback? onProgress,
  });
}
