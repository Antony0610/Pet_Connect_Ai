import 'package:flutter_test/flutter_test.dart';

import 'package:petconnect_ai/features/volunteer_rescue/data/models/lost_pet_alert_model.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/models/lost_pet_sighting_model.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/models/rescue_mission_model.dart';

void main() {
  group('Rescue Models DTO Unit Tests', () {
    test('LostPetAlertModel parses JSON correctly', () {
      final json = {
        'id': 'alert-1',
        'pet_id': 'pet-1',
        'owner_id': 'owner-1',
        'alert_status': 'ACTIVE',
        'last_seen_location': 'Central Park',
        'latitude': 40.785091,
        'longitude': -73.968285,
        'last_seen_time': '2026-08-12T10:00:00.000Z',
        'description': 'Golden Retriever lost near fountain',
        'contact_phone': '555-0199',
        'reward_amount': '\$500',
        'created_at': '2026-08-12T10:00:00.000Z',
        'updated_at': '2026-08-12T10:00:00.000Z',
      };

      final model = LostPetAlertModel.fromJson(json);
      expect(model.id, 'alert-1');
      expect(model.lastSeenLocation, 'Central Park');
      expect(model.toJson()['last_seen_location'], 'Central Park');
    });

    test('LostPetSightingModel parses JSON correctly', () {
      final json = {
        'id': 'sighting-1',
        'alert_id': 'alert-1',
        'reporter_id': 'user-2',
        'sighting_location': '5th Ave & 72nd St',
        'latitude': 40.772091,
        'longitude': -73.965285,
        'sighting_time': '2026-08-12T11:30:00.000Z',
        'photo_url': 'https://example.com/sighting.jpg',
        'notes': 'Spotted running south',
        'status': 'UNVERIFIED',
        'created_at': '2026-08-12T11:30:00.000Z',
      };

      final model = LostPetSightingModel.fromJson(json);
      expect(model.sightingLocation, '5th Ave & 72nd St');
      expect(model.toJson()['sighting_location'], '5th Ave & 72nd St');
    });

    test('RescueMissionModel parses JSON correctly', () {
      final json = {
        'id': 'mission-1',
        'alert_id': 'alert-1',
        'lead_volunteer_id': 'vol-1',
        'mission_title': 'Operation Search Buster',
        'priority': 'HIGH',
        'status': 'DISPATCHED',
        'search_radius_meters': 500,
        'notes': 'Grid search sector 4',
        'started_at': '2026-08-12T12:00:00.000Z',
        'completed_at': null,
        'created_at': '2026-08-12T12:00:00.000Z',
        'updated_at': '2026-08-12T12:00:00.000Z',
      };

      final model = RescueMissionModel.fromJson(json);
      expect(model.missionTitle, 'Operation Search Buster');
      expect(model.status, 'DISPATCHED');
      expect(model.toJson()['mission_title'], 'Operation Search Buster');
    });
  });
}
