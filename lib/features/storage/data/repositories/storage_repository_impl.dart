import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failure_mapper.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/storage/data/datasources/storage_remote_datasource.dart';
import 'package:petconnect_ai/features/storage/data/models/pet_document_model.dart';
import 'package:petconnect_ai/features/storage/data/models/pet_gallery_media_model.dart';
import 'package:petconnect_ai/features/storage/domain/entities/pet_document.dart';
import 'package:petconnect_ai/features/storage/domain/entities/pet_gallery_media.dart';
import 'package:petconnect_ai/features/storage/domain/repositories/storage_repository.dart';

class StorageRepositoryImpl implements StorageRepository {
  const StorageRepositoryImpl(this._remote);

  final StorageRemoteDataSource _remote;

  @override
  ResultFuture<String> uploadUserAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final path = '$userId/$fileName';
      await _remote.uploadFile(
        bucketId: 'user-avatars',
        path: path,
        bytes: bytes,
        mimeType: mimeType,
      );
      final publicUrl = await _remote.getPublicUrl(
        bucketId: 'user-avatars',
        path: path,
      );
      return Right(publicUrl);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<String> uploadPetAvatar({
    required String userId,
    required String petId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final path = '$userId/$petId/$fileName';
      await _remote.uploadFile(
        bucketId: 'pet-avatars',
        path: path,
        bytes: bytes,
        mimeType: mimeType,
      );
      final publicUrl = await _remote.getPublicUrl(
        bucketId: 'pet-avatars',
        path: path,
      );
      return Right(publicUrl);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<PetGalleryMedia> uploadGalleryMedia({
    required String userId,
    required String petId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? caption,
  }) async {
    try {
      final storagePath = '$userId/$fileName';
      await _remote.uploadFile(
        bucketId: 'community-media',
        path: storagePath,
        bytes: bytes,
        mimeType: mimeType,
      );
      final publicUrl = await _remote.getPublicUrl(
        bucketId: 'community-media',
        path: storagePath,
      );

      final model = PetGalleryMediaModel(
        id: '',
        petId: petId,
        uploadedBy: userId,
        mediaUrl: publicUrl,
        storagePath: storagePath,
        caption: caption,
        fileSize: bytes.length,
        mimeType: mimeType,
        createdAt: DateTime.now().toUtc(),
      );

      final inserted = await _remote.insertGalleryRecord(model);
      return Right(inserted);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<PetGalleryMedia>> getPetGalleryMedia(String petId) async {
    try {
      final list = await _remote.getPetGalleryRecords(petId);
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<void> deleteGalleryMedia(
    String mediaId,
    String storagePath,
  ) async {
    try {
      await _remote.deleteFile(bucketId: 'community-media', path: storagePath);
      await _remote.deleteGalleryRecord(mediaId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<PetDocument> uploadPetDocument({
    required String userId,
    required String petId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String documentName,
    required String documentType,
  }) async {
    try {
      final bucketId = documentType == 'VACCINATION_CERT'
          ? 'vaccination-certificates'
          : 'health-documents';
      final path = '$userId/$petId/$fileName';

      await _remote.uploadFile(
        bucketId: bucketId,
        path: path,
        bytes: bytes,
        mimeType: mimeType,
      );

      final signedUrl = await _remote.createSignedUrl(
        bucketId: bucketId,
        path: path,
      );

      final model = PetDocumentModel(
        id: '',
        petId: petId,
        uploadedBy: userId,
        documentName: documentName,
        documentType: documentType,
        filePath: path,
        signedUrl: signedUrl,
        fileSize: bytes.length,
        mimeType: mimeType,
        createdAt: DateTime.now().toUtc(),
      );

      final inserted = await _remote.insertDocumentRecord(model);
      return Right(inserted.copyWith(signedUrl: signedUrl));
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<PetDocument>> getPetDocuments(String petId) async {
    try {
      final list = await _remote.getPetDocumentRecords(petId);
      final withSignedUrls = <PetDocument>[];

      for (final doc in list) {
        final bucketId = doc.documentType == 'VACCINATION_CERT'
            ? 'vaccination-certificates'
            : 'health-documents';
        try {
          final signedUrl = await _remote.createSignedUrl(
            bucketId: bucketId,
            path: doc.filePath,
          );
          withSignedUrls.add(doc.copyWith(signedUrl: signedUrl));
        } catch (_) {
          withSignedUrls.add(doc);
        }
      }

      return Right(withSignedUrls);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<String> getSignedUrl({
    required String bucketId,
    required String filePath,
    int expiresInSeconds = 3600,
  }) async {
    try {
      final url = await _remote.createSignedUrl(
        bucketId: bucketId,
        path: filePath,
        expiresInSeconds: expiresInSeconds,
      );
      return Right(url);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<void> deletePetDocument({
    required String documentId,
    required String bucketId,
    required String filePath,
  }) async {
    try {
      await _remote.deleteFile(bucketId: bucketId, path: filePath);
      await _remote.deleteDocumentRecord(documentId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }
}
