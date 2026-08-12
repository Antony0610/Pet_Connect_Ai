import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/features/storage/data/datasources/storage_remote_datasource.dart';
import 'package:petconnect_ai/features/storage/data/repositories/storage_repository_impl.dart';
import 'package:petconnect_ai/features/storage/domain/entities/pet_document.dart';
import 'package:petconnect_ai/features/storage/domain/entities/pet_gallery_media.dart';
import 'package:petconnect_ai/features/storage/domain/repositories/storage_repository.dart';

final storageRemoteDataSourceProvider = Provider<StorageRemoteDataSource>((
  ref,
) {
  return StorageRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepositoryImpl(ref.watch(storageRemoteDataSourceProvider));
});

final petGalleryMediaProvider =
    FutureProvider.family<List<PetGalleryMedia>, String>((ref, petId) async {
      final repo = ref.watch(storageRepositoryProvider);
      final result = await repo.getPetGalleryMedia(petId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (media) => media,
      );
    });

final petDocumentsProvider = FutureProvider.family<List<PetDocument>, String>((
  ref,
  petId,
) async {
  final repo = ref.watch(storageRepositoryProvider);
  final result = await repo.getPetDocuments(petId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (docs) => docs,
  );
});
