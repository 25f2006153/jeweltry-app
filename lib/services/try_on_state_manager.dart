import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../models/jewelry_type.dart';
import '../models/try_on_request.dart';
import '../models/try_on_result.dart';
import 'ai_service.dart';

class TryOnStateManager extends ChangeNotifier {
  final AIService _aiService;

  String? _userImagePath = AppAssets.userSample;
  String? _jewelryImagePath = AppAssets.jewelryEarrings;
  JewelryType _selectedJewelryType = JewelryType.earrings;

  bool _isGenerating = false;
  double _progress = 0.0;
  String _statusMessage = '';
  TryOnResult? _lastResult;
  String? _errorMessage;

  TryOnStateManager({required AIService aiService}) : _aiService = aiService;

  // Getters
  String? get userImagePath => _userImagePath;
  String? get jewelryImagePath => _jewelryImagePath;
  JewelryType get selectedJewelryType => _selectedJewelryType;
  bool get isGenerating => _isGenerating;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  TryOnResult? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;

  bool get canContinueUpload =>
      _userImagePath != null &&
      _userImagePath!.isNotEmpty &&
      _jewelryImagePath != null &&
      _jewelryImagePath!.isNotEmpty;

  void setUserImagePath(String? path) {
    _userImagePath = path;
    _errorMessage = null;
    notifyListeners();
  }

  void setJewelryImagePath(String? path) {
    _jewelryImagePath = path;
    _errorMessage = null;
    notifyListeners();
  }

  void setSelectedJewelryType(JewelryType type) {
    _selectedJewelryType = type;
    notifyListeners();
  }

  /// Reset jewelry photo & result for "Try Another" flow while preserving user photo!
  void prepareTryAnother() {
    _jewelryImagePath = null;
    _lastResult = null;
    _progress = 0.0;
    _statusMessage = '';
    _errorMessage = null;
    notifyListeners();
  }

  void resetAll() {
    _userImagePath = AppAssets.userSample;
    _jewelryImagePath = AppAssets.jewelryEarrings;
    _selectedJewelryType = JewelryType.earrings;
    _isGenerating = false;
    _progress = 0.0;
    _statusMessage = '';
    _lastResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> runTryOnGeneration() async {
    if (!canContinueUpload) {
      _errorMessage = 'Please upload both your photo and a jewelry photo.';
      notifyListeners();
      return false;
    }

    _isGenerating = true;
    _progress = 0.0;
    _statusMessage = 'Starting AI Virtual Try-On...';
    _errorMessage = null;
    notifyListeners();

    try {
      final request = TryOnRequest(
        userImagePath: _userImagePath!,
        jewelryImagePath: _jewelryImagePath!,
        jewelryType: _selectedJewelryType,
      );

      final result = await _aiService.generateTryOn(
        request,
        onProgress: (progressVal, statusMsg) {
          _progress = progressVal;
          _statusMessage = statusMsg;
          notifyListeners();
        },
      );

      _lastResult = result;
      _isGenerating = false;

      if (!result.isSuccess) {
        _errorMessage = result.errorMessage ?? 'Something went wrong. Please try again.';
      }

      notifyListeners();
      return result.isSuccess;
    } catch (e) {
      _isGenerating = false;
      _errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
