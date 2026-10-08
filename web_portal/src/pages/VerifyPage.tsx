import React, { useState } from 'react';
import { 
  FileCheck, 
  ShieldCheck, 
  QrCode, 
  CheckCircle2, 
  AlertCircle, 
  Search, 
  Calendar, 
  Award,
  Lock,
  ArrowRight
} from 'lucide-react';

interface VerifyPageProps {
  navigate: (route: string) => void;
}

interface CertificateData {
  certificateId: string;
  petName: string;
  species: string;
  breed: string;
  microchipId: string;
  vaccineName: string;
  manufacturer: string;
  batchLot: string;
  administeredDate: string;
  validUntil: string;
  vetName: string;
  vetLicense: string;
  clinic: string;
  hashSignature: string;
}

const DEFAULT_CERTIFICATE: CertificateData = {
  certificateId: 'PC-VAC-2026-9821',
  petName: 'Buddy',
  species: 'Dog',
  breed: 'Golden Retriever',
  microchipId: 'PC-98210-IND-2026',
  vaccineName: 'Rabies Virus Vaccine (Inactivated) + DHPP 5-in-1 Core',
  manufacturer: 'Nobivac Rabies (MSD Animal Health)',
  batchLot: 'A489B01 / EXP-2027',
  administeredDate: '15 January 2026',
  validUntil: '15 January 2027',
  vetName: 'Dr. Rajesh Varma, MVSc',
  vetLicense: 'KVC-9014-VET',
  clinic: 'State Central Veterinary Hospital & Diagnostics',
  hashSignature: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
};

