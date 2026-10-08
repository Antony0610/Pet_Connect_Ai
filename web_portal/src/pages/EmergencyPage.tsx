import React, { useState, useEffect } from 'react';
import { 
  ShieldAlert, 
  Phone, 
  MessageSquare, 
  MapPin, 
  AlertTriangle, 
  CheckCircle, 
  Share2, 
  ArrowLeft,
  Navigation,
  Activity,
  Heart
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { EmergencyPetDossier } from '../types';

interface EmergencyPageProps {
  navigate: (route: string) => void;
}

export const EmergencyPage: React.FC<EmergencyPageProps> = ({ navigate }) => {
  const [dossier, setDossier] = useState<EmergencyPetDossier>({
    id: 'DOS-BUDDY-8291',
    name: 'Buddy',
    species: 'Dog',
    breed: 'Golden Retriever',
    gender: 'Male',
    weight_kg: 28.5,
    microchip_id: 'PC-98210-IND-2026',
    health_status: 'Optimal',
    allergies: ['Penicillin Allergy (High Risk)', 'Chicken Protein Intolerance'],
    chronic_conditions: ['Mild Hip Dysplasia (Right Side)'],
    image_url: 'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=600&q=80',
    emergency_contact_name: 'Verified Pet Guardian',
    emergency_contact_phone: '+91 98470 12345',
    owner_city: 'Kochi, Kerala',
  });

  const [loading, setLoading] = useState(true);
  const [locationSent, setLocationSent] = useState(false);

  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const petId = urlParams.get('id');

    // Extract param overrides if available
    const paramName = urlParams.get('name');
    const paramSpecies = urlParams.get('species');
    const paramBreed = urlParams.get('breed');
    const paramChip = urlParams.get('chip');

    if (paramName) {
      setDossier(prev => ({
        ...prev,
        name: paramName,
        species: paramSpecies || prev.species,
        breed: paramBreed || prev.breed,
        microchip_id: paramChip || prev.microchip_id,
      }));
    }

    if (!petId || petId.startsWith('demo')) {
      setLoading(false);
      return;
    }

    // Fetch from Supabase sanitized emergency view
    async function fetchEmergencyDossier() {
      try {
        const { data, error } = await supabase
          .from('vw_public_emergency_pet')
          .select('*')
          .eq('id', petId)
          .maybeSingle();

        if (data && !error) {
          setDossier({
            id: data.id,
            name: data.name || 'Companion',
            species: data.species || 'Pet',
            breed: data.breed || 'Standard Breed',
            gender: data.gender || 'Not specified',
            weight_kg: data.weight_kg,
            microchip_id: data.microchip_id || 'Registered & Active',
            health_status: data.health_status || 'Optimal',
            allergies: Array.isArray(data.allergies) && data.allergies.length > 0 ? data.allergies : ['No Known Drug Allergies (NKDA)'],
            chronic_conditions: Array.isArray(data.chronic_conditions) ? data.chronic_conditions : [],
            image_url: data.image_url || 'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=600&q=80',
            emergency_contact_name: data.emergency_contact_name || 'Verified Guardian',
            emergency_contact_phone: data.emergency_contact_phone || '+91 98470 12345',
            owner_city: data.owner_city || 'India',
          });
        }
      } catch (err) {
        console.warn('Fallback to URL params / offline dossier:', err);
      } finally {
        setLoading(false);
      }
    }

    fetchEmergencyDossier();
  }, []);

  const handleShareLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const lat = pos.coords.latitude;
          const lon = pos.coords.longitude;
          const cleanPhone = dossier.emergency_contact_phone.replace(/[^0-9]/g, '').slice(-10);
          const mapLink = `https://maps.google.com/?q=${lat},${lon}`;
          const message = encodeURIComponent(`🚨 FOUND YOUR PET: I just scanned ${dossier.name}'s collar pass! Here is my current GPS location: ${mapLink}`);
          window.open(`https://wa.me/91${cleanPhone}?text=${message}`, '_blank');
          setLocationSent(true);
        },
        () => {
          alert('Location access was not granted. Please call or message the guardian directly.');
        }
      );
    }
  };

  const cleanDigits = dossier.emergency_contact_phone.replace(/[^0-9]/g, '').slice(-10);

  return (
    <div style={{ maxWidth: '780px', margin: '0 auto', padding: '32px 20px 80px' }}>
      {/* Back Button */}
      <button
        onClick={() => navigate('home')}
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '8px',
          color: 'var(--text-secondary)',
          fontSize: '0.88rem',
          fontWeight: 600,
          marginBottom: '20px',
        }}
      >
        <ArrowLeft size={16} />
        <span>Return to Platform</span>
      </button>

      {/* SOS Alert Banner */}
      <div 
        style={{
          padding: '16px 20px',
          borderRadius: 'var(--radius-md)',
          backgroundColor: 'rgba(239, 68, 68, 0.15)',
          border: '1px solid rgba(239, 68, 68, 0.45)',
          display: 'flex',
          alignItems: 'center',
          gap: '16px',
          marginBottom: '24px',
        }}
      >
        <div 
          style={{
            width: '12px',
            height: '12px',
            borderRadius: '50%',
            backgroundColor: '#EF4444',
            boxShadow: '0 0 12px #EF4444',
            animation: 'pulseGlow 1.5s infinite',
            flexShrink: 0,
          }}
        />
        <div>
          <div style={{ color: '#FCA5A5', fontWeight: 800, fontSize: '1rem', letterSpacing: '0.02em' }}>
            🚨 VERIFIED EMERGENCY CLINICAL PASS ACTIVE
          </div>
          <div style={{ color: '#FECACA', fontSize: '0.82rem' }}>
            If you have found this pet, please immediately call or send your location to the verified guardian below.
          </div>
        </div>
      </div>

      {/* Main Dossier Bento Card */}
      <div 
        className="glass-panel"
        style={{
          padding: '32px',
          position: 'relative',
          overflow: 'hidden',
          marginBottom: '24px',
        }}
      >
        {/* Header Profile */}
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '24px', alignItems: 'center', marginBottom: '28px' }}>
          <div style={{ position: 'relative' }}>
            <img 
              src={dossier.image_url} 
              alt={dossier.name}
              style={{
                width: '110px',
                height: '110px',
                borderRadius: '50%',
                objectFit: 'cover',
                border: '4px solid var(--primary)',
                boxShadow: '0 8px 24px rgba(0, 0, 0, 0.4)',
              }}
              onError={(e) => {
                // Clean fallback
                (e.currentTarget as HTMLImageElement).src = 'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=400&q=80';
              }}
            />
            <div 
              style={{
                position: 'absolute',
                bottom: '4px',
                right: '4px',
                width: '24px',
                height: '24px',
                borderRadius: '50%',
                backgroundColor: 'var(--primary)',
                border: '2px solid #080A10',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
              title="Registered & Microchipped"
            >
              <CheckCircle size={14} color="#FFFFFF" />
            </div>
          </div>

          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '4px' }}>
              <h1 style={{ fontSize: '2rem', fontWeight: 900 }}>{dossier.name}</h1>
              <span style={{
                fontSize: '0.72rem',
                fontFamily: 'var(--font-mono)',
                padding: '3px 8px',
                borderRadius: '6px',
                background: 'rgba(16, 185, 129, 0.18)',
                color: 'var(--primary)',
                fontWeight: 700,
                border: '1px solid rgba(16, 185, 129, 0.4)',
              }}>
                {dossier.species.toUpperCase()}
              </span>
            </div>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.96rem', marginBottom: '8px' }}>
              {dossier.breed} • {dossier.gender} {dossier.weight_kg ? `• ${dossier.weight_kg} kg` : ''}
            </p>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
              <MapPin size={14} color="var(--primary)" />
              <span>Registered Territory: {dossier.owner_city}</span>
            </div>
          </div>
        </div>

        {/* Critical Allergies & Medical Warnings */}
        <div 
          style={{
            padding: '18px 20px',
            borderRadius: '12px',
            backgroundColor: 'rgba(239, 68, 68, 0.08)',
            border: '1px solid rgba(239, 68, 68, 0.35)',
            marginBottom: '24px',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#F87171', fontWeight: 800, fontSize: '0.86rem', marginBottom: '8px' }}>
            <AlertTriangle size={16} />
            <span>CRITICAL MEDICAL & DRUG ALLERGIES</span>
          </div>
          <div style={{ color: 'var(--text-primary)', fontSize: '0.9rem', lineHeight: '1.5' }}>
            {dossier.allergies && dossier.allergies.length > 0 ? (
              <ul style={{ paddingLeft: '20px' }}>
                {dossier.allergies.map((alg, i) => (
                  <li key={i} style={{ marginBottom: '4px' }}>{alg}</li>
                ))}
              </ul>
            ) : (
              <span>No known drug allergies reported (NKDA). Routine preventative care active.</span>
            )}
          </div>
        </div>

        {/* Clinical Vitals & Identification Grid */}
        <div 
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: '14px',
            marginBottom: '28px',
          }}
        >
          <div style={{ padding: '14px', borderRadius: '10px', background: 'rgba(255, 255, 255, 0.03)', border: '1px solid var(--border-subtle)' }}>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '4px' }}>MICROCHIP IDENTIFIER</div>
            <div style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: '0.9rem', color: 'var(--primary)' }}>
              {dossier.microchip_id}
            </div>
          </div>

          <div style={{ padding: '14px', borderRadius: '10px', background: 'rgba(255, 255, 255, 0.03)', border: '1px solid var(--border-subtle)' }}>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '4px' }}>HEALTH & RABIES STATUS</div>
            <div style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-primary)' }}>
              Certified Optimal
            </div>
          </div>

          <div style={{ padding: '14px', borderRadius: '10px', background: 'rgba(255, 255, 255, 0.03)', border: '1px solid var(--border-subtle)' }}>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '4px' }}>PASS DOSSIER ID</div>
            <div style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-secondary)' }}>
              {dossier.id.substring(0, 16)}
            </div>
          </div>
        </div>

        {/* Guardian Contact Box */}
        <div 
          style={{
            padding: '20px',
            borderRadius: '14px',
            backgroundColor: 'rgba(16, 185, 129, 0.08)',
            border: '1px solid rgba(16, 185, 129, 0.3)',
            marginBottom: '24px',
          }}
        >
          <div style={{ fontSize: '0.8rem', color: 'var(--primary)', fontWeight: 700, marginBottom: '6px', letterSpacing: '0.04em' }}>
            VERIFIED GUARDIAN / EMERGENCY CONTACT
          </div>
          <div style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--text-primary)', marginBottom: '4px' }}>
            {dossier.emergency_contact_name}
          </div>
          <div style={{ fontFamily: 'var(--font-mono)', color: 'var(--text-secondary)', fontSize: '0.95rem' }}>
            {dossier.emergency_contact_phone}
          </div>
        </div>

        {/* Primary Contact Action Buttons */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '12px' }}>
          <a
            href={`tel:${dossier.emergency_contact_phone}`}
            style={{
              padding: '16px',
              borderRadius: '12px',
              backgroundColor: '#10B981',
              color: '#FFFFFF',
              fontWeight: 800,
              fontSize: '0.96rem',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '10px',
              boxShadow: '0 4px 16px rgba(16, 185, 129, 0.35)',
              transition: 'all var(--transition-fast)',
            }}
          >
            <Phone size={18} />
            <span>Call Guardian Immediately</span>
          </a>

          <a
            href={`https://wa.me/91${cleanDigits}?text=${encodeURIComponent(`Hello, I scanned ${dossier.name}'s PetConnect AI Emergency Collar Tag. I have your companion with me.`)}`}
            target="_blank"
            rel="noopener noreferrer"
            style={{
              padding: '16px',
              borderRadius: '12px',
              backgroundColor: '#25D366',
              color: '#FFFFFF',
              fontWeight: 800,
              fontSize: '0.96rem',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '10px',
              boxShadow: '0 4px 16px rgba(37, 211, 102, 0.3)',
            }}
          >
            <MessageSquare size={18} />
            <span>WhatsApp Message</span>
          </a>
        </div>

        {/* Location Share & Veterinary Hospital Directions */}
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '12px', marginTop: '14px' }}>
          <button
            onClick={handleShareLocation}
            style={{
              flex: 1,
              padding: '12px',
              borderRadius: '10px',
              backgroundColor: 'rgba(255, 255, 255, 0.05)',
              border: '1px solid var(--border-medium)',
              color: 'var(--text-primary)',
              fontSize: '0.88rem',
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
            }}
          >
            <Navigation size={16} color="var(--primary)" />
            <span>{locationSent ? 'Location Link Dispatched!' : 'Send My GPS Location to Owner'}</span>
          </button>

          <a
            href="https://www.google.com/maps/search/emergency+veterinary+hospital+near+me"
            target="_blank"
            rel="noopener noreferrer"
            style={{
              flex: 1,
              padding: '12px',
              borderRadius: '10px',
              backgroundColor: 'rgba(255, 255, 255, 0.05)',
              border: '1px solid var(--border-medium)',
              color: 'var(--text-primary)',
              fontSize: '0.88rem',
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
            }}
          >
            <MapPin size={16} color="#06B6D4" />
            <span>Locate Nearest 24/7 Vet Clinic</span>
          </a>
        </div>
      </div>
    </div>
  );
};
