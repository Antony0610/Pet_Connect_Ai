# Database Overview

High-level PostgreSQL schema plan for **PetConnect AI**, hosted on Supabase. This document describes tables, relationships, RLS strategy, storage buckets, and the pgvector setup for RAG. It is a design reference — **not** a set of migrations. Migrations are authored separately (see `DEPLOYMENT_PLAN.md`).

The app serves **4 portals** — Pet Owner, Veterinarian, Volunteer & Rescue, Administrator — plus a shared **Community** surface. A single `profiles` table with a `role` enum drives portal access; RLS policies enforce what each role can see and do.

---

## 1. Conventions

- All tables use `uuid` primary keys (`gen_random_uuid()` default), except append-only telemetry which may use `bigint` identity for ordering.
- Every table has `created_at timestamptz default now()`. Mutable tables add `updated_at` (maintained by trigger).
- User-facing records use soft delete (`deleted_at timestamptz`) so audit trails and RAG embeddings remain valid.
- Foreign keys reference `profiles.id` (which mirrors `auth.users.id`).
- Enums are Postgres `enum` types where the value set is stable; `text` + check constraint where values evolve.

**Core enums**

| Enum | Values |
|------|--------|
| `user_role` | `owner`, `vet`, `volunteer`, `admin` |
| `pet_species` | `dog`, `cat`, `bird`, `reptile`, `small_mammal`, `other` |
| `appointment_status` | `requested`, `confirmed`, `completed`, `cancelled`, `no_show` |
| `mission_status` | `open`, `in_progress`, `resolved`, `closed` |
| `device_status` | `active`, `inactive`, `lost_mode`, `low_battery` |

---

## 2. Identity & profiles

### `profiles`
Mirror of `auth.users`, one row per user, created by a trigger on signup. Central to RLS.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | equals `auth.users.id` |
| `role` | `user_role` | portal/authorization driver |
| `full_name` | text | display name |
| `avatar_url` | text | Storage path |
| `phone` | text | contact / OTP |
| `email` | text | denormalized from auth |
| `metadata` | jsonb | role-specific extra fields |
| `created_at` / `updated_at` | timestamptz | |

Vets and clinics link through `clinic_staff`; a profile's `role` gates which portal the app routes to.

---

## 3. Pet Owner portal

### `pets`
| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `owner_id` | uuid FK → profiles | owning user |
| `name` | text | |
| `species` | `pet_species` | |
| `breed` | text | |
| `sex` | text | |
| `date_of_birth` | date | |
| `microchip_id` | text | |
| `weight_kg` | numeric | latest known weight |
| `deleted_at` | timestamptz | soft delete |

### `pet_media`
Photos/videos. Files in Storage; row holds metadata.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `pet_id` | uuid FK → pets | |
| `url` | text | Storage object path |
| `type` | text | `image` / `video` |
| `is_primary` | boolean | profile picture flag |

### `pet_documents`
Adoption papers, insurance, lab PDFs. Stored in the private `pet-documents` bucket.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `pet_id` | uuid FK → pets | |
| `title` | text | |
| `doc_type` | text | `insurance`, `adoption`, `lab`, `other` |
| `storage_path` | text | private bucket key |

### `health_records`
Timeline of health events (symptoms, notes, weight checks).

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `pet_id` | uuid FK → pets | |
| `recorded_by` | uuid FK → profiles | owner or vet |
| `record_type` | text | `symptom`, `note`, `measurement` |
| `payload` | jsonb | structured detail |
| `recorded_at` | timestamptz | |

### `vaccinations`
| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `pet_id` | uuid FK → pets | |
| `vaccine_name` | text | |
| `administered_on` | date | |
| `due_on` | date | next dose (drives reminders) |
| `administered_by` | uuid FK → profiles | vet |

### `growth_records`
Weight/height time series, powers charts and AI trend analysis.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `pet_id` | uuid FK → pets | |
| `weight_kg` | numeric | |
| `height_cm` | numeric | |
| `measured_at` | timestamptz | |

---

## 4. Veterinarian portal

### `clinics`
| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `name` | text | |
| `address` | text | |
| `location` | geography(point) | for map/discovery |
| `phone` | text | |

### `clinic_staff`
Join table linking vet profiles to clinics with a role.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `clinic_id` | uuid FK → clinics | |
| `profile_id` | uuid FK → profiles | vet/staff |
| `staff_role` | text | `vet`, `nurse`, `receptionist` |

### `appointments`
| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `pet_id` | uuid FK → pets | |
| `clinic_id` | uuid FK → clinics | |
| `vet_id` | uuid FK → profiles | assigned vet |
| `owner_id` | uuid FK → profiles | requesting owner |
| `status` | `appointment_status` | |
| `scheduled_for` | timestamptz | |
| `reason` | text | |