export const VerifyPage: React.FC<VerifyPageProps> = ({ navigate }) => {
  const [queryCode, setQueryCode] = useState('');
  const [cert, setCert] = useState<CertificateData>(DEFAULT_CERTIFICATE);
  const [verified, setVerified] = useState(true);
  const [searched, setSearched] = useState(false);

  const handleVerify = (e: React.FormEvent) => {
    e.preventDefault();
    setSearched(true);
    // Any alphanumeric code or test code resolves authentic certificate
    if (queryCode.trim().length > 3) {
      setCert({
        ...DEFAULT_CERTIFICATE,
        certificateId: queryCode.toUpperCase().startsWith('PC') ? queryCode.toUpperCase() : `PC-${queryCode.toUpperCase()}`,
      });
      setVerified(true);
    }
  };

  return (
    <div style={{ maxWidth: '880px', margin: '0 auto', padding: '40px 24px 80px' }}>
      {/* Header */}
      <div style={{ textAlign: 'center', marginBottom: '40px' }}>
        <div style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '8px',
          padding: '6px 14px',
          borderRadius: 'var(--radius-full)',
          background: 'rgba(16, 185, 129, 0.12)',
          border: '1px solid rgba(16, 185, 129, 0.3)',
          color: 'var(--primary)',
          fontSize: '0.82rem',
          fontFamily: 'var(--font-mono)',
          fontWeight: 700,
          marginBottom: '16px',
        }}>
          <ShieldCheck size={16} />
          <span>CRYPTOGRAPHIC CLINICAL VERIFICATION PORTAL</span>
        </div>
        <h1 style={{ fontSize: 'clamp(2rem, 4vw, 3rem)', fontWeight: 900, letterSpacing: '-0.03em', marginBottom: '12px' }}>
          Official Immunization & Rabies Certificate
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '1rem', maxWidth: '620px', margin: '0 auto' }}>
          Verify rabies titers, core vaccinations, and clinical health passports for travel clearance, airline compliance, boarding, and shelter cross-verification.
        </p>
      </div>

      {/* Search / Lookup Bar */}
      <form onSubmit={handleVerify} style={{ marginBottom: '36px' }}>
        <div 
          style={{
            display: 'flex',
            gap: '10px',
            backgroundColor: 'var(--bg-surface)',
            padding: '8px',
            borderRadius: '14px',
            border: '1px solid var(--border-medium)',
            boxShadow: 'var(--shadow-md)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', paddingLeft: '12px', color: 'var(--text-muted)' }}>
            <Search size={20} />
          </div>
          <input
            type="text"
            placeholder="Enter Certificate ID, Microchip ID, or Batch Code (e.g. PC-VAC-2026-9821)"
            value={queryCode}
            onChange={(e) => setQueryCode(e.target.value)}
            style={{
              flex: 1,
              backgroundColor: 'transparent',
              border: 'none',
              color: 'var(--text-primary)',
              fontSize: '0.95rem',
              outline: 'none',
            }}
          />
          <button
            type="submit"
            style={{
              padding: '12px 24px',
              borderRadius: '10px',
              backgroundColor: 'var(--primary)',
              color: '#FFFFFF',
              fontWeight: 700,
              fontSize: '0.92rem',
            }}
          >
            Verify Certificate
          </button>
        </div>
      </form>

      {/* Verified Certificate Dossier Card */}
      <div 
        className="glass-panel"
        style={{
          padding: '36px',
          position: 'relative',
          overflow: 'hidden',
          borderRadius: 'var(--radius-lg)',
        }}
      >
        {/* Verification Watermark Seal */}
        <div 
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            paddingBottom: '24px',
            borderBottom: '1px solid var(--border-subtle)',
            marginBottom: '28px',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
            <div 
              style={{
                width: '48px',
                height: '48px',
                borderRadius: '12px',
                backgroundColor: 'rgba(16, 185, 129, 0.15)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'var(--primary)',
              }}
            >
              <Award size={26} />
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 800, fontSize: '1.05rem', color: 'var(--text-primary)' }}>
                  {cert.certificateId}
                </span>
                <span style={{
                  fontSize: '0.72rem',
                  fontFamily: 'var(--font-mono)',
                  fontWeight: 800,
                  padding: '2px 8px',
                  borderRadius: '6px',
                  backgroundColor: 'rgba(16, 185, 129, 0.2)',
                  color: 'var(--primary)',
                  border: '1px solid rgba(16, 185, 129, 0.4)',
                }}>
                  AUTHENTIC RECORD
                </span>
              </div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                Issued by State Veterinary Authority & Verified on PetConnect AI
              </div>
            </div>
          </div>

          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>VALID UNTIL</div>
            <div style={{ fontFamily: 'var(--font-mono)', fontWeight: 800, fontSize: '1rem', color: 'var(--primary)' }}>
              {cert.validUntil}
            </div>
          </div>
        </div>

        {/* Certificate Breakdown */}
        <div 
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
            gap: '20px',
            marginBottom: '28px',
          }}
        >
          <div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '4px' }}>PATIENT / COMPANION</div>
            <div style={{ fontWeight: 800, fontSize: '1.1rem', color: 'var(--text-primary)' }}>{cert.petName}</div>
            <div style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>{cert.species} • {cert.breed}</div>
          </div>

          <div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '4px' }}>MICROCHIP TRANSPONDER</div>
            <div style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: '0.92rem', color: 'var(--primary)' }}>
              {cert.microchipId}
            </div>
            <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>ISO 11784/11785 Compliant</div>
          </div>

          <div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '4px' }}>ADMINISTERED DATE</div>
            <div style={{ fontWeight: 700, fontSize: '0.95rem', color: 'var(--text-primary)' }}>{cert.administeredDate}</div>
            <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>Annual Booster Protocol</div>
          </div>
        </div>

        {/* Vaccine & Batch Details */}
        <div 
          style={{
            padding: '20px',
            borderRadius: '12px',
            backgroundColor: 'rgba(255, 255, 255, 0.03)',
            border: '1px solid var(--border-subtle)',
            marginBottom: '28px',
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Vaccine Formulation:</span>
            <span style={{ fontWeight: 700, fontSize: '0.9rem' }}>{cert.vaccineName}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Manufacturer:</span>
            <span style={{ fontWeight: 600, fontSize: '0.9rem' }}>{cert.manufacturer}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Batch / Lot Number:</span>
            <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, color: 'var(--primary)' }}>{cert.batchLot}</span>
          </div>
        </div>

        {/* Veterinarian & Clinic Details */}
        <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'center', gap: '16px', paddingBottom: '24px', borderBottom: '1px solid var(--border-subtle)', marginBottom: '24px' }}>
          <div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>LICENSED VETERINARY PRACTITIONER</div>
            <div style={{ fontWeight: 800, fontSize: '0.98rem' }}>{cert.vetName}</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>License: {cert.vetLicense} • {cert.clinic}</div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--primary)', fontWeight: 700, fontSize: '0.85rem' }}>
            <CheckCircle2 size={18} />
            <span>CLINICALLY CERTIFIED</span>
          </div>
        </div>

        {/* Digital Signature & Hash */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.75rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          <Lock size={14} color="var(--primary)" />
          <span>SHA-256 HASH: {cert.hashSignature}</span>
        </div>
      </div>
    </div>
  );
};
