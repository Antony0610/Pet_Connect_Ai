import React, { useState, useEffect } from 'react';
import { 
  ShieldAlert, 
  Phone, 
  MessageSquare, 
  MapPin, 
  AlertTriangle, 
  CheckCircle, 
  Navigation,
  ArrowLeft,
  ChevronDown
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { EmergencyPetDossier } from '../types';

interface EmergencyPageProps {
  navigate: (route: string) => void;
}

export const EmergencyPage: React.FC<EmergencyPageProps> = ({ navigate }) => {
  const [dossier, setDossier] = useState<EmergencyPetDossier>({
    id: 'c590ba41-c8ab-4bc5-985b-e15f817e0b3c',
    name: 'Harly',
    species: 'dog',
    breed: 'German Shepard',
    gender: 'male',
    weight_kg: 35.0,
    microchip_id: 'Registered & Active on PetConnect',
    health_status: 'optimal',
    allergies: [],
    chronic_conditions: [],
    image_url: 'https://cghgslyikjqghrzhrqxz.supabase.co/storage/v1/object/public/pet-avatars/baf75c33-a5eb-46e8-ae7f-9f5670533908/temp_1788279775194/avatar_1788279775194.jpg',
    emergency_contact_name: 'Antony',
    emergency_contact_phone: '8921998733',
    owner_city: 'Meladoor, Kerala',
  });

  const [availablePets, setAvailablePets] = useState<EmergencyPetDossier[]>([]);
  const [loading, setLoading] = useState(true);
  const [locationSent, setLocationSent] = useState(false);

  useEffect(() => {
    async function loadEmergencyData() {
      try {
        setLoading(true);
        // Fetch all registered companions from sanitized public emergency view
        const { data: allPets, error } = await supabase
          .from('vw_public_emergency_pet')
          .select('*');

        if (allPets && !error && allPets.length > 0) {
          setAvailablePets(allPets);

          const urlParams = new URLSearchParams(window.location.search);
          const requestedId = urlParams.get('id');

          const match = requestedId 
            ? allPets.find(p => p.id === requestedId)
            : allPets[0];

          if (match) {
            setDossier(match);
          }
        }
      } catch (err) {
        console.warn('Error fetching emergency pet data:', err);
      } finally {
        setLoading(false);
      }
    }

    loadEmergencyData();
  }, []);

  const handleSelectPet = (pet: EmergencyPetDossier) => {
    setDossier(pet);
    window.history.pushState({}, '', `/emergency?id=${pet.id}`);
  };

  const handleShareLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const lat = pos.coords.latitude;
          const lon = pos.coords.longitude;
          const cleanPhone = (dossier.emergency_contact_phone || '8921998733').replace(/[^0-9]/g, '').slice(-10);
          const mapLink = `https://maps.google.com/?q=${lat},${lon}`;
          const msg = encodeURIComponent(`FOUND YOUR PET: I scanned ${dossier.name}'s PetConnect collar tag! Here is my current GPS location: ${mapLink}`);
          window.open(`https://wa.me/91${cleanPhone}?text=${msg}`, '_blank');
          setLocationSent(true);
        },
        () => {
          alert('Please call or message the guardian directly.');
        }
      );
    }
  };

  const cleanDigits = (dossier.emergency_contact_phone || '8921998733').replace(/[^0-9]/g, '').slice(-10);

  return (
    <div style={{ maxWidth: '720px', margin: '0 auto', padding: '32px 20px 80px' }}>
      {/* Return button */}
      <button
        onClick={() => navigate('home')}
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '6px',
          color: 'var(--text-secondary)',
          fontSize: '0.86rem',
          fontWeight: 600,
          marginBottom: '20px',
        }}
      >
        <ArrowLeft size={15} />
        <span>Return to Platform</span>
      </button>

      {/* Companion Switcher (When multiple registered pets exist) */}
      {availablePets.length > 1 && (
        <div style={{ marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Registered Companion:</span>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
            {availablePets.map((p) => (
              <button
                key={p.id}
                onClick={() => handleSelectPet(p)}
                style={{
                  padding: '4px 10px',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: '0.78rem',
                  fontFamily: 'var(--font-mono)',
                  fontWeight: dossier.id === p.id ? 700 : 500,
                  backgroundColor: dossier.id === p.id ? 'var(--btn-primary-bg)' : 'var(--bg-surface)',
                  color: dossier.id === p.id ? 'var(--btn-primary-text)' : 'var(--text-secondary)',
                  border: '1px solid var(--border-subtle)',
                }}
              >
                {p.name} ({p.species})
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Emergency Active Banner - Solid Minimalist */}
      <div 
        style={{
          padding: '14px 18px',
          borderRadius: 'var(--radius-md)',
          backgroundColor: 'var(--bg-surface-elevated)',
          borderLeft: '4px solid var(--danger)',
          borderTop: '1px solid var(--border-subtle)',
          borderRight: '1px solid var(--border-subtle)',
          borderBottom: '1px solid var(--border-subtle)',
          marginBottom: '20px',
          display: 'flex',
          alignItems: 'center',
          gap: '12px',
        }}
      >
        <AlertTriangle size={18} color="var(--danger)" style={{ flexShrink: 0 }} />
        <div>
          <div style={{ fontWeight: 800, fontSize: '0.92rem', color: 'var(--text-primary)' }}>
            EMERGENCY HEALTH PASS ACTIVE
          </div>
          <div style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
            If you have found this pet, please immediately call or message the verified caregiver below.
          </div>
        </div>
      </div>

      {/* Main Dossier Card - Solid Minimalist */}
      <div 
        className="flat-card"
        style={{
          padding: '28px',
          marginBottom: '20px',
        }}
      >
        {/* Profile Row */}
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '20px', alignItems: 'center', marginBottom: '24px' }}>
          <img 
            src={dossier.image_url || 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=400'} 
            alt={dossier.name}
            style={{
              width: '90px',
              height: '90px',
              borderRadius: 'var(--radius-md)',
              objectFit: 'cover',
              border: '1px solid var(--border-medium)',
              backgroundColor: 'var(--bg-inset)',
            }}
            onError={(e) => {
              (e.currentTarget as HTMLImageElement).src = 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=400';
            }}
          />

          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
              <h1 style={{ fontSize: '1.8rem', fontWeight: 900 }}>{dossier.name}</h1>
              <span className="pill-badge success">
                {dossier.species.toUpperCase()}
              </span>
            </div>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.92rem', marginBottom: '6px' }}>
              {dossier.breed || 'Companion'} • {dossier.gender || 'Companion'} {dossier.weight_kg ? `• ${dossier.weight_kg} kg` : ''}
            </p>
            <div style={{ display: 'flex', alignItems: 'center', gap: '5px', fontSize: '0.82rem', color: 'var(--text-muted)' }}>
              <MapPin size={13} color="var(--primary)" />
              <span>Registered City: {dossier.owner_city || 'Kerala, India'}</span>
            </div>
          </div>
        </div>

        {/* Clinical Grid */}
        <div 
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
            gap: '12px',
            marginBottom: '24px',
          }}
        >
          <div style={{ padding: '12px 14px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--bg-inset)', border: '1px solid var(--border-subtle)' }}>
            <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)', marginBottom: '2px' }}>MICROCHIP STATUS</div>
            <div style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: '0.86rem', color: 'var(--text-primary)' }}>
              {dossier.microchip_id || 'Registered on PetConnect'}
            </div>
          </div>

          <div style={{ padding: '12px 14px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--bg-inset)', border: '1px solid var(--border-subtle)' }}>
            <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)', marginBottom: '2px' }}>HEALTH RECORD</div>
            <div style={{ fontWeight: 700, fontSize: '0.86rem', color: 'var(--primary)' }}>
              Optimal
            </div>
          </div>

          <div style={{ padding: '12px 14px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--bg-inset)', border: '1px solid var(--border-subtle)' }}>
            <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)', marginBottom: '2px' }}>KNOWN ALLERGIES</div>
            <div style={{ fontWeight: 600, fontSize: '0.86rem', color: dossier.allergies?.length ? 'var(--danger)' : 'var(--text-secondary)' }}>
              {dossier.allergies?.length ? dossier.allergies.join(', ') : 'None Reported (NKDA)'}
            </div>
          </div>
        </div>

        {/* Guardian Contact Info - Flat Inset */}
        <div 
          style={{
            padding: '16px 20px',
            borderRadius: 'var(--radius-md)',
            backgroundColor: 'var(--bg-inset)',
            border: '1px solid var(--border-subtle)',
            marginBottom: '20px',
          }}
        >
          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 700, letterSpacing: '0.04em', textTransform: 'uppercase', marginBottom: '4px' }}>
            VERIFIED GUARDIAN CONTACT
          </div>
          <div style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--text-primary)' }}>
            {dossier.emergency_contact_name || 'Pet Guardian'}
          </div>
          <div style={{ fontFamily: 'var(--font-mono)', color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            +91 {cleanDigits} • {dossier.owner_city || 'Kerala'}
          </div>
        </div>

        {/* Direct Action Buttons - Flat Minimalist */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '10px' }}>
          <a
            href={`tel:+91${cleanDigits}`}
            className="btn-primary"
            style={{ padding: '14px', fontSize: '0.92rem' }}
          >
            <Phone size={16} />
            <span>Call Guardian (+91 {cleanDigits})</span>
          </a>

          <a
            href={`https://wa.me/91${cleanDigits}?text=${encodeURIComponent(`Hello, I scanned ${dossier.name}'s emergency collar tag on PetConnect AI. I have your companion with me.`)}`}
            target="_blank"
            rel="noopener noreferrer"
            className="btn-secondary"
            style={{ padding: '14px', fontSize: '0.92rem' }}
          >
            <MessageSquare size={16} />
            <span>WhatsApp Message</span>
          </a>
        </div>

        {/* Location Dispatch */}
        <div style={{ marginTop: '12px' }}>
          <button
            onClick={handleShareLocation}
            className="btn-secondary"
            style={{ width: '100%', padding: '11px', fontSize: '0.86rem' }}
          >
            <Navigation size={15} />
            <span>{locationSent ? 'Location Dispatched to WhatsApp' : 'Dispatch My Location via WhatsApp'}</span>
          </button>
        </div>
      </div>
    </div>
  );
};
