import 'dart:typed_data';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/features/storage/data/models/pet_document_model.dart';
import 'package:petconnect_ai/features/storage/data/models/pet_gallery_media_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class StorageRemoteDataSource {
  Future<String> uploadFile({
    required String bucketId,
    required String path,
    required Uint8List bytes,
    required String mimeType,
  });

  Future<String> getPublicUrl({required String bucketId, required String path});

  Future<String> createSignedUrl({
    required String bucketId,
    required String path,
    int expiresInSeconds = 3600,
  });

  Future<void> deleteFile({required String bucketId, required String path});

  Future<PetGalleryMediaModel> insertGalleryRecord(PetGalleryMediaModel model);
  Future<List<PetGalleryMediaModel>> getPetGalleryRecords(String petId);
  Future<void> deleteGalleryRecord(String mediaId);

  Future<PetDocumentModel> insertDocumentRecord(PetDocumentModel model);
  Future<List<PetDocumentModel>> getPetDocumentRecords(String petId);
  Future<void> deleteDocumentRecord(String documentId);
}

class StorageRemoteDataSourceImpl implements StorageRemoteDataSource {
  const StorageRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<String> uploadFile({
    required String bucketId,
    required String path,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      await _client.storage
          .from(bucketId)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );
      return path;
    } on StorageException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.statusCode ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to upload file to $bucketId: $e');
    }
  }

  @override
  Future<String> getPublicUrl({
    required String bucketId,
    required String path,
  }) async {
    try {
      return _client.storage.from(bucketId).getPublicUrl(path);
    } catch (e) {
      throw ServerException('Failed to get public URL for $path: $e');
    }
  }

  @override
  Future<String> createSignedUrl({
    required String bucketId,
    required String path,
    int expiresInSeconds = 3600,
  }) async {
    try {
      final url = await _client.storage
          .from(bucketId)
          .createSignedUrl(path, expiresInSeconds);
      return url;
    } on StorageException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.statusCode ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to create signed URL for $path: $e');
    }
  }

  @override
  Future<void> deleteFile({
    required String bucketId,
    required String path,
  }) async {
    try {
      await _client.storage.from(bucketId).remove([path]);
    } on StorageException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.statusCode ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to delete file $path: $e');
    }
  }

  @override
  Future<PetGalleryMediaModel> insertGalleryRecord(
    PetGalleryMediaModel model,
  ) async {
    try {
      final response = await _client
          .from('pet_gallery_media')
          .insert(model.toJson())
          .select()
          .single();
      return PetGalleryMediaModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to insert gallery record: $e');
    }
  }

  @override
  Future<List<PetGalleryMediaModel>> getPetGalleryRecords(String petId) async {
    try {
      final response = await _client
          .from('pet_gallery_media')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) =>
                PetGalleryMediaModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch gallery records: $e');
    }
  }

  @override
  Future<void> deleteGalleryRecord(String mediaId) async {
    try {
      await _client.from('pet_gallery_media').delete().eq('id', mediaId);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to delete gallery record: $e');
    }
  }

  @override
  Future<PetDocumentModel> insertDocumentRecord(PetDocumentModel model) async {
    try {
      final response = await _client
          .from('pet_documents')
          .insert(model.toJson())
          .select()
          .single();
      return PetDocumentModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to insert document record: $e');
    }
  }

  @override
  Future<List<PetDocumentModel>> getPetDocumentRecords(String petId) async {
    try {
      final response = await _client
          .from('pet_documents')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => PetDocumentModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch document records: $e');
    }
  }

  @override
  Future<void> deleteDocumentRecord(String documentId) async {
    try {
      await _client.from('pet_documents').delete().eq('id', documentId);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to delete document record: $e');
    }
  }
}
