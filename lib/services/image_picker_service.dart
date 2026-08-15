import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return file?.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image from gallery: $e');
      }
      return null;
    }
  }

  Future<String?> captureImageFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return file?.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error capturing image from camera: $e');
      }
      return null;
    }
  }

  bool isValidImagePath(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    if (kIsWeb) return true; // Web uses network/blob/data URLs
    if (path.startsWith('assets/')) return true; // Bundled asset
    return File(path).existsSync();
  }
}
