import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_event.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_settings.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_share.dart';
import 'package:petconnect_ai/shared/domain/repository.dart';

/// Domain contract for core Pet management operations.
abstract interface class PetRepository implements Repository {
  /// Fetches all pets owned by the currently authenticated user.
  ResultFuture<List<Pet>> getPets();

  /// Fetches a specific pet owned by the currently authenticated user by [id].
  ResultFuture<Pet?> getPetById(String id);

  /// Creates a new pet for the currently authenticated user.
  ResultFuture<Pet> createPet(Pet pet);

  /// Updates an existing pet owned by the currently authenticated user.
  ResultFuture<Pet> updatePet(Pet pet);

  /// Deletes a pet owned by the currently authenticated user by [id].
  ResultVoid deletePet(String id);

  /// Reads pet preference settings for [petId].
  ResultFuture<PetSettings?> getPetSettings(String petId);

  /// Saves pet preference settings for [petId].
  ResultVoid updatePetSettings(PetSettings settings);

  /// Activates Lost Mode in Supabase `lost_pet_alerts`.
  ResultFuture<Map<String, dynamic>> activateLostMode({
    required String petId,
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String description,
  });

  /// Resolves Lost Mode for an active alert or pet.
  ResultVoid resolveLostMode(String petId);

  /// Fetches active lost alert for a pet.
  ResultFuture<Map<String, dynamic>?> getActiveLostAlert(String petId);

  /// Fetches community sightings for a pet or general sightings.
  ResultFuture<List<Map<String, dynamic>>> getCommunitySightings({String? petId});

  /// Submits a new community sighting report.
  ResultFuture<Map<String, dynamic>> submitSighting({
    required String petId,
    required double latitude,
    required double longitude,
    required String locationName,
    required String note,
    String? photoUrl,
  });

  /// Fetches shared caregivers/co-owners for [petId].
  ResultFuture<List<PetShare>> getPetShares(String petId);

  /// Invites a new caregiver for [petId].
  ResultFuture<PetShare> inviteCaregiver({
    required String petId,
    required String email,
    required String role,
    required String permissionLevel,
  });

  /// Revokes caregiver access by [shareId].
  ResultVoid revokeCaregiver(String shareId);

  /// Fetches community events.
  ResultFuture<List<CommunityEvent>> getCommunityEvents({String? category});

  /// Toggles event RSVP registration.
  ResultFuture<bool> toggleEventRegistration(String eventId);
}
