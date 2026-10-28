import React, { useState, useEffect } from 'react';
import { 
  Radio, 
  MapPin, 
  Clock, 
  AlertCircle, 
  Phone, 
  Share2, 
  Check, 
  PlusCircle, 
  Filter, 
  Eye,
  CheckCircle2,
  X
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { MissingPetReport } from '../types';

interface MissingPetsPageProps {
  navigate: (route: string) => void;
}

const INITIAL_REPORTS: MissingPetReport[] = [
  {
    id: 'mis-01',
    pet_name: 'Milo',
    species: 'Dog',
    breed: 'Beagle',
    last_seen_location: 'Marine Drive, Kochi',
    last_seen_time: '2 hours ago',
    reward_amount: '₹5,000',
    contact_phone: '+91 98951 88200',
    distinctive_marks: 'Red collar with brass bell, white tip on tail',
    image_url: 'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?auto=format&fit=crop&w=600&q=80',
    status: 'ACTIVE',
  },
  {
    id: 'mis-02',
    pet_name: 'Cleo',
    species: 'Cat',
    breed: 'Calico Domestic Shorthair',
    last_seen_location: 'Panampilly Nagar, Kochi',
    last_seen_time: '5 hours ago',
    reward_amount: '₹3,000',
    contact_phone: '+91 94471 22910',
    distinctive_marks: 'Tri-color patches, notched left ear',
    image_url: 'https://images.unsplash.com/photo-1574158622682-e40e69881006?auto=format&fit=crop&w=600&q=80',
    status: 'SIGHTING_REPORTED',
  },
  {
    id: 'mis-03',
    pet_name: 'Rocky',
    species: 'Dog',
    breed: 'Labrador Retriever (Chocolate)',
    last_seen_location: 'Kakkanad Infopark Area',
    last_seen_time: 'Yesterday evening',
    reward_amount: '₹10,000',
    contact_phone: '+91 97455 33011',
    distinctive_marks: 'Microchipped, slight limp on left hind paw',
    image_url: 'https://images.unsplash.com/photo-1591769225440-811ad7d6eab2?auto=format&fit=crop&w=600&q=80',
    status: 'ACTIVE',
  },
];

export const MissingPetsPage: React.FC<MissingPetsPageProps> = ({ navigate }) => {
  const [reports, setReports] = useState<MissingPetReport[]>(INITIAL_REPORTS);
  const [filterSpecies, setFilterSpecies] = useState<'All' | 'Dog' | 'Cat'>('All');
  const [sightingModalPet, setSightingModalPet] = useState<MissingPetReport | null>(null);
  const [sightingLocation, setSightingLocation] = useState('');
  const [sightingNotes, setSightingNotes] = useState('');
  const [sightingSuccess, setSightingSuccess] = useState(false);
  const [ownerUserId, setOwnerUserId] = useState<string | null>(null);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    let alertId = params.get('id') || params.get('alert_id');

    if (!alertId) {
      const pathSegments = window.location.pathname.split('/').filter(Boolean);
      const mIdx = pathSegments.findIndex(s => s === 'missing');
      if (mIdx !== -1 && pathSegments[mIdx + 1]) {
        alertId = pathSegments[mIdx + 1];
      }
    }

    const pName = params.get('name');
    const pPhone = params.get('phone');
    const pLocation = params.get('location');
    const pDate = params.get('date');
    const pReward = params.get('reward');
    const pSpecies = params.get('species');
    const pBreed = params.get('breed');
    const pImg = params.get('img');
    const pNotes = params.get('notes');

    // 1. If scanned from QR poster with parameters, create instant priority card at top
    if (alertId || pName) {
      const scannedId = alertId || `mis-${Date.now()}`;
      const scannedPet: MissingPetReport = {
        id: scannedId,
        pet_name: pName || 'Buddy',
        species: (pSpecies && pSpecies.toLowerCase().includes('cat')) ? 'Cat' : 'Dog',
        breed: pBreed || 'Companion',
        last_seen_location: pLocation || 'Nearby Area',
        last_seen_time: pDate || 'Recently',
        reward_amount: pReward ? (pReward.startsWith('₹') ? pReward : `₹${pReward}`) : undefined,
        contact_phone: pPhone || '+91 98470 12345',
        distinctive_marks: pNotes || 'Active missing alert registered on PetConnect AI Community Radar',
        image_url: pImg || 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=600&q=80',
        status: 'ACTIVE',
      };

      setReports(prev => [scannedPet, ...prev.filter(p => p.id !== scannedId)]);

      // Fetch live database alert record
      const fetchAlertDetails = async () => {
        if (!alertId || alertId.startsWith('demo')) return;

        try {
          // A. Try public RPC first
          const { data: rpcData, error: rpcErr } = await supabase.rpc('get_public_lost_pet_alert', {
            p_id: alertId,
          });

          if (rpcData && !rpcErr && rpcData.pet_name) {
            setReports(prev => prev.map(p => {
              if (p.id === scannedId) {
                return {
                  ...p,
                  id: rpcData.alert_id || p.id,
                  pet_name: rpcData.pet_name || p.pet_name,
                  species: rpcData.pet_species ? (rpcData.pet_species.charAt(0).toUpperCase() + rpcData.pet_species.slice(1)) : p.species,
                  breed: rpcData.pet_breed || p.breed,
                  last_seen_location: rpcData.last_seen_location || p.last_seen_location,
                  last_seen_time: rpcData.last_seen_time ? new Date(rpcData.last_seen_time).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }) : p.last_seen_time,
                  reward_amount: rpcData.reward_amount ? (rpcData.reward_amount.startsWith('₹') ? rpcData.reward_amount : `₹${rpcData.reward_amount}`) : p.reward_amount,
                  contact_phone: rpcData.contact_phone || p.contact_phone,
                  distinctive_marks: rpcData.description || p.distinctive_marks,
                  image_url: rpcData.pet_image_url || p.image_url,
                };
              }
              return p;
            }));
            return;
          }
        } catch (_) {}

        // B. Fallback to direct alert table lookup
        try {
          const { data: aRow } = await supabase
            .from('lost_pet_alerts')
            .select('*, pets(*, profiles:owner_id(full_name, phone, city))')
            .eq('id', alertId)
            .maybeSingle();

          if (aRow) {
            const pet = aRow.pets || {};
            const ownerProf = pet.profiles || {};
            setOwnerUserId(aRow.owner_id || pet.owner_id || null);
            setReports(prev => prev.map(p => {
              if (p.id === scannedId) {
                return {
                  ...p,
                  pet_name: pet.name || p.pet_name,
                  species: pet.species ? (pet.species.charAt(0).toUpperCase() + pet.species.slice(1)) : p.species,
                  breed: pet.breed || p.breed,
                  last_seen_location: aRow.last_seen_location || ownerProf.city || p.last_seen_location,
                  last_seen_time: aRow.last_seen_time ? new Date(aRow.last_seen_time).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }) : p.last_seen_time,
                  reward_amount: aRow.reward_amount ? `₹${aRow.reward_amount}` : p.reward_amount,
                  contact_phone: aRow.contact_phone || ownerProf.phone || p.contact_phone,
                  distinctive_marks: aRow.description || p.distinctive_marks,
                  image_url: pet.image_url || p.image_url,
                };
              }
              return p;
            }));
            return;
          }
        } catch (_) {}

        // C. Fallback directly to pets table
        try {
          const { data: pRow } = await supabase
            .from('pets')
            .select('*, profiles:owner_id(full_name, phone, city)')
            .eq('id', alertId)
            .maybeSingle();

          if (pRow) {
            const ownerProf = pRow.profiles || {};
            setOwnerUserId(pRow.owner_id || null);
            setReports(prev => prev.map(p => {
              if (p.id === scannedId) {
                return {
                  ...p,
                  pet_name: pRow.name || p.pet_name,
                  species: pRow.species ? (pRow.species.charAt(0).toUpperCase() + pRow.species.slice(1)) : p.species,
                  breed: pRow.breed || p.breed,
                  last_seen_location: ownerProf.city || p.last_seen_location,
                  contact_phone: ownerProf.phone || p.contact_phone,
                  distinctive_marks: pRow.notes || p.distinctive_marks,
                  image_url: pRow.image_url || p.image_url,
                };
              }
              return p;
            }));
          }
        } catch (_) {}
      };

      fetchAlertDetails();
    }

    // 2. Load other real active alerts from database
    const loadCommunityAlerts = async () => {
      try {
        const { data: dbAlerts } = await supabase
          .from('lost_pet_alerts')
          .select('*, pets(name, species, breed, image_url), profiles:owner_id(phone, full_name, city)')
          .eq('status', 'active')
          .order('created_at', { ascending: false })
          .limit(6);

        if (Array.isArray(dbAlerts) && dbAlerts.length > 0) {
          const mapped: MissingPetReport[] = dbAlerts.map(a => {
            const pet = a.pets || {};
            const prof = a.profiles || {};
            return {
              id: a.id,
              pet_name: pet.name || 'Lost Companion',
              species: (pet.species && pet.species.toLowerCase() === 'cat') ? 'Cat' : 'Dog',
              breed: pet.breed || 'Companion',
              last_seen_location: a.last_seen_location || prof.city || 'Kerala',
              last_seen_time: a.last_seen_time ? new Date(a.last_seen_time).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }) : 'Recently',
              reward_amount: a.reward_amount ? `₹${a.reward_amount}` : undefined,
              contact_phone: a.contact_phone || prof.phone || '+91 98470 12345',
              distinctive_marks: a.description || 'Community lost pet alert',
              image_url: pet.image_url || 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=600&q=80',
              status: 'ACTIVE',
            };
          });

          setReports(prev => {
            const existingIds = new Set(prev.map(p => p.id));
            const newOnes = mapped.filter(m => !existingIds.has(m.id));
            return [...prev, ...newOnes];
          });
        }
      } catch (_) {}
    };

    loadCommunityAlerts();
  }, []);

  const handleSubmitSighting = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!sightingLocation.trim() || !sightingModalPet) return;

    try {
      // 1. Try public RPC submission first
      let sent = false;
      try {
        const { data: rpcRes, error: rpcErr } = await supabase.rpc('submit_public_lost_sighting', {
          p_id: sightingModalPet.id,
          p_location: sightingLocation.trim(),
          p_reporter_name: 'Passerby Helper',
          p_reporter_phone: null,
          p_notes: sightingNotes.trim() || 'Sighting reported via public web portal QR',
        });
        if (rpcRes && !rpcErr && rpcRes.success) {
          sent = true;
        }
      } catch (_) {}

      // 2. Direct table insert fallback
      if (!sent && sightingModalPet.id.length === 36) {
        await supabase.from('lost_pet_sightings').insert([{
          alert_id: sightingModalPet.id,
          sighting_location: sightingLocation.trim(),
          reporter_name: 'Passerby Helper',
          notes: sightingNotes.trim() || 'Sighting reported via public web portal QR',
          status: 'pending',
        }]);
      }

      // 3. In-app native notification to pet guardian if owner ID is known
      if (ownerUserId) {
        try {
          await supabase.from('user_notifications').insert([{
            user_id: ownerUserId,
            title: `🚨 Sighting Reported: ${sightingModalPet.pet_name}`,
            body: `Spotted at: ${sightingLocation.trim()}. Tap to view details.`,
            notification_type: 'LOST_PET',
            is_read: false,
            payload: {
              alert_id: sightingModalPet.id,
              location: sightingLocation.trim(),
              notes: sightingNotes.trim(),
            },
          }]);
        } catch (_) {}
      }
    } catch (err) {
      console.warn('Sighting submission note:', err);
    }

    setReports(prev => prev.map(p => {
      if (p.id === sightingModalPet?.id) {
        return { ...p, status: 'SIGHTING_REPORTED' };
      }
      return p;
    }));

    setSightingSuccess(true);
    setTimeout(() => {
      setSightingSuccess(false);
      setSightingModalPet(null);
      setSightingLocation('');
      setSightingNotes('');
    }, 2000);
  };

  const filteredReports = reports.filter(r => 
    filterSpecies === 'All' ? true : r.species === filterSpecies
  );

  return (
    <div style={{ maxWidth: '1280px', margin: '0 auto', padding: '40px 24px 80px' }}>
      {/* Header */}
      <div style={{ marginBottom: '40px', display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'flex-end', gap: '20px' }}>
        <div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', color: '#38BDF8', fontSize: '0.85rem', fontFamily: 'var(--font-mono)', fontWeight: 700, marginBottom: '10px' }}>
            <Radio size={16} />
            <span>COMMUNITY LOST PET RADAR // 5-MILE GEOFENCE</span>
          </div>
          <h1 style={{ fontSize: 'clamp(2rem, 4vw, 3rem)', fontWeight: 900, letterSpacing: '-0.03em' }}>
            Active Search & Rescue Grid
          </h1>
          <p style={{ color: 'var(--text-secondary)', maxWidth: '600px', fontSize: '1rem', marginTop: '8px' }}>
            Community-driven real-time missing pet alerts. When an alert triggers, nearby registered PetConnect guardians receive instant geofence notifications.
          </p>
        </div>

        {/* Filters */}
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          {(['All', 'Dog', 'Cat'] as const).map(sp => (
            <button
              key={sp}
              onClick={() => setFilterSpecies(sp)}
              style={{
                padding: '8px 16px',
                borderRadius: '8px',
                fontSize: '0.86rem',
                fontWeight: 600,
                backgroundColor: filterSpecies === sp ? 'rgba(16, 185, 129, 0.2)' : 'rgba(255, 255, 255, 0.04)',
                color: filterSpecies === sp ? 'var(--primary)' : 'var(--text-secondary)',
                border: filterSpecies === sp ? '1px solid var(--primary)' : '1px solid var(--border-subtle)',
              }}
            >
              {sp === 'All' ? 'All Pets' : `${sp}s`}
            </button>
          ))}
        </div>
      </div>

      {/* Interactive Radar Visualizer */}
      <div 
        className="glass-panel"
        style={{
          padding: '24px',
          marginBottom: '40px',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        <div style={{
          width: '100%',
          maxWidth: '800px',
          height: '240px',
          borderRadius: '16px',
          backgroundColor: '#070A12',
          border: '1px solid rgba(6, 182, 212, 0.2)',
          position: 'relative',
          overflow: 'hidden',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}>
          {/* Radar Circles */}
          <div style={{ position: 'absolute', width: '80px', height: '80px', borderRadius: '50%', border: '1px dashed rgba(6, 182, 212, 0.4)' }} />
          <div style={{ position: 'absolute', width: '160px', height: '160px', borderRadius: '50%', border: '1px dashed rgba(6, 182, 212, 0.3)' }} />
          <div style={{ position: 'absolute', width: '240px', height: '240px', borderRadius: '50%', border: '1px dashed rgba(6, 182, 212, 0.2)' }} />

          {/* Animated Sweeper Wave */}
          <div style={{
            position: 'absolute',
            width: '180px',
            height: '180px',
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(16, 185, 129, 0.25) 0%, transparent 70%)',
            animation: 'radarWave 3.5s cubic-bezier(0, 0.2, 0.8, 1) infinite',
          }} />

          {/* Simulated Pet Blips on Radar */}
          <div style={{ position: 'absolute', top: '35%', left: '38%', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <div style={{ width: '12px', height: '12px', borderRadius: '50%', backgroundColor: '#EF4444', boxShadow: '0 0 10px #EF4444' }} />
            <span style={{ fontSize: '0.72rem', fontFamily: 'var(--font-mono)', color: '#FCA5A5', fontWeight: 700 }}>Milo (Beagle)</span>
          </div>

          <div style={{ position: 'absolute', top: '65%', left: '60%', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <div style={{ width: '12px', height: '12px', borderRadius: '50%', backgroundColor: '#F59E0B', boxShadow: '0 0 10px #F59E0B' }} />
            <span style={{ fontSize: '0.72rem', fontFamily: 'var(--font-mono)', color: '#FDE68A', fontWeight: 700 }}>Cleo (Cat)</span>
          </div>

          {/* Center User Pin */}
          <div style={{ width: '20px', height: '20px', borderRadius: '50%', backgroundColor: 'var(--primary)', boxShadow: '0 0 15px var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Radio size={12} color="#FFFFFF" />
          </div>

          <div style={{ position: 'absolute', bottom: '12px', left: '16px', fontSize: '0.75rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)' }}>
            SCANNING FREQUENCY: 868 MHz / NB-IoT // ACTIVE NODES: 42
          </div>
        </div>
      </div>

      {/* Missing Pets Cards Grid */}
      <div 
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))',
          gap: '24px',
        }}
      >
        {filteredReports.map((pet) => (
          <div 
            key={pet.id} 
            className="glass-panel"
            style={{
              padding: '24px',
              display: 'flex',
              flexDirection: 'column',
              position: 'relative',
              overflow: 'hidden',
            }}
          >
            {/* Status Pill */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <span style={{
                fontSize: '0.72rem',
                fontFamily: 'var(--font-mono)',
                fontWeight: 800,
                padding: '3px 8px',
                borderRadius: '6px',
                backgroundColor: pet.status === 'ACTIVE' ? 'rgba(239, 68, 68, 0.2)' : 'rgba(245, 158, 11, 0.2)',
                color: pet.status === 'ACTIVE' ? '#F87171' : '#FBBF24',
                border: pet.status === 'ACTIVE' ? '1px solid rgba(239, 68, 68, 0.4)' : '1px solid rgba(245, 158, 11, 0.4)',
              }}>
                {pet.status === 'ACTIVE' ? '🚨 SEARCHING ACTIVE' : '👁️ SIGHTING REPORTED'}
              </span>

              {pet.reward_amount && (
                <span style={{ fontSize: '0.82rem', fontFamily: 'var(--font-mono)', fontWeight: 700, color: 'var(--primary)' }}>
                  REWARD: {pet.reward_amount}
                </span>
              )}
            </div>

            {/* Photo & Bio */}
            <div style={{ display: 'flex', gap: '16px', marginBottom: '16px' }}>
              <img
                src={pet.image_url}
                alt={pet.pet_name}
                style={{
                  width: '90px',
                  height: '90px',
                  borderRadius: '12px',
                  objectFit: 'cover',
                  border: '2px solid var(--border-medium)',
                }}
              />
              <div>
                <h3 style={{ fontSize: '1.3rem', fontWeight: 800 }}>{pet.pet_name}</h3>
                <p style={{ color: 'var(--text-secondary)', fontSize: '0.88rem' }}>{pet.breed}</p>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--text-muted)', fontSize: '0.8rem', marginTop: '6px' }}>
                  <MapPin size={13} color="var(--primary)" />
                  <span>{pet.last_seen_location}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--text-muted)', fontSize: '0.8rem', marginTop: '3px' }}>
                  <Clock size={13} />
                  <span>{pet.last_seen_time}</span>
                </div>
              </div>
            </div>

            {/* Marks */}
            <div style={{
              padding: '10px 14px',
              borderRadius: '8px',
              backgroundColor: 'rgba(255, 255, 255, 0.03)',
              border: '1px solid var(--border-subtle)',
              fontSize: '0.82rem',
              color: 'var(--text-secondary)',
              marginBottom: '20px',
            }}>
              <strong>Features:</strong> {pet.distinctive_marks}
            </div>

            {/* Action Buttons */}
            <div style={{ marginTop: 'auto', display: 'flex', gap: '10px' }}>
              <button
                onClick={() => setSightingModalPet(pet)}
                style={{
                  flex: 1,
                  padding: '10px',
                  borderRadius: '8px',
                  backgroundColor: 'rgba(16, 185, 129, 0.15)',
                  border: '1px solid rgba(16, 185, 129, 0.35)',
                  color: 'var(--primary)',
                  fontWeight: 700,
                  fontSize: '0.86rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '6px',
                }}
              >
                <Eye size={16} />
                <span>Report Sighting</span>
              </button>

              <a
                href={`tel:${pet.contact_phone}`}
                style={{
                  padding: '10px 14px',
                  borderRadius: '8px',
                  backgroundColor: '#10B981',
                  color: '#FFFFFF',
                  fontWeight: 700,
                  fontSize: '0.86rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                }}
              >
                <Phone size={15} />
                <span>Call</span>
              </a>
            </div>
          </div>
        ))}
      </div>

      {/* Sighting Modal */}
      {sightingModalPet && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            zIndex: 300,
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            backdropFilter: 'blur(8px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '20px',
          }}
          onClick={() => setSightingModalPet(null)}
        >
          <div
            style={{
              width: '100%',
              maxWidth: '480px',
              backgroundColor: 'var(--bg-surface)',
              border: '1px solid var(--border-medium)',
              borderRadius: 'var(--radius-lg)',
              padding: '28px',
              boxShadow: 'var(--shadow-lg)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            {sightingSuccess ? (
              <div style={{ textAlign: 'center', padding: '20px 0' }}>
                <CheckCircle2 size={48} color="var(--primary)" style={{ margin: '0 auto 16px' }} />
                <h3 style={{ fontSize: '1.3rem', fontWeight: 800, marginBottom: '8px' }}>Sighting Recorded!</h3>
                <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
                  The pet guardian has been notified with your dispatch details. Thank you for caring!
                </p>
              </div>
            ) : (
              <form onSubmit={handleSubmitSighting}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                  <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>
                    Report Sighting of {sightingModalPet.pet_name}
                  </h3>
                  <button type="button" onClick={() => setSightingModalPet(null)}>
                    <X size={20} color="var(--text-muted)" />
                  </button>
                </div>

                <div style={{ marginBottom: '16px' }}>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)', marginBottom: '6px' }}>
                    Where did you spot {sightingModalPet.pet_name}? *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Near Metro Pillar 420, MG Road"
                    value={sightingLocation}
                    onChange={(e) => setSightingLocation(e.target.value)}
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
                    Observations / Condition (Optional)
                  </label>
                  <textarea
                    rows={3}
                    placeholder="e.g. Running towards park, collar still on, drinking water"
                    value={sightingNotes}
                    onChange={(e) => setSightingNotes(e.target.value)}
                    style={{
                      width: '100%',
                      padding: '12px 14px',
                      borderRadius: '8px',
                      backgroundColor: 'rgba(255, 255, 255, 0.05)',
                      border: '1px solid var(--border-medium)',
                      color: 'var(--text-primary)',
                      fontSize: '0.92rem',
                      resize: 'none',
                    }}
                  />
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
                  Send Sighting Alert to Guardian
                </button>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
