import 'dart:typed_data';

import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/storage/domain/entities/pet_document.dart';
import 'package:petconnect_ai/features/storage/domain/entities/pet_gallery_media.dart';

/// Clean Architecture Repository contract for Supabase Storage & File Management.
abstract class StorageRepository {
  /// Upload user profile avatar to `user-avatars` bucket. Returns public URL.
  ResultFuture<String> uploadUserAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  });

  /// Upload pet avatar to `pet-avatars` bucket. Returns public URL.
  ResultFuture<String> uploadPetAvatar({
    required String userId,
    required String petId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  });

  /// Upload gallery image to `community-media` & record in `pet_gallery_media`.
  ResultFuture<PetGalleryMedia> uploadGalleryMedia({
    required String userId,
    required String petId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? caption,
  });

  /// List gallery media for a pet.
  ResultFuture<List<PetGalleryMedia>> getPetGalleryMedia(String petId);

  /// Delete gallery media item.
  ResultFuture<void> deleteGalleryMedia(String mediaId, String storagePath);

  /// Upload private document to `health-documents` or `vaccination-certificates`.
  ResultFuture<PetDocument> uploadPetDocument({
    required String userId,
    required String petId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String documentName,
    required String documentType,
  });

  /// List private documents for a pet.
  ResultFuture<List<PetDocument>> getPetDocuments(String petId);

  /// Generate signed URL (expires in [expiresInSeconds]) for a private document path.
  ResultFuture<String> getSignedUrl({
    required String bucketId,
    required String filePath,
    int expiresInSeconds = 3600,
  });

  /// Delete private document.
  ResultFuture<void> deletePetDocument({
    required String documentId,
    required String bucketId,
    required String filePath,
  });
}
