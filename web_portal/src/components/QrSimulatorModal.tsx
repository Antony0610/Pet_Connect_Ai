import React, { useState, useEffect } from 'react';
import { X, QrCode, ExternalLink, Copy, Check, Cpu } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { EmergencyPetDossier } from '../types';

interface QrSimulatorModalProps {
  isOpen: boolean;
  onClose: () => void;
  onNavigateEmergency: (petId: string) => void;
}

const FALLBACK_PETS: EmergencyPetDossier[] = [
  {
    id: 'c590ba41-c8ab-4bc5-985b-e15f817e0b3c',
    name: 'Harly',
    species: 'dog',
    breed: 'German Shepard',
    gender: 'male',
    weight_kg: 35.0,
    microchip_id: 'Registered on PetConnect',
    health_status: 'optimal',
    allergies: [],
    chronic_conditions: [],
    emergency_contact_name: 'Antony',
    emergency_contact_phone: '8921998733',
    owner_city: 'Meladoor, Kerala'
  },
  {
    id: 'ca970bed-278a-45c3-99cd-1133bf0c23cc',
    name: 'chikku',
    species: 'cat',
    breed: 'Persian',
    gender: 'male',
    weight_kg: 4.0,
    microchip_id: 'Registered on PetConnect',
    health_status: 'optimal',
    allergies: [],
    chronic_conditions: [],
    emergency_contact_name: 'Antony Thomson',
    emergency_contact_phone: '8921998733',
    owner_city: 'Annamanada, Kerala'
  },
  {
    id: 'f652e1dc-d87c-469b-814b-f19a97aebfa2',
    name: 'Sabu',
    species: 'dog',
    breed: 'Labrador',
    gender: 'female',
    weight_kg: 18.0,
    microchip_id: 'Registered on PetConnect',
    health_status: 'optimal',
    allergies: [],
    chronic_conditions: [],
    emergency_contact_name: 'Joe John',
    emergency_contact_phone: '8089807003',
    owner_city: 'Thrissur'
  }
];

