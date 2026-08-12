import 'dart:typed_data';

import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/storage/domain/entities/pet_document.dart';
import 'package:petconnect_ai/features/storage/domain/entities/pet_gallery_media.dart';
import 'package:petconnect_ai/features/storage/domain/repositories/storage_repository.dart';

class UploadUserAvatar {
  const UploadUserAvatar(this._repository);
  final StorageRepository _repository;

  ResultFuture<String> call({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) => _repository.uploadUserAvatar(
    userId: userId,
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
}

class UploadPetAvatar {
  const UploadPetAvatar(this._repository);
  final StorageRepository _repository;

  ResultFuture<String> call({
    required String userId,
    required String petId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) => _repository.uploadPetAvatar(
    userId: userId,
    petId: petId,
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
}

class UploadGalleryMedia {
  const UploadGalleryMedia(this._repository);
  final StorageRepository _repository;

  ResultFuture<PetGalleryMedia> call({
    required String userId,
    required String petId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? caption,
  }) => _repository.uploadGalleryMedia(
    userId: userId,
    petId: petId,
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    caption: caption,
  );
}

class GetPetGalleryMedia {
  const GetPetGalleryMedia(this._repository);
  final StorageRepository _repository;

  ResultFuture<List<PetGalleryMedia>> call(String petId) =>
      _repository.getPetGalleryMedia(petId);
}

class UploadPetDocument {
  const UploadPetDocument(this._repository);
  final StorageRepository _repository;

  ResultFuture<PetDocument> call({
    required String userId,
    required String petId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String documentName,
    required String documentType,
  }) => _repository.uploadPetDocument(
    userId: userId,
    petId: petId,
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    documentName: documentName,
    documentType: documentType,
  );
}

class GetPetDocuments {
  const GetPetDocuments(this._repository);
  final StorageRepository _repository;

  ResultFuture<List<PetDocument>> call(String petId) =>
      _repository.getPetDocuments(petId);
}

class GetSignedUrl {
  const GetSignedUrl(this._repository);
  final StorageRepository _repository;

  ResultFuture<String> call({
    required String bucketId,
    required String filePath,
    int expiresInSeconds = 3600,
  }) => _repository.getSignedUrl(
    bucketId: bucketId,
    filePath: filePath,
    expiresInSeconds: expiresInSeconds,
  );
}
