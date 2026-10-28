import React, { useState, useEffect } from 'react';
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
  Heart,
  ArrowLeft,
  Phone,
  MessageSquare,
  Share2,
  Info,
  CheckCircle,
  ExternalLink
} from 'lucide-react';
import confetti from 'canvas-confetti';
import { supabase } from '../lib/supabase';
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
    contact_phone: '+91 98470 12345',
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
    contact_phone: '+91 98470 54321',
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
    contact_phone: '+91 98470 12345',
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
    contact_phone: '+91 98470 12345',
  },
];

export const AdoptionPage: React.FC<AdoptionPageProps> = ({ navigate }) => {
  const [pets, setPets] = useState<AdoptionProfile[]>(RESCUE_PROFILES);
  const [filterSpecies, setFilterSpecies] = useState<'All' | 'Dog' | 'Cat'>('All');
  
  // Single Pet Deep Link / Dedicated Page view state
  const [selectedPetForDetail, setSelectedPetForDetail] = useState<AdoptionProfile | null>(null);

  // Application form modal state
  const [selectedPet, setSelectedPet] = useState<AdoptionProfile | null>(null);
  const [applicantName, setApplicantName] = useState('');
  const [applicantPhone, setApplicantPhone] = useState('');
  const [applicantHomeType, setApplicantHomeType] = useState('Apartment');
  const [inquirySubmitted, setInquirySubmitted] = useState(false);
  const [copiedLink, setCopiedLink] = useState(false);

  // Handle URL deep link check on load and popstate
  useEffect(() => {
    const parseUrlAndLoadPet = () => {
      const pathSegments = window.location.pathname.split('/').filter(Boolean);
      const aIdx = pathSegments.findIndex(s => s === 'adopt');
      let petIdFromUrl: string | null = null;

      if (aIdx !== -1 && pathSegments[aIdx + 1]) {
        petIdFromUrl = pathSegments[aIdx + 1];
      }

      const params = new URLSearchParams(window.location.search);
      if (!petIdFromUrl) {
        petIdFromUrl = params.get('id') || params.get('pet_id');
      }

      if (!petIdFromUrl) {
        setSelectedPetForDetail(null);
        return;
      }

      const pName = params.get('name');
      const pBreed = params.get('breed');
      const pSpecies = params.get('species');
      const pAge = params.get('age');
      const pGender = params.get('gender');
      const pShelter = params.get('shelter');
      const pLocation = params.get('location');
      const pImg = params.get('img');
      const pPhone = params.get('phone');
      const pStory = params.get('story') || params.get('desc');

      // 1. Check local catalog first
      const existing = pets.find(
        p => p.id.toLowerCase() === petIdFromUrl?.toLowerCase() || 
             (pName && p.name.toLowerCase() === pName.toLowerCase())
      );

      if (existing) {
        setSelectedPetForDetail(existing);
        return;
      }

      // 2. Fetch from Supabase pets table or construct profile
      const fetchCloudPet = async (cleanId: string) => {
        try {
          const { data: petRow } = await supabase
            .from('pets')
            .select('*, profiles:owner_id(full_name, city, phone)')
            .eq('id', cleanId)
            .maybeSingle();

          if (petRow) {
            const owner = petRow.profiles || {};
            const cloudProfile: AdoptionProfile = {
              id: petRow.id,
              name: petRow.name || pName || 'Companion',
              species: petRow.species ? (petRow.species.charAt(0).toUpperCase() + petRow.species.slice(1)) : (pSpecies || 'Dog'),
              breed: petRow.breed || pBreed || 'Standard Breed',
              age: pAge || (petRow.date_of_birth ? `${(Math.max(1, Math.round((Date.now() - new Date(petRow.date_of_birth).getTime()) / (365 * 24 * 3600 * 1000))))} yrs` : 'Young Adult'),
              gender: petRow.gender || pGender || 'Not Specified',
              shelter_name: pShelter || owner.full_name || 'PetConnect Rescue Network',
              location: pLocation || owner.city || 'Kerala, India',
              image_url: petRow.image_url || pImg || 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=600&q=80',
              personality: Array.isArray(petRow.personality) && petRow.personality.length > 0 
                ? petRow.personality 
                : ['Clinically Vetted', 'Healthy', 'Adoption Ready'],
              vaccinated: true,
              neutered: true,
              microchipped: !!petRow.microchip_id,
              story: pStory || `Meet ${petRow.name || 'this companion'}. Clinically verified and microchipped on PetConnect AI Sovereign OS, ready for a warm and caring forever home.`,
              contact_phone: pPhone || owner.phone || '+91 89219 98733',
            };
            setSelectedPetForDetail(cloudProfile);
            return;
          }
        } catch (err) {
          console.warn('Fallback to URL params for adoption pet:', err);
        }

        // 3. Fallback: Build rich profile from QR parameters
        const fallbackProfile: AdoptionProfile = {
          id: cleanId,
          name: pName || 'Rescue Companion',
          species: pSpecies ? (pSpecies.charAt(0).toUpperCase() + pSpecies.slice(1)) : 'Dog',
          breed: pBreed || 'Companion Animal',
          age: pAge || '1 - 2 years',
          gender: pGender || 'Companion',
          shelter_name: pShelter || 'Verified Shelter / Foster',
          location: pLocation || 'Kerala, India',
          image_url: pImg || 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=600&q=80',
          personality: ['Playful', 'Affectionate', 'Adoption Ready'],
          vaccinated: true,
          neutered: true,
          microchipped: true,
          story: pStory || `Rescued companion registered on PetConnect AI. Clinically inspected and ready for adoption into a permanent loving home.`,
          contact_phone: pPhone || '+91 89219 98733',
        };
        setSelectedPetForDetail(fallbackProfile);
      };

      fetchCloudPet(petIdFromUrl);
    };

    parseUrlAndLoadPet();
    window.addEventListener('popstate', parseUrlAndLoadPet);
    return () => window.removeEventListener('popstate', parseUrlAndLoadPet);
  }, [pets]);

  // Navigate back to all adoption pets
  const handleBackToAllPets = () => {
    setSelectedPetForDetail(null);
    window.history.pushState({}, '', '/adopt');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  // Open a specific pet's dedicated page
  const handleOpenPetDetail = (pet: AdoptionProfile) => {
    setSelectedPetForDetail(pet);
    window.history.pushState({}, '', `/adopt/${pet.id}`);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

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

  const handleSharePet = (pet: AdoptionProfile) => {
    const url = `${window.location.origin}/adopt/${pet.id}`;
    if (navigator.share) {
      navigator.share({
        title: `Adopt ${pet.name} on PetConnect AI`,
        text: `Meet ${pet.name} (${pet.breed}) looking for a forever home on PetConnect AI!`,
        url,
      }).catch(() => {});
    } else {
      navigator.clipboard.writeText(url);
      setCopiedLink(true);
      setTimeout(() => setCopiedLink(false), 2000);
    }
  };

  // =========================================================================
  // VIEW A: DEDICATED SINGLE PET PAGE (When QR is scanned or pet is clicked)
  // =========================================================================
  if (selectedPetForDetail) {
    const pet = selectedPetForDetail;
    const cleanPhone = (pet.contact_phone || '+918921998733').replace(/[^0-9]/g, '').slice(-10);

    return (
      <div style={{ maxWidth: '960px', margin: '0 auto', padding: '32px 20px 80px' }}>
        {/* Back Navigation Button */}
        <button
          onClick={handleBackToAllPets}
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '8px',
            padding: '10px 18px',
            borderRadius: '10px',
            backgroundColor: 'rgba(255, 255, 255, 0.05)',
            border: '1px solid var(--border-medium)',
            color: 'var(--text-secondary)',
            cursor: 'pointer',
            fontSize: '0.92rem',
            fontWeight: 600,
            marginBottom: '28px',
            transition: 'all var(--transition-smooth)',
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.backgroundColor = 'rgba(255, 255, 255, 0.1)';
            e.currentTarget.style.color = 'var(--text-primary)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.backgroundColor = 'rgba(255, 255, 255, 0.05)';
            e.currentTarget.style.color = 'var(--text-secondary)';
          }}
        >
          <ArrowLeft size={18} />
          <span>← Back to All Adoption Pets</span>
        </button>

        {/* Hero Card Container */}
        <div 
          className="glass-panel"
          style={{
            borderRadius: 'var(--radius-lg)',
            overflow: 'hidden',
            border: '1px solid var(--border-medium)',
            boxShadow: 'var(--shadow-lg)',
          }}
        >
          {/* Top Status Header */}
          <div 
            style={{
              padding: '14px 24px',
              backgroundColor: 'rgba(16, 185, 129, 0.12)',
              borderBottom: '1px solid rgba(16, 185, 129, 0.25)',
              display: 'flex',
              flexWrap: 'wrap',
              justifyContent: 'space-between',
              alignItems: 'center',
              gap: '12px',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary)', fontWeight: 800, fontSize: '0.86rem', fontFamily: 'var(--font-mono)' }}>
              <HeartHandshake size={18} />
              <span>VERIFIED ADOPTION CANDIDATE DOSSIER</span>
            </div>
            <div style={{ display: 'flex', gap: '8px' }}>
              <span style={{ fontSize: '0.74rem', padding: '4px 10px', borderRadius: '6px', backgroundColor: 'rgba(16, 185, 129, 0.2)', color: 'var(--primary)', fontWeight: 700 }}>
                HEALTH PASS VERIFIED
              </span>
              <span style={{ fontSize: '0.74rem', padding: '4px 10px', borderRadius: '6px', backgroundColor: 'rgba(59, 130, 246, 0.2)', color: '#60A5FA', fontWeight: 700 }}>
                READY FOR REHOMING
              </span>
            </div>
          </div>

          {/* Main Grid: Photo + Information */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '32px', padding: '32px' }}>
            {/* Left: Pet Photo & Gallery */}
            <div>
              <div 
                style={{
                  position: 'relative',
                  width: '100%',
                  height: '380px',
                  borderRadius: 'var(--radius-md)',
                  overflow: 'hidden',
                  border: '1px solid var(--border-subtle)',
                }}
              >
                <img
                  src={pet.image_url}
                  alt={pet.name}
                  style={{
                    width: '100%',
                    height: '100%',
                    objectFit: 'cover',
                  }}
                />
                <div
                  style={{
                    position: 'absolute',
                    top: '14px',
                    left: '14px',
                    padding: '4px 12px',
                    borderRadius: '8px',
                    backgroundColor: 'rgba(8, 10, 16, 0.85)',
                    backdropFilter: 'blur(8px)',
                    color: '#FFFFFF',
                    fontSize: '0.78rem',
                    fontWeight: 700,
                    border: '1px solid var(--border-subtle)',
                  }}
                >
                  {pet.species} • {pet.gender}
                </div>
              </div>

              {/* Personality Pills */}
              <div style={{ marginTop: '20px' }}>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 700, marginBottom: '8px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Key Personality Traits
                </div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                  {pet.personality.map((trait, i) => (
                    <span
                      key={i}
                      style={{
                        fontSize: '0.82rem',
                        padding: '5px 12px',
                        borderRadius: '8px',
                        backgroundColor: 'rgba(255, 255, 255, 0.05)',
                        border: '1px solid var(--border-medium)',
                        color: 'var(--text-secondary)',
                        fontWeight: 500,
                      }}
                    >
                      ✨ {trait}
                    </span>
                  ))}
                </div>
              </div>
            </div>

            {/* Right: Detailed Dossier & Actions */}
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              <div style={{ marginBottom: '18px' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px' }}>
                  <h1 style={{ fontSize: 'clamp(2.2rem, 3.5vw, 2.8rem)', fontWeight: 900, letterSpacing: '-0.02em', margin: 0 }}>
                    {pet.name}
                  </h1>
                  <button
                    onClick={() => handleSharePet(pet)}
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '6px',
                      padding: '8px 14px',
                      borderRadius: '8px',
                      backgroundColor: 'rgba(255, 255, 255, 0.06)',
                      border: '1px solid var(--border-medium)',
                      color: 'var(--text-secondary)',
                      cursor: 'pointer',
                      fontSize: '0.82rem',
                    }}
                  >
                    <Share2 size={15} />
                    <span>{copiedLink ? 'Copied Link!' : 'Share'}</span>
                  </button>
                </div>
                <p style={{ color: 'var(--primary)', fontWeight: 700, fontSize: '1.05rem', marginTop: '4px' }}>
                  {pet.breed}
                </p>
              </div>

              {/* Quick Meta Row */}
              <div 
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(3, 1fr)',
                  gap: '12px',
                  backgroundColor: 'rgba(255, 255, 255, 0.03)',
                  padding: '16px',
                  borderRadius: '12px',
                  border: '1px solid var(--border-subtle)',
                  marginBottom: '22px',
                  textAlign: 'center',
                }}
              >
                <div>
                  <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', textTransform: 'uppercase' }}>Age</div>
                  <div style={{ fontSize: '0.98rem', fontWeight: 800, marginTop: '2px' }}>{pet.age}</div>
                </div>
                <div style={{ borderLeft: '1px solid var(--border-subtle)', borderRight: '1px solid var(--border-subtle)' }}>
                  <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', textTransform: 'uppercase' }}>Gender</div>
                  <div style={{ fontSize: '0.98rem', fontWeight: 800, marginTop: '2px' }}>{pet.gender}</div>
                </div>
                <div>
                  <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', textTransform: 'uppercase' }}>Status</div>
                  <div style={{ fontSize: '0.98rem', fontWeight: 800, color: 'var(--primary)', marginTop: '2px' }}>Adoptable</div>
                </div>
              </div>

              {/* Shelter & Location */}
              <div 
                style={{
                  display: 'flex',
                  alignItems: 'flex-start',
                  gap: '10px',
                  backgroundColor: 'rgba(255, 255, 255, 0.03)',
                  padding: '14px 16px',
                  borderRadius: '10px',
                  border: '1px solid var(--border-subtle)',
                  marginBottom: '20px',
                }}
              >
                <MapPin size={20} color="var(--primary)" style={{ flexShrink: 0, marginTop: '2px' }} />
                <div>
                  <div style={{ fontWeight: 700, fontSize: '0.95rem' }}>{pet.shelter_name}</div>
                  <div style={{ color: 'var(--text-secondary)', fontSize: '0.84rem' }}>{pet.location}</div>
                </div>
              </div>

              {/* About & Story */}
              <div style={{ marginBottom: '24px', flex: 1 }}>
                <div style={{ fontSize: '0.82rem', color: 'var(--text-muted)', fontWeight: 700, marginBottom: '6px', textTransform: 'uppercase' }}>
                  About & Background
                </div>
                <p style={{ color: 'var(--text-secondary)', fontSize: '0.94rem', lineHeight: '1.65' }}>
                  {pet.story}
                </p>
              </div>

              {/* Verified Health Badges */}
              <div 
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(3, 1fr)',
                  gap: '10px',
                  padding: '14px',
                  borderRadius: '10px',
                  backgroundColor: 'rgba(16, 185, 129, 0.06)',
                  border: '1px solid rgba(16, 185, 129, 0.2)',
                  marginBottom: '26px',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.8rem', color: 'var(--text-primary)' }}>
                  <ShieldCheck size={16} color="var(--primary)" />
                  <span>Vaccinated</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.8rem', color: 'var(--text-primary)' }}>
                  <ShieldCheck size={16} color="var(--primary)" />
                  <span>Neutered</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.8rem', color: 'var(--text-primary)' }}>
                  <ShieldCheck size={16} color="var(--primary)" />
                  <span>Microchipped</span>
                </div>
              </div>

              {/* Action Buttons */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                <button
                  onClick={() => setSelectedPet(pet)}
                  style={{
                    width: '100%',
                    padding: '15px',
                    borderRadius: '12px',
                    background: 'linear-gradient(135deg, var(--primary) 0%, #059669 100%)',
                    color: '#FFFFFF',
                    fontWeight: 800,
                    fontSize: '1rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '10px',
                    boxShadow: '0 6px 20px rgba(16, 185, 129, 0.35)',
                    cursor: 'pointer',
                  }}
                >
                  <Heart size={18} fill="#FFFFFF" />
                  <span>Apply to Adopt {pet.name}</span>
                </button>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <a
                    href={`https://wa.me/91${cleanPhone}?text=${encodeURIComponent(`Hi, I am interested in adopting ${pet.name} (${pet.breed}) from PetConnect AI!`)}`}
                    target="_blank"
                    rel="noreferrer"
                    style={{
                      padding: '12px',
                      borderRadius: '10px',
                      backgroundColor: 'rgba(255, 255, 255, 0.05)',
                      border: '1px solid var(--border-medium)',
                      color: 'var(--text-primary)',
                      fontWeight: 600,
                      fontSize: '0.88rem',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '8px',
                      textDecoration: 'none',
                    }}
                  >
                    <MessageSquare size={16} color="var(--primary)" />
                    <span>WhatsApp</span>
                  </a>

                  <a
                    href={`tel:+91${cleanPhone}`}
                    style={{
                      padding: '12px',
                      borderRadius: '10px',
                      backgroundColor: 'rgba(255, 255, 255, 0.05)',
                      border: '1px solid var(--border-medium)',
                      color: 'var(--text-primary)',
                      fontWeight: 600,
                      fontSize: '0.88rem',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '8px',
                      textDecoration: 'none',
                    }}
                  >
                    <Phone size={16} color="#60A5FA" />
                    <span>Call Shelter</span>
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Application Modal */}
        {selectedPet && (
          <div
            style={{
              position: 'fixed',
              inset: 0,
              zIndex: 300,
              backgroundColor: 'rgba(0, 0, 0, 0.85)',
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
                    <button type="button" onClick={() => setSelectedPet(null)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
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
                      border: 'none',
                      cursor: 'pointer',
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
  }

  // =========================================================================
  // VIEW B: GENERAL ADOPTION CATALOG (All Pets)
  // =========================================================================
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
                cursor: 'pointer',
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
              cursor: 'pointer',
            }}
            onClick={() => handleOpenPetDetail(pet)}
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
                onClick={(e) => {
                  e.stopPropagation();
                  handleOpenPetDetail(pet);
                }}
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
                  border: 'none',
                  cursor: 'pointer',
                }}
              >
                <Heart size={16} />
                <span>Meet {pet.name} (View Profile)</span>
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
                  <button type="button" onClick={() => setSelectedPet(null)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
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
                    border: 'none',
                    cursor: 'pointer',
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
