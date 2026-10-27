import React, { useState } from 'react';
import { X, QrCode, ExternalLink, Copy, Check, Sparkles, ShieldAlert, Cpu } from 'lucide-react';

interface QrSimulatorModalProps {
  isOpen: boolean;
  onClose: () => void;
  onNavigateEmergency: (petId: string) => void;
}

const SAMPLE_PETS = [
  {
    id: 'demo-buddy',
    name: 'Buddy',
    species: 'Dog',
    breed: 'Golden Retriever',
    chip: 'PC-98210-IND',
    color: '#F59E0B',
    avatar: 'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=400&q=80',
    allergies: 'Severe Penicillin Allergy (NKDA)',
  },
  {
    id: 'demo-luna',
    name: 'Luna',
    species: 'Cat',
    breed: 'Bengal Cross',
    chip: 'PC-44109-IND',
    color: '#06B6D4',
    avatar: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=400&q=80',
    allergies: 'Asthma Inhaler Required (Fluticasone)',
  },
  {
    id: 'demo-max',
    name: 'Max',
    species: 'Dog',
    breed: 'German Shepherd',
    chip: 'PC-77321-IND',
    color: '#10B981',
    avatar: 'https://images.unsplash.com/photo-1589941013453-ec89f33b5e95?auto=format&fit=crop&w=400&q=80',
    allergies: 'Dietary Celiac Sensitivity (Grain-Free)',
  },
];

