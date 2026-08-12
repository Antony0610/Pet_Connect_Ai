# Phase 5 — Volunteer & Rescue / EOC Backend Documentation

**Document Status**: COMPLETE, DEPLOYED & VERIFIED  
**Target Supabase Project**: `PetConnect AI` (`cghgslyikjqghrzhrqxz`)  
**Region**: `ap-south-1`  
**Date**: August 13, 2026  

---

## 1. Executive Summary & Scope Control

Phase 5 backend implementation for **Volunteer & Rescue / EOC** has been fully created, deployed to live Supabase, integrated into Flutter Clean Architecture, unit tested, and verified.

Per strict scope control directives, Phase 5 focused exclusively on **Volunteer, Rescue Operations, EOC Dispatch, and Lost Pet Alerts/Sightings**. General social/community tables (`community_posts`, `saved_posts`, `post_comments`, `post_reactions`, `user_achievements`) were intentionally omitted and deferred to the Social & Community phase.

---

## 2. Live Database Schema (3 Physical Tables, 2 Security-Invoker Views)

### Physical Tables
1. **`public.lost_pet_alerts`** (`rls_enabled: true`):
   - `id` (UUID PRIMARY KEY DEFAULT gen_random_uuid())
   - `pet_id` (UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE)
   - `owner_id` (UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE)
   - `alert_status` ('ACTIVE', 'RESOLVED', 'CANCELLED')
   - `last_seen_location` (TEXT), `latitude` (NUMERIC), `longitude` (NUMERIC)
   - `last_seen_time` (TIMESTAMPTZ), `description` (TEXT), `contact_phone` (TEXT), `reward_amount` (TEXT)
   - `created_at`, `updated_at` (TIMESTAMPTZ)

2. **`public.lost_pet_sightings`** (`rls_enabled: true`):
   - `id` (UUID PRIMARY KEY DEFAULT gen_random_uuid())
   - `alert_id` (UUID NOT NULL REFERENCES public.lost_pet_alerts(id) ON DELETE CASCADE)
   - `reporter_id` (UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE)
   - `sighting_location` (TEXT), `latitude` (NUMERIC), `longitude` (NUMERIC)
   - `sighting_time` (TIMESTAMPTZ), `photo_url` (TEXT), `notes` (TEXT)
   - `status` ('UNVERIFIED', 'CONFIRMED', 'DISMISSED')
   - `created_at` (TIMESTAMPTZ)

3. **`public.rescue_missions`** (`rls_enabled: true`):
   - `id` (UUID PRIMARY KEY DEFAULT gen_random_uuid())
   - `alert_id` (UUID NOT NULL REFERENCES public.lost_pet_alerts(id) ON DELETE CASCADE)
   - `lead_volunteer_id` (UUID REFERENCES public.profiles(id) ON DELETE SET NULL)
   - `mission_title` (TEXT), `priority` ('HIGH', 'CRITICAL', 'ROUTINE')
   - `status` ('DISPATCHED', 'IN_PROGRESS', 'COMPLETED', 'ABORTED')
   - `search_radius_meters` (INT), `notes` (TEXT)
   - `started_at`, `completed_at`, `created_at`, `updated_at` (TIMESTAMPTZ)

### Security-Invoker Database Views
1. **`public.vw_active_lost_pets`**: View listing active alerts joined with pet and owner profiles. Verified with `WITH (security_invoker = true)`.
2. **`public.vw_nearby_rescue_requests`**: View listing active dispatch requests formatted for EOC HUDs. Verified with `WITH (security_invoker = true)`.

---

## 3. Security & Row Level Security (RLS)

- **`lost_pet_alerts`**: Public read for active alerts; insert/update restricted to owner (`owner_id = auth.uid()`) or Rescuers (`role IN ('volunteer_rescue', 'administrator')`).
- **`lost_pet_sightings`**: Read restricted to reporter, alert owner, or Rescuers; insert restricted to reporter (`reporter_id = auth.uid()`).
- **`rescue_missions`**: Read and write restricted to assigned rescuers or alert owners.
- **View Security**: Verified in `pg_class.reloptions` that both views have `security_invoker=true`, preventing RLS bypass.

---

## 4. Storage & Realtime

- **Storage Bucket**: `rescue-evidence` deployed for sighting photos and field verification.
- **Realtime**: Enabled broadcast triggers on `lost_pet_alerts`, `lost_pet_sightings`, and `rescue_missions`.

---

## 5. Flutter Clean Architecture Integration

- **Entities**: `LostPetAlert`, `LostPetSighting`, `RescueMission`
- **Repository Interface**: `RescueRepository`
- **Use Cases**: `GetActiveLostPetAlerts`, `CreateLostPetAlert`, `GetSightingsForAlert`, `ReportSighting`, `GetRescueMissions`, `CreateRescueMission`, `UpdateMissionStatus`
- **Data Layer**: DTO Models (`LostPetAlertModel`, `LostPetSightingModel`, `RescueMissionModel`), `RescueRemoteDataSourceImpl`, `RescueRepositoryImpl`
- **Providers**: `rescueProviders.dart` (`rescueRepositoryProvider`, `activeLostPetAlertsProvider`, `rescueMissionsProvider`, `sightingsProvider`)
- **UI Screens**: Connected `MissionDashboardScreen` to `rescueMissionsProvider`.

---

## 6. Testing & Verification Summary

- **Dart Analyzer**: `dart analyze lib test` → **No issues found!**
- **Unit Test Suite**: `flutter test test/unit/` → **122/122 tests passed!**
- **Live Supabase Audit**: Verified all 18 physical tables (15 from Phases 1–4 + 3 from Phase 5) and 3 security-invoker views (`vw_patient_queue`, `vw_active_lost_pets`, `vw_nearby_rescue_requests`).