export const QrSimulatorModal: React.FC<QrSimulatorModalProps> = ({
  isOpen,
  onClose,
  onNavigateEmergency,
}) => {
  const [pets, setPets] = useState<EmergencyPetDossier[]>(FALLBACK_PETS);
  const [selectedPet, setSelectedPet] = useState<EmergencyPetDossier>(FALLBACK_PETS[0]);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    async function loadPets() {
      try {
        const { data } = await supabase
          .from('vw_public_emergency_pet')
          .select('*')
          .limit(5);

        if (data && data.length > 0) {
          setPets(data);
          setSelectedPet(data[0]);
        }
      } catch (_e) {
        // Fallback already set
      }
    }

    if (isOpen) {
      loadPets();
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const emergencyUrl = `${window.location.origin}/emergency?id=${selectedPet.id}`;

  const handleCopyLink = () => {
    navigator.clipboard.writeText(emergencyUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleSimulateScan = () => {
    onClose();
    onNavigateEmergency(selectedPet.id);
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 200,
        backgroundColor: 'rgba(0, 0, 0, 0.75)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '20px',
      }}
      onClick={onClose}
    >
      <div
        style={{
          width: '100%',
          maxWidth: '500px',
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-medium)',
          borderRadius: 'var(--radius-md)',
          boxShadow: 'var(--shadow-lg)',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header - Flat Minimalist */}
        <div
          style={{
            padding: '16px 20px',
            borderBottom: '1px solid var(--border-subtle)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Cpu size={16} color="var(--primary)" />
            <h3 style={{ fontSize: '1.05rem', fontWeight: 800 }}>
              Physical Collar Tag Simulator
            </h3>
          </div>
          <button
            onClick={onClose}
            style={{
              padding: '4px',
              borderRadius: '4px',
              color: 'var(--text-secondary)',
            }}
          >
            <X size={18} />
          </button>
        </div>

        {/* Pet Switcher Tabs */}
        <div style={{ padding: '14px 20px 0', display: 'flex', gap: '6px' }}>
          {pets.map((pet) => (
            <button
              key={pet.id}
              onClick={() => setSelectedPet(pet)}
              style={{
                flex: 1,
                padding: '7px 10px',
                borderRadius: 'var(--radius-sm)',
                fontSize: '0.8rem',
                fontFamily: 'var(--font-mono)',
                fontWeight: selectedPet.id === pet.id ? 700 : 500,
                backgroundColor: selectedPet.id === pet.id ? 'var(--btn-primary-bg)' : 'var(--bg-inset)',
                color: selectedPet.id === pet.id ? 'var(--btn-primary-text)' : 'var(--text-secondary)',
                border: '1px solid var(--border-subtle)',
              }}
            >
              {pet.name} ({pet.species})
            </button>
          ))}
        </div>

        {/* Body: Physical Tag Minimalist Graphic */}
        <div style={{ padding: '24px 20px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          {/* Simulated Solid Physical Tag */}
          <div
            style={{
              width: '180px',
              height: '180px',
              borderRadius: '50%',
              backgroundColor: 'var(--bg-inset)',
              border: '3px solid var(--border-medium)',
              boxShadow: 'var(--shadow-md)',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              position: 'relative',
              marginBottom: '20px',
            }}
          >
            {/* Top Ring Mount */}
            <div
              style={{
                position: 'absolute',
                top: '-12px',
                width: '18px',
                height: '18px',
                borderRadius: '50%',
                border: '3px solid var(--border-medium)',
              }}
            />

            {/* QR Centerpiece */}
            <div
              style={{
                width: '90px',
                height: '90px',
                backgroundColor: '#FFFFFF',
                borderRadius: '8px',
                padding: '6px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              {/* QR Code SVG */}
              <svg width="100%" height="100%" viewBox="0 0 100 100" fill="none">
                <rect width="100" height="100" fill="#FFFFFF" />
                <rect x="8" y="8" width="28" height="28" fill="#121316" rx="2" />
                <rect x="14" y="14" width="16" height="16" fill="#FFFFFF" rx="1" />
                <rect x="18" y="18" width="8" height="8" fill="#121316" />

                <rect x="64" y="8" width="28" height="28" fill="#121316" rx="2" />
                <rect x="70" y="14" width="16" height="16" fill="#FFFFFF" rx="1" />
                <rect x="74" y="18" width="8" height="8" fill="#121316" />

                <rect x="8" y="64" width="28" height="28" fill="#121316" rx="2" />
                <rect x="14" y="70" width="16" height="16" fill="#FFFFFF" rx="1" />
                <rect x="18" y="74" width="8" height="8" fill="#121316" />

                <rect x="42" y="10" width="6" height="6" fill="#121316" />
                <rect x="52" y="10" width="6" height="6" fill="#121316" />
                <rect x="42" y="24" width="6" height="6" fill="#121316" />
                <rect x="52" y="24" width="6" height="6" fill="#121316" />
                <rect x="44" y="44" width="12" height="12" fill="#121316" />
                <rect x="64" y="44" width="6" height="6" fill="#121316" />
                <rect x="76" y="44" width="6" height="6" fill="#121316" />
                <rect x="44" y="64" width="6" height="6" fill="#121316" />
                <rect x="54" y="64" width="6" height="6" fill="#121316" />
                <rect x="44" y="76" width="6" height="6" fill="#121316" />
                <rect x="64" y="76" width="10" height="6" fill="#121316" />
              </svg>
            </div>

            <div style={{ marginTop: '10px', textAlign: 'center' }}>
              <div style={{ fontSize: '0.8rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '0.04em' }}>
                {selectedPet.name.toUpperCase()}
              </div>
              <div style={{ fontSize: '0.62rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)' }}>
                {selectedPet.owner_city || 'Kerala'}
              </div>
            </div>
          </div>

          {/* Details Summary */}
          <div
            style={{
              width: '100%',
              padding: '12px 14px',
              borderRadius: 'var(--radius-sm)',
              backgroundColor: 'var(--bg-inset)',
              border: '1px solid var(--border-subtle)',
              marginBottom: '18px',
              fontSize: '0.82rem',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
              <span style={{ color: 'var(--text-muted)' }}>Companion:</span>
              <span style={{ fontWeight: 600 }}>{selectedPet.name} • {selectedPet.breed || 'Companion'}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: 'var(--text-muted)' }}>Guardian Contact:</span>
              <span style={{ fontFamily: 'var(--font-mono)', color: 'var(--text-primary)' }}>{selectedPet.emergency_contact_phone || '8921998733'}</span>
            </div>
          </div>

          {/* Actions */}
          <div style={{ width: '100%', display: 'flex', gap: '8px' }}>
            <button
              onClick={handleSimulateScan}
              className="btn-primary"
              style={{ flex: 1, padding: '10px', fontSize: '0.86rem' }}
            >
              <ExternalLink size={15} />
              <span>Simulate Good Samaritan Scan</span>
            </button>

            <button
              onClick={handleCopyLink}
              className="btn-secondary"
              style={{ padding: '10px 14px', fontSize: '0.86rem' }}
            >
              {copied ? <Check size={14} color="var(--primary)" /> : <Copy size={14} />}
              <span>{copied ? 'Copied' : 'Copy'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
