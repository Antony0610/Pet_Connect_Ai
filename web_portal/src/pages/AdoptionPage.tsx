import React, { useState } from 'react';
import { 
  HeartHandshake, 
  MapPin, 
  Check, 
  Sparkles, 
  ShieldCheck, 
  Send, 
  X, 
  CheckCircle2,
  Calendar,
  Heart
} from 'lucide-react';
import confetti from 'canvas-confetti';
import { AdoptionProfile } from '../types';

interface AdoptionPageProps {
  navigate: (route: string) => void;
}

const RESCUE_PROFILES: AdoptionProfile[] = [
  {
    id: 'adopt-01',
    name: 'Bruno',
    species: 'Dog',
    breed: 'Indie Hound Cross',
    age: '1.5 years',
    gender: 'Male',
    shelter_name: 'Hope Animal Rescue Trust',
    location: 'Kochi, Kerala',
    image_url: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=600&q=80',
    personality: ['Playful', 'Affectionate', 'Good with Kids', 'Leash Trained'],
    vaccinated: true,
    neutered: true,
    microchipped: true,
    story: 'Rescued during monsoon flooding; fully rehabilitated with high energy and deep loyalty. Adores evening jogs and belly rubs.',
  },
  {
    id: 'adopt-02',
    name: 'Mochi',
    species: 'Cat',
    breed: 'Domestic Longhair Mix',
    age: '8 months',
    gender: 'Female',
    shelter_name: 'Paws & Whiskers Sanctuary',
    location: 'Aluva, Kerala',
    image_url: 'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?auto=format&fit=crop&w=600&q=80',
    personality: ['Gentle', 'Quiet Purrer', 'Loves Sunbeams', 'Litter Trained'],
    vaccinated: true,
    neutered: true,
    microchipped: true,
    story: 'Gentle soul discovered at a local tea plantation. Soft purrs when brushed, ideal for calm apartment living.',
  },
  {
    id: 'adopt-03',
    name: 'Simba',
    species: 'Dog',
    breed: 'Golden Retriever Mix',
    age: '2 years',
    gender: 'Male',
    shelter_name: 'Cochin Pet Welfare Center',
    location: 'Ernakulam, Kerala',
    image_url: 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=600&q=80',
    personality: ['Swimming Lover', 'Fetch Champion', 'Gentle Giant'],
    vaccinated: true,
    neutered: true,
    microchipped: true,
    story: 'Surrendered due to family relocation. Outstanding recall obedience, loves swimming and human companionship.',
  },
  {
    id: 'adopt-04',
    name: 'Bella',
    species: 'Dog',
    breed: 'Border Collie Cross',
    age: '1 year',
    gender: 'Female',
    shelter_name: 'Hope Animal Rescue Trust',
    location: 'Kochi, Kerala',
    image_url: 'https://images.unsplash.com/photo-1517849845537-4d257902454a?auto=format&fit=crop&w=600&q=80',
    personality: ['Agile', 'Quick Learner', 'Curious', 'Frisbee Enthusiast'],
    vaccinated: true,
    neutered: true,
    microchipped: true,
    story: 'Energetic and whip-smart. Thrives when learning new commands and will make an incredible trail running buddy.',
  },
];