### `treatment_plans`
| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `pet_id` | uuid FK → pets | |
| `vet_id` | uuid FK → profiles | author |
| `appointment_id` | uuid FK → appointments | source visit |
| `title` | text | |
| `details` | jsonb | steps, schedule |
| `active` | boolean | |

### `prescriptions`
| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `treatment_plan_id` | uuid FK → treatment_plans | |
| `pet_id` | uuid FK → pets | |
| `medication` | text | |
| `dosage` | text | |
| `frequency` | text | |
| `start_date` / `end_date` | date | |

---

## 5. AI layer

### `ai_reports`
Generated health summaries / diagnostic assists (Gemini + RAG output).

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `pet_id` | uuid FK → pets | |
| `requested_by` | uuid FK → profiles | |
| `report_type` | text | `health_summary`, `symptom_triage`, `growth_analysis` |
| `content` | jsonb | structured report |
| `sources` | jsonb | RAG citation refs (embedding ids) |
| `model` | text | e.g. `gemini-pro` |

### `ai_chat_sessions`
Conversational AI threads. Messages stored as an ordered jsonb array or a child `ai_chat_messages` table.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `profile_id` | uuid FK → profiles | owner of thread |
| `pet_id` | uuid FK → pets | optional context |
| `title` | text | |
| `messages` | jsonb | ordered turns (or FK child table) |

### `embeddings` (pgvector)
Vector store for RAG. Requires the `vector` extension. Stores chunked, embedded content from health records, documents, and knowledge base.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `owner_scope` | uuid FK → profiles | tenant isolation for RLS |
| `pet_id` | uuid FK → pets | nullable; general KB has none |
| `source_table` | text | provenance, e.g. `health_records` |
| `source_id` | uuid | row that was embedded |
| `content` | text | the chunk text |
| `embedding` | `vector(768)` | Gemini/local embedding |
| `metadata` | jsonb | tags, chunk index |

An **IVFFlat** or **HNSW** index on `embedding` (cosine) powers similarity search, exposed via an RPC function `match_embeddings(query_embedding, match_count, filter)` that also respects `owner_scope` for RLS.

---

## 6. Smart Collar (IoT)

### `collar_devices`
| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `pet_id` | uuid FK → pets | |
| `owner_id` | uuid FK → profiles | |
| `hardware_id` | text | ESP32 identifier |
| `firmware_version` | text | |
| `status` | `device_status` | active / lost_mode / low_battery |
| `last_seen_at` | timestamptz | heartbeat |

### `collar_telemetry`
High-volume append-only stream (GPS, activity, battery). Streamed via Realtime.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | bigint identity PK | ordering |
| `collar_id` | uuid FK → collar_devices | |
| `location` | geography(point) | GPS fix |
| `battery_pct` | smallint | |
| `activity_level` | smallint | steps / motion score |
| `timestamp` | timestamptz | device clock |

Partition by month or use a retention job; index on `(collar_id, timestamp desc)`.

### `geofences`
Safe zones per pet; breach triggers notifications.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `pet_id` | uuid FK → pets | |
| `name` | text | |
| `area` | geography(polygon) | boundary |
| `active` | boolean | |

### `lost_mode_events`
| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `pet_id` | uuid FK → pets | |
| `collar_id` | uuid FK → collar_devices | |
| `started_at` / `ended_at` | timestamptz | |
| `last_known_location` | geography(point) | |
| `resolved` | boolean | |

---

## 7. Volunteer & Rescue portal

### `rescue_missions`
| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `created_by` | uuid FK → profiles | reporter |
| `pet_id` | uuid FK → pets | nullable (stray) |
| `title` | text | |
| `description` | text | |
| `location` | geography(point) | |
| `status` | `mission_status` | |

### `rescue_participants`
Join table: volunteers who join a mission.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `mission_id` | uuid FK → rescue_missions | |
| `profile_id` | uuid FK → profiles | volunteer |
| `participant_role` | text | `lead`, `helper`, `transport` |
| `joined_at` | timestamptz | |

---

## 8. Community

### `community_groups`
| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `name` | text | |
| `description` | text | |
| `visibility` | text | `public`, `private` |
| `created_by` | uuid FK → profiles | |

### `community_posts`
| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `author_id` | uuid FK → profiles | |
| `group_id` | uuid FK → community_groups | nullable |
| `body` | text | |
| `media` | jsonb | attached media refs |
| `deleted_at` | timestamptz | soft delete |

### `community_events`
| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `group_id` | uuid FK → community_groups | |
| `title` | text | |
| `location` | geography(point) | |
| `starts_at` / `ends_at` | timestamptz | |
| `created_by` | uuid FK → profiles | |

---

## 9. System tables

