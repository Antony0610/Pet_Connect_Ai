import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_event.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_settings.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_share.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/pet_repository.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';

class FakePetRepository implements PetRepository {
  final List<Pet> pets = [
    const Pet(id: 'p1', ownerId: 'u1', name: 'Luna', species: 'dog'),
    const Pet(id: 'p2', ownerId: 'u1', name: 'Oliver', species: 'cat'),
  ];

  @override
  ResultFuture<List<Pet>> getPets() async => Right(pets);

  @override
  ResultFuture<Pet?> getPetById(String id) async =>
      Right(pets.where((p) => p.id == id).firstOrNull);

  @override
  ResultFuture<Pet> createPet(Pet pet) async {
    pets.add(pet);
    return Right(pet);
  }

  @override
  ResultFuture<Pet> updatePet(Pet pet) async {
    pets.removeWhere((p) => p.id == pet.id);
    pets.add(pet);
    return Right(pet);
  }

  @override
  ResultVoid deletePet(String id) async {
    pets.removeWhere((p) => p.id == id);
    return const Right(null);
  }

  @override
  ResultFuture<PetSettings?> getPetSettings(String petId) async =>
      Right(PetSettings(petId: petId));

  @override
  ResultVoid updatePetSettings(PetSettings settings) async => const Right(null);

  @override
  ResultFuture<Map<String, dynamic>> activateLostMode({
    required String petId,
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String description,
  }) async => const Right({'status': 'active'});

  @override
  ResultVoid resolveLostMode(String petId) async => const Right(null);

  @override
  ResultFuture<Map<String, dynamic>?> getActiveLostAlert(String petId) async => const Right(null);

  @override
  ResultFuture<List<Map<String, dynamic>>> getCommunitySightings({String? petId}) async => const Right([]);

  @override
  ResultFuture<Map<String, dynamic>> submitSighting({
    required String petId,
    required double latitude,
    required double longitude,
    required String locationName,
    required String note,
    String? photoUrl,
  }) async => const Right({'id': 's-1'});

  @override
  ResultFuture<List<PetShare>> getPetShares(String petId) async => const Right([]);

  @override
  ResultFuture<PetShare> inviteCaregiver({
    required String petId,
    required String email,
    required String role,
    required String permissionLevel,
  }) async => Right(
        PetShare(
          id: 'share-1',
          petId: petId,
          userId: 'u-1',
          userEmail: email,
          userName: 'Caregiver',
          role: role,
          permissionLevel: permissionLevel,
          invitedAt: DateTime.now(),
        ),
      );

  @override
  ResultVoid revokeCaregiver(String shareId) async => const Right(null);

  @override
  ResultFuture<List<CommunityEvent>> getCommunityEvents({String? category}) async => const Right([]);

  @override
  ResultFuture<bool> toggleEventRegistration(String eventId) async => const Right(true);
}

void main() {
  late ProviderContainer container;
  late FakePetRepository fakeRepository;

  setUp(() {
    fakeRepository = FakePetRepository();
    container = ProviderContainer(
      overrides: [petRepositoryProvider.overrideWithValue(fakeRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Pet Providers & Notifier', () {
    test('petsProvider loads initial pet list', () async {
      final petsAsync = await container.read(petsProvider.future);
      expect(petsAsync.length, 2);
      expect(petsAsync.first.name, 'Luna');
    });

    test(
      'selectedPetProvider defaults to first pet when selectedPetId is null',
      () async {
        await container.read(petsProvider.future);
        final selected = container.read(selectedPetProvider);
        expect(selected, isNotNull);
        expect(selected?.id, 'p1');
      },
    );

    test(
      'selectedPetProvider updates when selectedPetIdProvider changes',
      () async {
        await container.read(petsProvider.future);
        container.read(selectedPetIdProvider.notifier).state = 'p2';

        final selected = container.read(selectedPetProvider);
        expect(selected?.id, 'p2');
        expect(selected?.name, 'Oliver');
      },
    );

    test('petDetailProvider fetches pet by family key', () async {
      final pet = await container.read(petDetailProvider('p2').future);
      expect(pet?.name, 'Oliver');
    });
  });
}
