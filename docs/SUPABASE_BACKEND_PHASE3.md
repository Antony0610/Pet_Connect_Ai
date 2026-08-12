# Supabase Backend — Phase 3: Pet Health Passport & Medical Data

This document contains the backend DDL schema, security configuration, Row-Level Security (RLS) policies, Clean Architecture mapping, and live deployment verification for **Phase 3 — Pet Health Passport & Medical Data**.

---

## Live Supabase Project Verification

- **Project Reference**: `cghgslyikjqghrzhrqxz`
- **Project URL**: `https://cghgslyikjqghrzhrqxz.supabase.co`
- **Region**: `ap-south-1`
- **Deployment Status**: **DEPLOYED & LIVE VERIFIED**

---

## Database Tables & Schema DDL

### 1. `public.health_records`
Stores medical history, clinical diagnoses, surgeries, emergency records, and treatments.

```sql
CREATE TABLE IF NOT EXISTS public.health_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  record_date DATE NOT NULL DEFAULT CURRENT_DATE,
  category TEXT NOT NULL DEFAULT 'General',
  title TEXT NOT NULL,
  notes TEXT,
  diagnosis TEXT,
  treatment TEXT,
  veterinarian_name TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_health_records_pet_id ON public.health_records(pet_id);
```

---

### 2. `public.vaccinations`
Stores vaccination history, due dates, batch numbers, and certificate URLs.

```sql
CREATE TABLE IF NOT EXISTS public.vaccinations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  vaccine_name TEXT NOT NULL,
  administered_date DATE NOT NULL,
  next_due_date DATE,
  administered_by TEXT,
  batch_number TEXT,
  certificate_url TEXT,
  notes TEXT,
  is_completed BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_vaccinations_pet_id ON public.vaccinations(pet_id);
```

---

### 3. `public.health_timeline_events`
Stores chronologically ordered health timeline events across Medical, AI Insights, Growth, and Vaccines categories.

```sql
CREATE TABLE IF NOT EXISTS public.health_timeline_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  event_date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  category TEXT NOT NULL DEFAULT 'Medical',
  title TEXT NOT NULL,
  description TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_health_timeline_events_pet_id ON public.health_timeline_events(pet_id);
```

---

### 4. `public.pet_weight_logs`
Stores historical pet weight entries for growth curves and analytics.

```sql
CREATE TABLE IF NOT EXISTS public.pet_weight_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  weight_kg NUMERIC(5,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_pet_weight_logs_pet_id ON public.pet_weight_logs(pet_id);
```

---

### 5. `public.treatment_plans`
Stores active recovery and treatment plans (post-surgery rehab, medication schedules, physical therapy).

```sql
CREATE TABLE IF NOT EXISTS public.treatment_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Rehab',
  target_date DATE,
  progress_percent INT DEFAULT 0 NOT NULL,
  status TEXT DEFAULT 'active' NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_treatment_plans_pet_id ON public.treatment_plans(pet_id);
```

---

## Row-Level Security (RLS) Policies

Every Phase 3 table has Row-Level Security enabled with strict owner isolation checked via `pets.owner_id = auth.uid()`:

1. `health_records`:
   - `Pet owners view own health records`: `SELECT` WHERE `EXISTS (SELECT 1 FROM public.pets WHERE pets.id = health_records.pet_id AND pets.owner_id = auth.uid())`
   - `Pet owners insert own health records`: `INSERT` WITH CHECK `EXISTS (...)`
   - `Pet owners update own health records`: `UPDATE` USING `EXISTS (...)` WITH CHECK `EXISTS (...)`
   - `Pet owners delete own health records`: `DELETE` USING `EXISTS (...)`

2. `vaccinations`:
   - `Pet owners view own vaccinations`: `SELECT` WHERE `EXISTS (...)`
   - `Pet owners insert own vaccinations`: `INSERT` WITH CHECK `EXISTS (...)`
   - `Pet owners update own vaccinations`: `UPDATE` USING `EXISTS (...)`
   - `Pet owners delete own vaccinations`: `DELETE` USING `EXISTS (...)`

3. `health_timeline_events`:
   - `Pet owners view own health timeline events`: `SELECT` WHERE `EXISTS (...)`
   - `Pet owners insert own health timeline events`: `INSERT` WITH CHECK `EXISTS (...)`

4. `pet_weight_logs`:
   - `Pet owners view own pet weight logs`: `SELECT` WHERE `EXISTS (...)`
   - `Pet owners insert own pet weight logs`: `INSERT` WITH CHECK `EXISTS (...)`

5. `treatment_plans`:
   - `Pet owners view own treatment plans`: `SELECT` WHERE `EXISTS (...)`
   - `Pet owners insert own treatment plans`: `INSERT` WITH CHECK `EXISTS (...)`
   - `Pet owners update own treatment plans`: `UPDATE` USING `EXISTS (...)`

---

## Flutter Clean Architecture Integration

### Domain Layer (`lib/features/pet_owner/domain/`)
- Entities: `HealthRecord`, `Vaccination`, `HealthTimelineEvent`, `PetWeightLog`, `TreatmentPlan`
- Repository Contract: `HealthRepository`
- UseCases: `GetHealthRecords`, `CreateHealthRecord`, `GetVaccinations`, `CreateVaccination`, `GetHealthTimelineEvents`, `GetPetWeightLogs`, `AddPetWeightLog`, `GetTreatmentPlans`

### Data Layer (`lib/features/pet_owner/data/`)
- DTO Models: `HealthRecordModel`, `VaccinationModel`, `HealthTimelineEventModel`, `PetWeightLogModel`, `TreatmentPlanModel`
- Remote Data Source: `HealthRemoteDataSourceImpl` (interacting via Supabase Client)
- Repository Implementation: `HealthRepositoryImpl`

### Presentation & Riverpod State (`lib/features/pet_owner/presentation/`)
- `healthRemoteDataSourceProvider`
- `healthRepositoryProvider`
- `healthRecordsProvider(petId)`
- `vaccinationsProvider(petId)`
- `healthTimelineEventsProvider(petId)`
- `petWeightLogsProvider(petId)`
- `treatmentPlansProvider(petId)`

---

## Targeted Unit Tests Suite

All 18 unit tests passed cleanly:
- `test/unit/features/pet_owner/data/models/health_models_test.dart` (5 tests)
- `test/unit/features/pet_owner/data/repositories/health_repository_impl_test.dart` (6 tests)
- `test/unit/features/pet_owner/domain/usecases/health_usecases_test.dart` (5 tests)
- `test/unit/features/pet_owner/presentation/providers/health_providers_test.dart` (2 tests)
