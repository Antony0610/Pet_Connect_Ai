import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/features/storage/domain/entities/pet_document.dart';
import 'package:petconnect_ai/features/storage/domain/entities/pet_gallery_media.dart';
import 'package:petconnect_ai/features/storage/domain/repositories/storage_repository.dart';
import 'package:petconnect_ai/features/storage/presentation/providers/storage_providers.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

void main() {
  late MockStorageRepository mockRepo;

  final now = DateTime(2026, 8, 12);

  final tMedia = PetGalleryMedia(
    id: 'media-1',
    petId: 'pet-1',
    uploadedBy: 'user-1',
    mediaUrl: 'https://example.com/pet.jpg',
    storagePath: 'user-1/pet.jpg',
    createdAt: now,
  );

  final tDoc = PetDocument(
    id: 'doc-1',
    petId: 'pet-1',
    uploadedBy: 'user-1',
    documentName: 'Rabies Cert',
    filePath: 'user-1/pet-1/cert.pdf',
    createdAt: now,
  );

  setUp(() {
    mockRepo = MockStorageRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [storageRepositoryProvider.overrideWithValue(mockRepo)],
    );
  }

  group('Storage Providers Unit Tests', () {
    test('petGalleryMediaProvider loads media for pet', () async {
      when(
        () => mockRepo.getPetGalleryMedia('pet-1'),
      ).thenAnswer((_) async => Right([tMedia]));

      final container = makeContainer();
      final media = await container.read(
        petGalleryMediaProvider('pet-1').future,
      );

      expect(media, [tMedia]);
      verify(() => mockRepo.getPetGalleryMedia('pet-1')).called(1);
    });

    test('petDocumentsProvider loads documents for pet', () async {
      when(
        () => mockRepo.getPetDocuments('pet-1'),
      ).thenAnswer((_) async => Right([tDoc]));

      final container = makeContainer();
      final docs = await container.read(petDocumentsProvider('pet-1').future);

      expect(docs, [tDoc]);
      verify(() => mockRepo.getPetDocuments('pet-1')).called(1);
    });
  });
}
