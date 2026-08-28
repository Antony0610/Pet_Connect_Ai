import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/core/utils/qr_generator_helper.dart';

void main() {
  group('QrCodeHelper Unit Tests', () {
    test('generateQrMatrix creates a valid non-empty square matrix', () {
      const data = 'https://petconnect.ai/emergency/pet-123';
      final matrix = QrCodeHelper.generateQrMatrix(data);

      expect(matrix.isNotEmpty, isTrue);
      expect(matrix.length, equals(matrix.first.length));
      expect(matrix.length, isPositive);
    });

    test('generateQrMatrix places finder patterns at all three corners', () {
      const data = 'https://petconnect.ai/emergency/test';
      final matrix = QrCodeHelper.generateQrMatrix(data);
      final size = matrix.length;

      // Top-Left corner center (r=3, c=3) should be true (black)
      expect(matrix[3][3], isTrue);

      // Top-Right corner center (r=3, c=size-4) should be true (black)
      expect(matrix[3][size - 4], isTrue);

      // Bottom-Left corner center (r=size-4, c=3) should be true (black)
      expect(matrix[size - 4][3], isTrue);
    });

    test('generateQrMatrix dynamically scales matrix size for longer data', () {
      const shortData = 'short';
      const longData = 'https://petconnect.ai/emergency/pet-long-identifier-with-metadata-string-longer-than-70-characters';

      final shortMatrix = QrCodeHelper.generateQrMatrix(shortData);
      final longMatrix = QrCodeHelper.generateQrMatrix(longData);

      expect(longMatrix.length, greaterThanOrEqualTo(shortMatrix.length));
    });
  });
}
