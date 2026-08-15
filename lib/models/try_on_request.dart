import 'jewelry_type.dart';

class TryOnRequest {
  final String userImagePath;
  final String jewelryImagePath;
  final JewelryType jewelryType;
  final DateTime createdAt;

  TryOnRequest({
    required this.userImagePath,
    required this.jewelryImagePath,
    required this.jewelryType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'user_image_path': userImagePath,
      'jewelry_image_path': jewelryImagePath,
      'jewelry_type': jewelryType.name,
      'target_anchor': jewelryType.targetAnchor,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
