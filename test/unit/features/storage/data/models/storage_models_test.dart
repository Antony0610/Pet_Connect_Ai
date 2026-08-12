import 'package:flutter_test/flutter_test.dart';

import 'package:petconnect_ai/features/storage/data/models/pet_document_model.dart';
import 'package:petconnect_ai/features/storage/data/models/pet_gallery_media_model.dart';

void main() {
  group('Storage Models DTO Unit Tests', () {
    test('PetGalleryMediaModel parses JSON correctly', () {
      final json = {
        'id': 'media-1',
        'pet_id': 'pet-1',
        'uploaded_by': 'user-1',
        'media_url': 'https://example.com/pet.jpg',
        'storage_path': 'user-1/pet.jpg',
        'caption': 'Fun day at park',
        'file_size': 1024500,
        'mime_type': 'image/jpeg',
        'created_at': '2026-08-12T10:00:00.000Z',
      };

      final model = PetGalleryMediaModel.fromJson(json);
      expect(model.id, 'media-1');
      expect(model.petId, 'pet-1');
      expect(model.mediaUrl, 'https://example.com/pet.jpg');
      expect(model.caption, 'Fun day at park');
      expect(model.fileSize, 1024500);
    });

    test('PetGalleryMediaModel toJson produces valid output', () {
      final model = PetGalleryMediaModel(
        id: 'media-1',
        petId: 'pet-1',
        uploadedBy: 'user-1',
        mediaUrl: 'https://example.com/pet.jpg',
        storagePath: 'user-1/pet.jpg',
        caption: 'Playing fetch',
        fileSize: 204800,
        mimeType: 'image/png',
        createdAt: DateTime.utc(2026, 8, 12),
      );

      final json = model.toJson();
      expect(json['pet_id'], 'pet-1');
      expect(json['uploaded_by'], 'user-1');
      expect(json['media_url'], 'https://example.com/pet.jpg');
      expect(json['storage_path'], 'user-1/pet.jpg');
    });

    test('PetDocumentModel parses JSON correctly', () {
      final json = {
        'id': 'doc-1',
        'pet_id': 'pet-1',
        'uploaded_by': 'user-1',
        'document_name': 'Rabies Vaccine Cert',
        'document_type': 'VACCINATION_CERT',
        'file_path': 'user-1/pet-1/cert.pdf',
        'signed_url': 'https://example.com/signed.pdf',
        'file_size': 512000,
        'mime_type': 'application/pdf',
        'created_at': '2026-08-12T11:00:00.000Z',
      };

      final model = PetDocumentModel.fromJson(json);
      expect(model.id, 'doc-1');
      expect(model.documentName, 'Rabies Vaccine Cert');
      expect(model.documentType, 'VACCINATION_CERT');
      expect(model.signedUrl, 'https://example.com/signed.pdf');
    });

    test('PetDocumentModel copyWith updates signedUrl', () {
      final model = PetDocumentModel(
        id: 'doc-1',
        petId: 'pet-1',
        uploadedBy: 'user-1',
        documentName: 'Lab Results',
        filePath: 'user-1/pet-1/lab.pdf',
        createdAt: DateTime.utc(2026, 8, 12),
      );

      final updated = model.copyWith(signedUrl: 'https://signed.url/lab.pdf');
      expect(updated.signedUrl, 'https://signed.url/lab.pdf');
      expect(updated.id, 'doc-1');
    });
  });
}
