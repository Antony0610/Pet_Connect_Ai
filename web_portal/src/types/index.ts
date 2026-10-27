export interface AdoptionListing {
  id: string;
  pet_id?: string | null;
  name: string;
  breed: string;
  species: string;
  age?: string;
  gender?: string;
  adoption_fee?: string;
  location?: string;
  contact_phone?: string;
  status: string;
  image_url?: string;
  images?: string[] | null;
  description?: string;
  created_at?: string;
}

export interface EmergencyPetDossier {
  id: string;
  name: string;
  species: string;
  breed: string;
  gender: string;
  weight_kg?: number | string | null;
  microchip_id: string;
  health_status: string;
  allergies: string[];
  chronic_conditions: string[];
  image_url?: string;
  emergency_contact_name: string;
  emergency_contact_phone: string;
  owner_city: string;
}

export interface VaccinationRecord {
  id: string;
  pet_id: string;
  pet_name?: string;
  vaccine_name: string;
  batch_number?: string | null;
  administered_date?: string;
  next_due_date?: string;
  administered_by?: string | null;
  certificate_url?: string | null;
  notes?: string | null;
  pets?: {
    name?: string;
    species?: string;
    breed?: string;
    image_url?: string;
    profiles?: {
      full_name?: string;
      city?: string;
    };
  };
}

export interface LostPetAlert {
  id: string;
  pet_id?: string;
  owner_id?: string;
  last_seen_location?: string;
  last_seen_time?: string;
  reward_amount?: string;
  description?: string;
  alert_status?: string;
  contact_phone?: string;
  created_at?: string;
  pets?: {
    name?: string;
    species?: string;
    breed?: string;
    image_url?: string;
    profiles?: {
      full_name?: string;
      phone?: string;
      city?: string;
    };
  };
}
