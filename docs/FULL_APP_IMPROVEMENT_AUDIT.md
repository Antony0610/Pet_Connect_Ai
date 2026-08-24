# PetConnect AI — Full App Improvement Audit
> Generated: 2026-08-22 | Project ID: cghgslyikjqghrzhrqxz

---

## Backend Audit (Live Supabase)

### Tables (31 total — all RLS enabled)
| Table | Rows | RLS |
|-------|------|-----|
| profiles | 3 | ✅ Correct (select public, insert/update own) |
| pets | 1 | ✅ Correct (owner select/insert/update, soft-delete) |
| smart_collars | 0 | ✅ Correct (owner only) |
| collar_activity_summaries | 0 | ✅ Correct (via collar ownership join) |
| collar_gps_locations | 0 | ✅ |
| geofences | 0 | ✅ |
| ai_conversations | 1 | ✅ |
| ai_chat_messages | 6 | ✅ |
| ai_health_scans | 2 | ✅ |
| pet_gallery_media | 0 | ✅ (owner insert/delete, public read) |
| user_notifications | 0 | ✅ |
| appointments | 0 | ✅ |
| health_records | 0 | — |
| vaccinations | 0 | — |

### Actual Column Names (critical for avoiding mapping errors)
- `smart_collars`: `battery_percentage` (NOT battery_level)
- `collar_activity_summaries`: `step_count`, `active_minutes`, `rest_minutes`, `calories_burned`, `activity_date`
- `pets`: `image_url`, `weight_kg`, `date_of_birth`, `health_status` — NO `color` column
- `profiles`: `full_name`, `avatar_url`, `email`, `phone`, `role`

### RLS Verdict
**All policies already correct — NO duplicate policies needed.**

### Edge Functions (3 deployed, ACTIVE)
- `ai-assistant` — deployed but returns hardcoded template string
- `ai-symptom-scan` — deployed but returns hardcoded template string
- `ai-report-generator` — deployed but returns hardcoded template

### Storage Buckets
Need verification — `StorageRemoteDataSource` references `pet_gallery_media` table and uses generic `bucketId` parameter.

### Secrets
- `GEMINI_API_KEY` — NOT YET SET in Supabase secrets (user must provide)
- No secrets found in Flutter client code ✅

---

## Issue Classification

| # | Issue | File | Status |
|---|-------|------|--------|
| 1 | Dashboard quick-action buttons (Collar, Rescue, Appts) show "coming soon" | `home_dashboard_screen.dart` | **MISSING** |
| 2 | Dashboard hero card shows hardcoded "Buddy"/"Luna" mock pets | `home_dashboard_screen.dart` | **MISSING** |
| 3 | Dashboard profile avatar is hardcoded `aida-public` URL | `home_dashboard_screen.dart` | **MISSING** |
| 4 | Supabase RLS on `public.pets` | All pet tables | **FIXED** (already correct) |
| 5 | "Edit Profile" button does nothing (`onPressed: () {}`) | `profile_screen.dart` | **MISSING** |
| 6 | No Settings/Logout visible from Profile tab | `profile_screen.dart` | **MISSING** |
| 7 | Pet photo upload is decorative — no `image_picker`, no upload | `add_pet_screen.dart` | **MISSING** |
| 8 | `ai-assistant` edge function returns hardcoded template | `supabase/functions/ai-assistant/index.ts` | **MISSING** (needs GEMINI_API_KEY) |
| 9 | `ai-symptom-scan` returns hardcoded template | `supabase/functions/ai-symptom-scan/index.ts` | **MISSING** (needs GEMINI_API_KEY) |
| 10 | `ai-report-generator` returns hardcoded template | `supabase/functions/ai-report-generator/index.ts` | **MISSING** (needs GEMINI_API_KEY) |
| 11 | Dashboard "Today's Summary" stats are hardcoded (4230 steps, 84% battery, fake appointment) | `home_dashboard_screen.dart` | **MISSING** |
| 12 | Dashboard timeline events are hardcoded (Sarah, puppy meetup) | `home_dashboard_screen.dart` | **MISSING** |
| 13 | Dashboard AI Insight is static hardcoded string | `home_dashboard_screen.dart` | **MISSING** |
| 14 | Profile screen shows hardcoded posts, badges, groups, events | `profile_screen.dart` | **MISSING** |
| 15 | Smart Collar activity shows hardcoded 8,420 steps, 5.2km, "Centennial Park" | `smart_collar_dashboard_screen.dart` | **MISSING** |
| 16 | Smart Collar location shows fake "Centennial Park • 2m ago" | `smart_collar_dashboard_screen.dart` | **MISSING** |
| 17 | Pet gallery is entirely hardcoded `aida-public` URLs | `pet_media_gallery_screen.dart` | **MISSING** |
| 18 | Profile avatar is hardcoded static URL | `profile_screen.dart` | **MISSING** |
| 19 | Add Pet: DOB/Weight fields missing in UI (schema supports them) | `add_pet_screen.dart` | **PARTIALLY FIXED** (model supports it, UI missing) |
| 20 | My Pets card overflow menu does nothing | `my_pets_list_screen.dart` | **MISSING** |

### Additional Issues Found
| # | Issue | Status |
|---|-------|--------|
| 21 | AI chat uses session-scoped fallback ID if `createConversation` fails | `ai_assistant_chat_screen.dart` line 97 | **MISSING** |
| 22 | Smart Collar "Collar: Active" status pill on dashboard is hardcoded | `home_dashboard_screen.dart` line 351 | **MISSING** |
| 23 | Health Passport stats/wellness score is hardcoded | `health_passport_dashboard_screen.dart` | **MISSING** |
| 24 | GEMINI_API_KEY not set in Supabase secrets — AI is blocked | Supabase Edge Functions | **BLOCKED** (external prereq) |
| 25 | Smart collar hardware not available | All collar screens | **HARDWARE REQUIRED** |

---

## Implementation Plan

### Priority Order
1. Phase B — Dashboard (quick actions, real pets, real stats, timeline)
2. Phase D — Profile (edit, logout, real avatar)
3. Phase E — Pet photo upload (image_picker → storage → DB)
4. Phase L — Smart Collar zero dummy data
5. Phase N — Pet gallery (real data + upload)
6. Phase M — Health Passport real data
7. Phase F/H/I/J — Gemini AI (BLOCKED until key provided, will wire correctly)
8. Phase Q — My Pets menu actions

---

## Architecture Notes (Do Not Duplicate)
- `petsProvider` / `PetsNotifier` — EXISTS, use it
- `currentUserProfileProvider` — EXISTS, use it
- `registeredCollarsProvider` — EXISTS, use it
- `collarActivitySummariesProvider` — EXISTS (family by collarId)
- `liveGpsLocationStreamProvider` — EXISTS (family by collarId)
- `signOutProvider` — EXISTS
- `upsertUserProfileProvider` — EXISTS
- `StorageRemoteDataSource` — EXISTS with `uploadFile`, `getPublicUrl`
- `image_picker: ^1.1.2` — already in pubspec.yaml
- `pet_gallery_media` table + RLS — EXISTS and correct
- Storage system — EXISTS and abstracted via `StorageRemoteDataSource`
