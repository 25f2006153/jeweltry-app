import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  // Web: store raw bytes since blob URLs can't be fetched server-side
  Uint8List? _userImageBytes;
  Uint8List? _jewelryImageBytes;

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

  /// Set user image from XFile (handles both web bytes and mobile path)
  Future<void> setUserImageFromXFile(XFile xfile) async {
    _userImagePath = xfile.path;
    if (kIsWeb) {
      _userImageBytes = await xfile.readAsBytes();
    }
    _errorMessage = null;
    notifyListeners();
  }

  /// Set jewelry image from XFile (handles both web bytes and mobile path)
  Future<void> setJewelryImageFromXFile(XFile xfile) async {
    _jewelryImagePath = xfile.path;
    if (kIsWeb) {
      _jewelryImageBytes = await xfile.readAsBytes();
    }
    _errorMessage = null;
    notifyListeners();
  }

  void setUserImagePath(String? path) {
    _userImagePath = path;
    _userImageBytes = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setJewelryImagePath(String? path) {
    _jewelryImagePath = path;
    _jewelryImageBytes = null;
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
    _jewelryImageBytes = null;
    _lastResult = null;
    _progress = 0.0;
    _statusMessage = '';
    _errorMessage = null;
    notifyListeners();
  }

  void resetAll() {
    _userImagePath = AppAssets.userSample;
    _jewelryImagePath = AppAssets.jewelryEarrings;
    _userImageBytes = null;
    _jewelryImageBytes = null;
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
        userImageBytes: _userImageBytes,
        jewelryImageBytes: _jewelryImageBytes,
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
