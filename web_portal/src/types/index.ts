export interface Pet {
  id: string;
  name: string;
  species: string;
  breed?: string;
  gender?: string;
  date_of_birth?: string;
  weight_kg?: number;
  microchip_id?: string;
  health_status?: string;
  allergies?: string[];
  chronic_conditions?: string[];
  image_url?: string;
  created_at?: string;
}

export interface EmergencyPetDossier {
  id: string;
  name: string;
  species: string;
  breed: string;
  gender: string;
  weight_kg?: number;
  microchip_id: string;
  health_status: string;
  allergies: string[];
  chronic_conditions: string[];
  image_url?: string;
  emergency_contact_name: string;
  emergency_contact_phone: string;
  owner_city: string;
}

export interface MissingPetReport {
  id: string;
  pet_name: string;
  species: string;
  breed: string;
  last_seen_location: string;
  last_seen_time: string;
  reward_amount?: string;
  contact_phone: string;
  distinctive_marks?: string;
  image_url?: string;
  status: 'ACTIVE' | 'REUNITED' | 'SIGHTING_REPORTED';
}

export interface AdoptionProfile {
  id: string;
  name: string;
  species: 'Dog' | 'Cat' | 'Other';
  breed: string;
  age: string;
  gender: 'Male' | 'Female';
  shelter_name: string;
  location: string;
  image_url: string;
  personality: string[];
  vaccinated: boolean;
  neutered: boolean;
  microchipped: boolean;
  story: string;
}