export const AdoptionPage: React.FC<AdoptionPageProps> = ({ navigate }) => {
  const [pets, setPets] = useState<AdoptionProfile[]>(RESCUE_PROFILES);
  const [filterSpecies, setFilterSpecies] = useState<'All' | 'Dog' | 'Cat'>('All');
  const [selectedPet, setSelectedPet] = useState<AdoptionProfile | null>(null);
  const [applicantName, setApplicantName] = useState('');
  const [applicantPhone, setApplicantPhone] = useState('');
  const [applicantHomeType, setApplicantHomeType] = useState('Apartment');
  const [inquirySubmitted, setInquirySubmitted] = useState(false);

  const filteredPets = pets.filter(p => 
    filterSpecies === 'All' ? true : p.species === filterSpecies
  );

  const handleApply = (e: React.FormEvent) => {
    e.preventDefault();
    if (!applicantName || !applicantPhone) return;

    // Trigger celebration confetti
    try {
      confetti({
        particleCount: 80,
        spread: 70,
        origin: { y: 0.6 },
        colors: ['#10B981', '#06B6D4', '#F59E0B', '#FFFFFF'],
      });
    } catch (_e) {
      // Confetti fallback
    }

    setInquirySubmitted(true);
    setTimeout(() => {
      setInquirySubmitted(false);
      setSelectedPet(null);
      setApplicantName('');
      setApplicantPhone('');
    }, 2500);
  };

  return (
    <div style={{ maxWidth: '1280px', margin: '0 auto', padding: '40px 24px 80px' }}>
      {/* Header */}
      <div style={{ marginBottom: '40px', display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'flex-end', gap: '20px' }}>
        <div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', color: 'var(--primary)', fontSize: '0.85rem', fontFamily: 'var(--font-mono)', fontWeight: 700, marginBottom: '10px' }}>
            <HeartHandshake size={16} />
            <span>VERIFIED SHELTER ADOPTION PIPELINE</span>
          </div>
          <h1 style={{ fontSize: 'clamp(2rem, 4vw, 3rem)', fontWeight: 900, letterSpacing: '-0.03em' }}>
            Find Your Lifelong Companion
          </h1>
          <p style={{ color: 'var(--text-secondary)', maxWidth: '600px', fontSize: '1rem', marginTop: '8px' }}>
            Every companion below is clinically vetted, microchipped, fully vaccinated, and registered with an active PetConnect AI Sovereign Health Pass.
          </p>
        </div>

        {/* Filter Tabs */}
        <div style={{ display: 'flex', gap: '8px' }}>
          {(['All', 'Dog', 'Cat'] as const).map(sp => (
            <button
              key={sp}
              onClick={() => setFilterSpecies(sp)}
              style={{
                padding: '8px 18px',
                borderRadius: '8px',
                fontSize: '0.86rem',
                fontWeight: 600,
                backgroundColor: filterSpecies === sp ? 'rgba(16, 185, 129, 0.2)' : 'rgba(255, 255, 255, 0.04)',
                color: filterSpecies === sp ? 'var(--primary)' : 'var(--text-secondary)',
                border: filterSpecies === sp ? '1px solid var(--primary)' : '1px solid var(--border-subtle)',
              }}
            >
              {sp === 'All' ? 'All Companions' : `${sp}s`}
            </button>
          ))}
        </div>
      </div>

      {/* Grid of Pets */}
      <div 
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
          gap: '28px',
        }}
      >
        {filteredPets.map((pet) => (
          <div
            key={pet.id}
            className="glass-panel"
            style={{
              borderRadius: 'var(--radius-lg)',
              overflow: 'hidden',
              display: 'flex',
              flexDirection: 'column',
              transition: 'all var(--transition-smooth)',
            }}
          >
            {/* Pet Photo Container */}
            <div style={{ position: 'relative', height: '240px', overflow: 'hidden' }}>
              <img
                src={pet.image_url}
                alt={pet.name}
                style={{
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover',
                  transition: 'transform 0.5s ease',
                }}
                onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
                onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
              />
              <div 
                style={{
                  position: 'absolute',
                  top: '12px',
                  right: '12px',
                  padding: '4px 10px',
                  borderRadius: '6px',
                  backgroundColor: 'rgba(8, 10, 16, 0.8)',
                  backdropFilter: 'blur(8px)',
                  fontSize: '0.74rem',
                  fontFamily: 'var(--font-mono)',
                  color: 'var(--primary)',
                  fontWeight: 700,
                  border: '1px solid rgba(16, 185, 129, 0.3)',
                }}
              >
                PASS READY
              </div>
            </div>

            {/* Content Body */}
            <div style={{ padding: '24px', display: 'flex', flexDirection: 'column', flex: 1 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: '6px' }}>
                <h3 style={{ fontSize: '1.4rem', fontWeight: 800 }}>{pet.name}</h3>
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>{pet.age} • {pet.gender}</span>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--text-secondary)', fontSize: '0.85rem', marginBottom: '14px' }}>
                <MapPin size={14} color="var(--primary)" />
                <span>{pet.shelter_name} ({pet.location})</span>
              </div>

              <p style={{ color: 'var(--text-muted)', fontSize: '0.88rem', lineHeight: '1.5', marginBottom: '16px', flex: 1 }}>
                {pet.story}
              </p>

              {/* Personality Pills */}
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginBottom: '20px' }}>
                {pet.personality.map((trait, i) => (
                  <span
                    key={i}
                    style={{
                      fontSize: '0.72rem',
                      padding: '3px 8px',
                      borderRadius: '6px',
                      backgroundColor: 'rgba(255, 255, 255, 0.04)',
                      border: '1px solid var(--border-subtle)',
                      color: 'var(--text-secondary)',
                    }}
                  >
                    {trait}
                  </span>
                ))}
              </div>

              {/* Verified Health Flags */}
              <div style={{ display: 'flex', gap: '14px', fontSize: '0.78rem', color: 'var(--text-secondary)', paddingBottom: '18px', borderBottom: '1px solid var(--border-subtle)', marginBottom: '18px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <ShieldCheck size={14} color="var(--primary)" />
                  <span>Vaccinated</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <ShieldCheck size={14} color="var(--primary)" />
                  <span>Neutered</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <ShieldCheck size={14} color="var(--primary)" />
                  <span>Microchipped</span>
                </div>
              </div>

              {/* Action Button */}
              <button
                onClick={() => setSelectedPet(pet)}
                style={{
                  width: '100%',
                  padding: '12px',
                  borderRadius: '10px',
                  background: 'linear-gradient(135deg, var(--primary) 0%, #059669 100%)',
                  color: '#FFFFFF',
                  fontWeight: 700,
                  fontSize: '0.92rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '8px',
                  boxShadow: '0 4px 14px rgba(16, 185, 129, 0.25)',
                }}
              >
                <Heart size={16} />
                <span>Meet {pet.name} (Apply to Adopt)</span>
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Adoption Application Modal */}
      {selectedPet && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            zIndex: 300,
            backgroundColor: 'rgba(0, 0, 0, 0.82)',
            backdropFilter: 'blur(10px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '20px',
          }}
          onClick={() => setSelectedPet(null)}
        >
          <div
            style={{
              width: '100%',
              maxWidth: '520px',
              backgroundColor: 'var(--bg-surface)',
              border: '1px solid var(--border-medium)',
              borderRadius: 'var(--radius-lg)',
              padding: '30px',
              boxShadow: 'var(--shadow-lg)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            {inquirySubmitted ? (
              <div style={{ textAlign: 'center', padding: '24px 0' }}>
                <CheckCircle2 size={54} color="var(--primary)" style={{ margin: '0 auto 16px' }} />
                <h3 style={{ fontSize: '1.4rem', fontWeight: 800, marginBottom: '8px' }}>
                  Adoption Inquiry Dispatched!
                </h3>
                <p style={{ color: 'var(--text-secondary)', fontSize: '0.92rem', lineHeight: '1.6' }}>
                  {selectedPet.shelter_name} has received your inquiry for <strong>{selectedPet.name}</strong>. Their coordinator will reach out via WhatsApp / Call within 24 hours to schedule a meet-and-greet!
                </p>
              </div>
            ) : (
              <form onSubmit={handleApply}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                  <div>
                    <h3 style={{ fontSize: '1.3rem', fontWeight: 800 }}>Adopt {selectedPet.name}</h3>
                    <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{selectedPet.shelter_name}</p>
                  </div>
                  <button type="button" onClick={() => setSelectedPet(null)}>
                    <X size={20} color="var(--text-muted)" />
                  </button>
                </div>

                <div style={{ marginBottom: '16px' }}>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)', marginBottom: '6px' }}>
                    Your Full Name *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Dr. Ananya Menon"
                    value={applicantName}
                    onChange={(e) => setApplicantName(e.target.value)}
                    style={{
                      width: '100%',
                      padding: '12px 14px',
                      borderRadius: '8px',
                      backgroundColor: 'rgba(255, 255, 255, 0.05)',
                      border: '1px solid var(--border-medium)',
                      color: 'var(--text-primary)',
                      fontSize: '0.92rem',
                    }}
                  />
                </div>

                <div style={{ marginBottom: '16px' }}>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)', marginBottom: '6px' }}>
                    Phone Number (WhatsApp Verified) *
                  </label>
                  <input
                    type="tel"
                    required
                    placeholder="e.g. +91 98470 12345"
                    value={applicantPhone}
                    onChange={(e) => setApplicantPhone(e.target.value)}
                    style={{
                      width: '100%',
                      padding: '12px 14px',
                      borderRadius: '8px',
                      backgroundColor: 'rgba(255, 255, 255, 0.05)',
                      border: '1px solid var(--border-medium)',
                      color: 'var(--text-primary)',
                      fontSize: '0.92rem',
                    }}
                  />
                </div>

                <div style={{ marginBottom: '24px' }}>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)', marginBottom: '6px' }}>
                    Home Environment
                  </label>
                  <select
                    value={applicantHomeType}
                    onChange={(e) => setApplicantHomeType(e.target.value)}
                    style={{
                      width: '100%',
                      padding: '12px 14px',
                      borderRadius: '8px',
                      backgroundColor: 'var(--bg-surface-elevated)',
                      border: '1px solid var(--border-medium)',
                      color: 'var(--text-primary)',
                      fontSize: '0.92rem',
                    }}
                  >
                    <option value="Apartment">Apartment (Gated / Balcony)</option>
                    <option value="Independent House with Yard">Independent House with Fenced Yard</option>
                    <option value="Farm / Villa">Farm / Villa Estate</option>
                  </select>
                </div>

                <button
                  type="submit"
                  style={{
                    width: '100%',
                    padding: '14px',
                    borderRadius: '10px',
                    backgroundColor: 'var(--primary)',
                    color: '#FFFFFF',
                    fontWeight: 800,
                    fontSize: '0.96rem',
                    boxShadow: '0 4px 14px rgba(16, 185, 129, 0.35)',
                  }}
                >
                  Submit Adoption Application
                </button>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
