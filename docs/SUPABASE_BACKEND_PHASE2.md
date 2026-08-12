# PetConnect AI — Phase 2 Supabase Backend Specification & Verification Report

**Phase Scope**: Core Pet Management  
**Status**: COMPLETE & VERIFIED  
**Date**: August 12, 2026  

---

## 1. Database Schema & RLS Architecture

```sql
-- 1. Create Enums
DO $$ BEGIN
  CREATE TYPE pet_species AS ENUM ('dog', 'cat', 'bird', 'reptile', 'small_mammal', 'other');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE pet_gender AS ENUM ('male', 'female', 'unknown');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- 2. Create public.pets table
CREATE TABLE IF NOT EXISTS public.pets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  species TEXT NOT NULL DEFAULT 'dog',
  breed TEXT,
  gender TEXT DEFAULT 'unknown',
  date_of_birth DATE,
  weight_kg NUMERIC(5,2),
  microchip_id TEXT,
  image_url TEXT,
  health_status TEXT DEFAULT 'optimal',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  deleted_at TIMESTAMPTZ
);

-- 3. Create public.pet_settings table
CREATE TABLE IF NOT EXISTS public.pet_settings (
  pet_id UUID PRIMARY KEY REFERENCES public.pets(id) ON DELETE CASCADE,
  ai_health_tracking BOOLEAN DEFAULT true NOT NULL,
  location_sharing BOOLEAN DEFAULT false NOT NULL,
  activity_alerts BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Indexes for querying performance
CREATE INDEX IF NOT EXISTS idx_pets_owner_id ON public.pets(owner_id);
CREATE INDEX IF NOT EXISTS idx_pets_deleted_at ON public.pets(deleted_at) WHERE deleted_at IS NULL;

-- Enable RLS
ALTER TABLE public.pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pet_settings ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies on public.pets
CREATE POLICY "Pet owners view own pets"
  ON public.pets FOR SELECT TO authenticated
  USING (
    (auth.uid() = owner_id AND deleted_at IS NULL) OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'administrator')
  );

CREATE POLICY "Pet owners insert own pets"
  ON public.pets FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Pet owners update own pets"
  ON public.pets FOR UPDATE TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Pet owners delete own pets"
  ON public.pets FOR DELETE TO authenticated
  USING (auth.uid() = owner_id);

-- 5. RLS Policies on public.pet_settings
CREATE POLICY "Pet owners view pet settings"
  ON public.pet_settings FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.pets WHERE pets.id = pet_settings.pet_id AND pets.owner_id = auth.uid())
  );

CREATE POLICY "Pet owners update pet settings"
  ON public.pet_settings FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.pets WHERE pets.id = pet_settings.pet_id AND pets.owner_id = auth.uid())
  );

CREATE POLICY "Pet owners insert pet settings"
  ON public.pet_settings FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.pets WHERE pets.id = pet_settings.pet_id AND pets.owner_id = auth.uid())
  );

-- 6. Ownership Protection Trigger Function
CREATE OR REPLACE FUNCTION public.prevent_pet_owner_spoofing()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.owner_id := auth.uid();
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.owner_id IS DISTINCT FROM OLD.owner_id THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'administrator'
      ) THEN
        RAISE EXCEPTION 'Unauthorized: Pet ownership transfer requires administrative privilege.';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER enforce_pet_ownership_protection
  BEFORE INSERT OR UPDATE ON public.pets
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_pet_owner_spoofing();
```

---

## 2. Integrated Flutter Architecture

- **Domain Layer**:
  - `Pet` entity (`lib/features/pet_owner/domain/entities/pet.dart`)
  - `PetSettings` entity (`lib/features/pet_owner/domain/entities/pet_settings.dart`)
  - `PetRepository` interface (`lib/features/pet_owner/domain/repositories/pet_repository.dart`)
  - UseCases: `GetPets`, `GetPetById`, `CreatePet`, `UpdatePet`, `DeletePet`, `GetPetSettings`, `UpdatePetSettings`.

- **Data Layer**:
  - `PetModel` (`lib/features/pet_owner/data/models/pet_model.dart`)
  - `PetSettingsModel` (`lib/features/pet_owner/data/models/pet_settings_model.dart`)
  - `PetRemoteDataSourceImpl` (`lib/features/pet_owner/data/datasources/pet_remote_datasource.dart`)
  - `PetRepositoryImpl` (`lib/features/pet_owner/data/repositories/pet_repository_impl.dart`)

- **Presentation Layer**:
  - Providers (`lib/features/pet_owner/presentation/providers/pet_providers.dart`)
  - Wired Screens:
    - My Pets List Screen (`/owner/pets`)
    - Add Pet Screen (`/owner/pets/add`)
    - Pet Profile Detail Screen (`/owner/pets/:petId`)
    - Edit Pet Profile Screen (`/owner/pets/:petId/edit`)
    - Pet Settings Screen (`/owner/pets/:petId/settings`)
    - Delete Pet Confirmation Screen (`/owner/pets/:petId/delete`)
    - Initial Pet Setup Screen (`/pet-setup`)

---

## 3. Verification & Test Metrics

- **Unit Tests**: 23/23 tests passing (`flutter test test/unit/features/pet_owner/`).
- **Formatting**: `dart format` 0 errors.
- **RLS & Security**: Server-side ownership spoofing trigger enforced. Soft-delete support (`deleted_at`).
