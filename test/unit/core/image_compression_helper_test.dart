import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/core/utils/image_compression_helper.dart';

void main() {
  group('ImageCompressionHelper Unit Tests', () {
    test('isWithinOptimalSize validates image sizes accurately', () {
      final smallBuffer = Uint8List(200 * 1024); // 200 KB
      final largeBuffer = Uint8List(800 * 1024); // 800 KB

      expect(ImageCompressionHelper.isWithinOptimalSize(smallBuffer), isTrue);
      expect(ImageCompressionHelper.isWithinOptimalSize(largeBuffer), isFalse);
    });

    test('calculateCompressionRatio returns accurate reduction percentage', () {
      const original = 1000;
      const compressed = 300;

      final ratio = ImageCompressionHelper.calculateCompressionRatio(
        originalBytes: original,
        compressedBytes: compressed,
      );

      expect(ratio, closeTo(0.70, 0.01)); // 70% savings
    });

    test('formatBytes formats B, KB, and MB cleanly', () {
      expect(ImageCompressionHelper.formatBytes(500), equals('500 B'));
      expect(ImageCompressionHelper.formatBytes(2048), equals('2.0 KB'));
      expect(ImageCompressionHelper.formatBytes(2 * 1024 * 1024), equals('2.00 MB'));
    });
  });
}