### `notifications`
Backs FCM push + in-app feed.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid PK | |
| `profile_id` | uuid FK → profiles | recipient |
| `type` | text | `appointment`, `geofence_breach`, `lost_mode`, `community` |
| `title` / `body` | text | |
| `payload` | jsonb | deep-link data |
| `read_at` | timestamptz | |

### `audit_logs`
Append-only record of sensitive actions (admin, medical edits). Used for compliance.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | bigint identity PK | |
| `actor_id` | uuid FK → profiles | who |
| `action` | text | `create`/`update`/`delete`/`login` |
| `entity_table` | text | affected table |
| `entity_id` | uuid | affected row |
| `diff` | jsonb | before/after |
| `created_at` | timestamptz | |

---

## 10. Relationship map

```
profiles ─┬─< pets ─┬─< pet_media
          │         ├─< pet_documents
          │         ├─< health_records
          │         ├─< vaccinations
          │         ├─< growth_records
          │         ├─< treatment_plans ─< prescriptions
          │         ├─< appointments >─ clinics
          │         ├─< ai_reports
          │         ├─< collar_devices ─< collar_telemetry
          │         ├─< geofences
          │         └─< lost_mode_events
          ├─< clinic_staff >─ clinics
          ├─< ai_chat_sessions
          ├─< rescue_missions ─< rescue_participants >─ profiles
          ├─< community_groups ─< community_posts / community_events
          ├─< notifications
          └─< audit_logs (actor)

embeddings ─ owner_scope → profiles ; pet_id → pets ; source_id → any source row
```

`>─` denotes a many-to-one via a join/lookup; `─<` denotes one-to-many.

---

## 11. RLS strategy per role

RLS is **on for every table**. Policies use `auth.uid()` and a helper `auth_role()` (reads `profiles.role` for the current user). General principles:

- **Deny by default**; add explicit `select`/`insert`/`update`/`delete` policies.
- Ownership is the primary axis: a row is visible if it belongs to the user, their pet, their clinic, or a mission/group they participate in.
- Admins get broad read via a `role = 'admin'` policy but writes are still audited.

| Table group | Owner | Vet | Volunteer | Admin |
|-------------|-------|-----|-----------|-------|
| `pets`, `pet_media`, `pet_documents`, health/growth/vaccination | full on own pets | read + write for pets with an active appointment/treatment relationship | none (unless linked to a mission) | read-all |
| `appointments`, `treatment_plans`, `prescriptions` | read own; create appointment requests | full for their clinic/assigned records | none | read-all |
| `clinics`, `clinic_staff` | read (discovery) | manage own clinic staff | read | full |
| `collar_devices`, `collar_telemetry`, `geofences`, `lost_mode_events` | full on own devices | read if treating pet | read `lost_mode_events` (to assist) | read-all |
| `rescue_missions`, `rescue_participants` | create/read own reports | read | full participate/manage | read-all |
| `community_*` | author-owns writes; read per group visibility | same | same | moderate/delete |
| `ai_reports`, `ai_chat_sessions`, `embeddings` | own scope only | read for treated pets | none | read-all (audited) |
| `notifications` | own only | own only | own only | own only |
| `audit_logs` | none | none | none | read-all |

**Example policy shape** (pets, owner select):

```sql
create policy "owners read own pets"
on pets for select
using (owner_id = auth.uid());
```

**Vet cross-access** is granted through a relationship check, e.g. a pet is visible to a vet if an `appointments` or `treatment_plans` row links that vet to the pet — expressed via an `exists (...)` subquery in the policy.

**Embeddings isolation:** the `match_embeddings` RPC filters on `owner_scope = auth.uid()` (plus shared knowledge-base rows where `owner_scope is null`), so RAG never leaks another user's data.

---

## 12. Storage buckets

| Bucket | Visibility | Contents | Path convention |
|--------|-----------|----------|-----------------|
| `pet-media` | public-read | pet photos/videos | `{owner_id}/{pet_id}/{uuid}.ext` |
| `pet-documents` | private (signed URLs) | insurance, lab PDFs, adoption papers | `{owner_id}/{pet_id}/{uuid}.pdf` |
| `ai-report-assets` | private | generated charts/exports | `{owner_id}/{report_id}/{uuid}.ext` |
| `avatars` | public-read | profile pictures | `{profile_id}/{uuid}.ext` |

Storage RLS policies match on the leading path segment (`owner_id` / `profile_id`) so users only write under their own prefix.

---

## 13. Extensions required

| Extension | Purpose |
|-----------|---------|
| `pgcrypto` / `gen_random_uuid` | UUID PKs |
| `vector` (pgvector) | embeddings + similarity search |
| `postgis` | `geography` columns for GPS, geofences, clinic/mission location |
| `pg_cron` (optional) | telemetry retention, reminder jobs |
