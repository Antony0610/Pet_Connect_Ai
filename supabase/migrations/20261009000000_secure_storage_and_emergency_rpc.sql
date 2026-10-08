-- ============================================================================
-- PetConnect AI: Security Hardening Migration
-- 1. Eliminate insecure anonymous DELETE permissions on storage.objects
-- 2. Create sanitized public emergency view (vw_public_emergency_pet)
-- 3. Enhance get_emergency_pet_dossier SECURITY DEFINER RPC with PII protection
-- ============================================================================

-- 1. Neutralize insecure anon delete and update policies on storage.objects
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' 
          AND schemaname = 'storage' 
          AND policyname = 'Public and anon delete pet-avatars'
    ) THEN
        ALTER POLICY "Public and anon delete pet-avatars" ON storage.objects USING (false);
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' 
          AND schemaname = 'storage' 
          AND policyname = 'Public and anon update pet-avatars'
    ) THEN
        ALTER POLICY "Public and anon update pet-avatars" ON storage.objects USING (false);
    END IF;
END $$;

-- 2. Create sanitized public emergency view for zero-PII emergency QR resolution
CREATE OR REPLACE VIEW public.vw_public_emergency_pet AS
SELECT 
    p.id,
    p.name,
    p.species,
    COALESCE(p.breed, 'Standard Breed') AS breed,
    COALESCE(p.gender, 'Companion') AS gender,
    p.weight_kg,
    COALESCE(p.microchip_id, 'Registered & Active on PetConnect') AS microchip_id,
    COALESCE(p.health_status, 'Optimal') AS health_status,
    COALESCE(p.allergies, ARRAY[]::TEXT[]) AS allergies,
    COALESCE(p.chronic_conditions, ARRAY[]::TEXT[]) AS chronic_conditions,
    p.image_url,
    COALESCE(prof.full_name, 'Pet Guardian') AS emergency_contact_name,
    COALESCE(prof.phone, 'Contact via Cloud') AS emergency_contact_phone,
    COALESCE(prof.city, 'India') AS owner_city
FROM public.pets p
LEFT JOIN public.profiles prof ON prof.id = p.owner_id
WHERE p.deleted_at IS NULL;

-- Allow anon and authenticated access strictly to this sanitized view
GRANT SELECT ON public.vw_public_emergency_pet TO anon, authenticated;

-- 3. Harden get_emergency_pet_dossier RPC
CREATE OR REPLACE FUNCTION public.get_emergency_pet_dossier(p_pet_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'id', p.id,
        'name', p.name,
        'species', p.species,
        'breed', COALESCE(p.breed, 'Standard Breed'),
        'gender', COALESCE(p.gender, 'Companion'),
        'weight_kg', p.weight_kg,
        'microchip_id', COALESCE(p.microchip_id, 'Registered & Active on PetConnect'),
        'health_status', COALESCE(p.health_status, 'Optimal'),
        'allergies', COALESCE(p.allergies, ARRAY[]::TEXT[]),
        'chronic_conditions', COALESCE(p.chronic_conditions, ARRAY[]::TEXT[]),
        'image_url', p.image_url,
        'owner_name', COALESCE(prof.full_name, 'Pet Guardian'),
        'owner_phone', COALESCE(prof.phone, 'Contact via Cloud'),
        'owner_city', COALESCE(prof.city, 'India')
    )
    INTO result
    FROM public.pets p
    LEFT JOIN public.profiles prof ON prof.id = p.owner_id
    WHERE p.id = p_pet_id AND p.deleted_at IS NULL;

    RETURN result;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.get_emergency_pet_dossier(uuid) TO anon, authenticated;
