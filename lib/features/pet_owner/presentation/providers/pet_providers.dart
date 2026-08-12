import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/features/pet_owner/data/datasources/pet_remote_datasource.dart';
import 'package:petconnect_ai/features/pet_owner/data/repositories/pet_repository_impl.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_settings.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/pet_repository.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/create_pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/delete_pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/get_pet_by_id.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/get_pet_settings.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/get_pets.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/update_pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/update_pet_settings.dart';

// ── Data Layer Providers ──────────────────────────────────────────────

final petRemoteDataSourceProvider = Provider<PetRemoteDataSource>(
  (ref) => PetRemoteDataSourceImpl(ref.watch(supabaseClientProvider)),
);

final petRepositoryProvider = Provider<PetRepository>(
  (ref) => PetRepositoryImpl(ref.watch(petRemoteDataSourceProvider)),
);

// ── Domain Layer UseCase Providers ────────────────────────────────────

final getPetsProvider = Provider<GetPets>(
  (ref) => GetPets(ref.watch(petRepositoryProvider)),
);

final getPetByIdProvider = Provider<GetPetById>(
  (ref) => GetPetById(ref.watch(petRepositoryProvider)),
);

final createPetUseCaseProvider = Provider<CreatePet>(
  (ref) => CreatePet(ref.watch(petRepositoryProvider)),
);

final updatePetUseCaseProvider = Provider<UpdatePet>(
  (ref) => UpdatePet(ref.watch(petRepositoryProvider)),
);

final deletePetUseCaseProvider = Provider<DeletePet>(
  (ref) => DeletePet(ref.watch(petRepositoryProvider)),
);

final getPetSettingsUseCaseProvider = Provider<GetPetSettings>(
  (ref) => GetPetSettings(ref.watch(petRepositoryProvider)),
);

final updatePetSettingsUseCaseProvider = Provider<UpdatePetSettings>(
  (ref) => UpdatePetSettings(ref.watch(petRepositoryProvider)),
);

// ── Presentation State Providers ──────────────────────────────────────

/// Notifier managing real-time list of current user's pets.
class PetsNotifier extends AsyncNotifier<List<Pet>> {
  @override
  Future<List<Pet>> build() async {
    final getPets = ref.watch(getPetsProvider);
    final result = await getPets(const NoParams());
    return result.fold(
      (failure) => throw Exception(failure.message),
      (pets) => pets,
    );
  }

  /// Reloads pets from Supabase.
  Future<void> refreshPets() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final getPets = ref.read(getPetsProvider);
      final result = await getPets(const NoParams());
      return result.fold(
        (failure) => throw Exception(failure.message),
        (pets) => pets,
      );
    });
  }
}

final petsProvider = AsyncNotifierProvider<PetsNotifier, List<Pet>>(
  PetsNotifier.new,
);

/// Currently selected pet ID in the UI.
final selectedPetIdProvider = StateProvider<String?>((ref) => null);

/// Resolves currently selected [Pet] entity.
final selectedPetProvider = Provider<Pet?>((ref) {
  final petsAsync = ref.watch(petsProvider);
  final selectedId = ref.watch(selectedPetIdProvider);

  return petsAsync.when(
    data: (pets) {
      if (pets.isEmpty) return null;
      if (selectedId != null) {
        final match = pets.where((p) => p.id == selectedId).firstOrNull;
        if (match != null) return match;
      }
      return pets.first;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Fetches individual pet details.
final petDetailProvider = FutureProvider.family<Pet?, String>((
  ref,
  petId,
) async {
  final getPetById = ref.watch(getPetByIdProvider);
  final result = await getPetById(petId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (pet) => pet,
  );
});

/// Fetches pet settings preferences.
final petSettingsProvider = FutureProvider.family<PetSettings?, String>((
  ref,
  petId,
) async {
  final getSettings = ref.watch(getPetSettingsUseCaseProvider);
  final result = await getSettings(petId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (settings) => settings,
  );
});