export const QrSimulatorModal: React.FC<QrSimulatorModalProps> = ({
  isOpen,
  onClose,
  onNavigateEmergency,
}) => {
  const [selectedPet, setSelectedPet] = useState(SAMPLE_PETS[0]);
  const [copied, setCopied] = useState(false);

  if (!isOpen) return null;

  const emergencyUrl = `${window.location.origin}/emergency?id=${selectedPet.id}&name=${encodeURIComponent(selectedPet.name)}&species=${encodeURIComponent(selectedPet.species)}&breed=${encodeURIComponent(selectedPet.breed)}&chip=${encodeURIComponent(selectedPet.chip)}&demo=true`;

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
        backgroundColor: 'rgba(0, 0, 0, 0.78)',
        backdropFilter: 'blur(12px)',
        WebkitBackdropFilter: 'blur(12px)',
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
          maxWidth: '560px',
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-medium)',
          borderRadius: 'var(--radius-lg)',
          boxShadow: 'var(--shadow-lg)',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
          animation: 'pulseGlow 0.4s ease-out',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div
          style={{
            padding: '20px 24px',
            borderBottom: '1px solid var(--border-subtle)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            background: 'rgba(255, 255, 255, 0.02)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div
              style={{
                width: '32px',
                height: '32px',
                borderRadius: '8px',
                backgroundColor: 'rgba(16, 185, 129, 0.15)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'var(--primary)',
              }}
            >
              <Cpu size={18} />
            </div>
            <div>
              <h3 style={{ fontSize: '1.1rem', fontWeight: 700 }}>
                Interactive Collar Tag Simulator
              </h3>
              <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                Experience how a Good Samaritan or Vet resolves an emergency pass
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '8px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'var(--text-secondary)',
              backgroundColor: 'rgba(255, 255, 255, 0.05)',
            }}
          >
            <X size={18} />
          </button>
        </div>

        {/* Pet Switcher Tabs */}
        <div style={{ padding: '16px 24px 0', display: 'flex', gap: '8px' }}>
          {SAMPLE_PETS.map((pet) => (
            <button
              key={pet.id}
              onClick={() => setSelectedPet(pet)}
              style={{
                flex: 1,
                padding: '8px 12px',
                borderRadius: '8px',
                fontSize: '0.84rem',
                fontWeight: 600,
                background: selectedPet.id === pet.id ? 'rgba(16, 185, 129, 0.18)' : 'rgba(255, 255, 255, 0.04)',
                color: selectedPet.id === pet.id ? 'var(--primary)' : 'var(--text-secondary)',
                border: selectedPet.id === pet.id ? '1px solid var(--primary)' : '1px solid var(--border-subtle)',
                transition: 'all var(--transition-fast)',
              }}
            >
              {pet.name} ({pet.species})
            </button>
          ))}
        </div>

        {/* Body: Collar Tag Mockup */}
        <div style={{ padding: '24px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          {/* Simulated Physical Tag */}
          <div
            style={{
              width: '240px',
              height: '240px',
              borderRadius: '50%',
              background: 'radial-gradient(circle at 35% 35%, #1F293D 0%, #0F1320 80%)',
              border: '6px solid rgba(255, 255, 255, 0.14)',
              boxShadow: '0 20px 40px -10px rgba(0, 0, 0, 0.8), inset 0 2px 4px rgba(255, 255, 255, 0.25)',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              position: 'relative',
              marginBottom: '20px',
            }}
          >
            {/* Top Collar Ring Mount */}
            <div
              style={{
                position: 'absolute',
                top: '-18px',
                width: '26px',
                height: '26px',
                borderRadius: '50%',
                border: '4px solid rgba(255, 255, 255, 0.4)',
                boxShadow: '0 4px 8px rgba(0,0,0,0.5)',
              }}
            />

            {/* Glowing Active LED */}
            <div
              style={{
                position: 'absolute',
                top: '20px',
                width: '8px',
                height: '8px',
                borderRadius: '50%',
                backgroundColor: 'var(--primary)',
                boxShadow: '0 0 10px var(--primary)',
                animation: 'pulseGlow 2s infinite',
              }}
            />

            {/* QR Centerpiece */}
            <div
              style={{
                width: '120px',
                height: '120px',
                backgroundColor: '#FFFFFF',
                borderRadius: '12px',
                padding: '8px',
                boxShadow: '0 4px 12px rgba(0, 0, 0, 0.4)',
                position: 'relative',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              {/* QR Code SVG */}
              <svg width="100%" height="100%" viewBox="0 0 100 100" fill="none">
                <rect width="100" height="100" fill="#FFFFFF" />
                {/* QR Position Squares */}
                <rect x="8" y="8" width="28" height="28" fill="#090B10" rx="3" />
                <rect x="14" y="14" width="16" height="16" fill="#FFFFFF" rx="2" />
                <rect x="18" y="18" width="8" height="8" fill="#10B981" rx="1" />

                <rect x="64" y="8" width="28" height="28" fill="#090B10" rx="3" />
                <rect x="70" y="14" width="16" height="16" fill="#FFFFFF" rx="2" />
                <rect x="74" y="18" width="8" height="8" fill="#10B981" rx="1" />

                <rect x="8" y="64" width="28" height="28" fill="#090B10" rx="3" />
                <rect x="14" y="70" width="16" height="16" fill="#FFFFFF" rx="2" />
                <rect x="18" y="74" width="8" height="8" fill="#10B981" rx="1" />

                {/* Data dots */}
                <rect x="42" y="10" width="6" height="6" fill="#090B10" />
                <rect x="52" y="10" width="6" height="6" fill="#090B10" />
                <rect x="42" y="24" width="6" height="6" fill="#090B10" />
                <rect x="52" y="24" width="6" height="6" fill="#10B981" />
                <rect x="10" y="44" width="6" height="6" fill="#090B10" />
                <rect x="24" y="44" width="6" height="6" fill="#090B10" />
                <rect x="44" y="44" width="12" height="12" fill="#090B10" rx="2" />
                <rect x="64" y="44" width="6" height="6" fill="#090B10" />
                <rect x="76" y="44" width="6" height="6" fill="#090B10" />
                <rect x="44" y="64" width="6" height="6" fill="#090B10" />
                <rect x="54" y="64" width="6" height="6" fill="#10B981" />
                <rect x="44" y="76" width="6" height="6" fill="#090B10" />
                <rect x="64" y="76" width="10" height="6" fill="#090B10" />
                <rect x="80" y="64" width="8" height="8" fill="#090B10" />
              </svg>

              {/* Scanning Laser Beam Effect */}
              <div
                style={{
                  position: 'absolute',
                  left: 0,
                  right: 0,
                  height: '2px',
                  backgroundColor: 'rgba(16, 185, 129, 0.9)',
                  boxShadow: '0 0 8px #10B981',
                  animation: 'scanLaser 2.2s ease-in-out infinite',
                }}
              />
            </div>

            {/* Tag Engraving Info */}
            <div style={{ marginTop: '12px', textAlign: 'center' }}>
              <div style={{ fontSize: '0.86rem', fontWeight: 800, color: '#FFFFFF', letterSpacing: '0.04em' }}>
                {selectedPet.name.toUpperCase()}
              </div>
              <div style={{ fontSize: '0.62rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)' }}>
                {selectedPet.chip}
              </div>
            </div>
          </div>

          {/* Details Card */}
          <div
            style={{
              width: '100%',
              padding: '14px 18px',
              borderRadius: '12px',
              backgroundColor: 'rgba(255, 255, 255, 0.03)',
              border: '1px solid var(--border-subtle)',
              marginBottom: '20px',
              fontSize: '0.85rem',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
              <span style={{ color: 'var(--text-muted)' }}>Species & Breed:</span>
              <span style={{ fontWeight: 600 }}>{selectedPet.species} • {selectedPet.breed}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
              <span style={{ color: 'var(--text-muted)' }}>Clinical Alert:</span>
              <span style={{ color: '#F87171', fontWeight: 600 }}>{selectedPet.allergies}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: 'var(--text-muted)' }}>Cloud Pass ID:</span>
              <span style={{ fontFamily: 'var(--font-mono)', color: 'var(--primary)' }}>{selectedPet.id}</span>
            </div>
          </div>

          {/* Action Buttons */}
          <div style={{ width: '100%', display: 'flex', gap: '10px' }}>
            <button
              onClick={handleSimulateScan}
              style={{
                flex: 1,
                padding: '12px',
                borderRadius: '10px',
                background: 'linear-gradient(135deg, var(--primary) 0%, #059669 100%)',
                color: '#FFFFFF',
                fontWeight: 700,
                fontSize: '0.9rem',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px',
                boxShadow: '0 4px 14px rgba(16, 185, 129, 0.3)',
                transition: 'all var(--transition-fast)',
              }}
            >
              <ExternalLink size={16} />
              <span>Simulate Good Samaritan Scan</span>
            </button>

            <button
              onClick={handleCopyLink}
              style={{
                padding: '12px 18px',
                borderRadius: '10px',
                backgroundColor: 'rgba(255, 255, 255, 0.06)',
                border: '1px solid var(--border-medium)',
                color: 'var(--text-primary)',
                fontWeight: 600,
                fontSize: '0.88rem',
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
              }}
              title="Copy URL"
            >
              {copied ? <Check size={16} color="var(--primary)" /> : <Copy size={16} />}
              <span>{copied ? 'Copied!' : 'Copy Link'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
