import 'dart:typed_data';

/// Preprocessing and payload optimization utility for pet photos,
/// clinical medical records, and AI vision analysis.
class ImageCompressionHelper {
  const ImageCompressionHelper._();

  /// Target maximum payload size for fast AI vision upload (~500 KB).
  static const int maxTargetBytes = 512 * 1024;

  /// Validates whether an image buffer is within the optimal size threshold for network dispatch.
  static bool isWithinOptimalSize(Uint8List imageBytes) {
    return imageBytes.lengthInBytes <= maxTargetBytes;
  }

  /// Calculates size compression ratio.
  static double calculateCompressionRatio({
    required int originalBytes,
    required int compressedBytes,
  }) {
    if (originalBytes <= 0) return 1.0;
    return (1.0 - (compressedBytes / originalBytes)).clamp(0.0, 1.0);
  }

  /// Formats human-readable file size strings (e.g. `2.4 MB`, `340 KB`).
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024.0).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024.0 * 1024.0)).toStringAsFixed(2)} MB';
  }
}
