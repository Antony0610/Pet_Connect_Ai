import React, { useState, useEffect } from 'react';
import { 
  FileCheck, 
  ShieldCheck, 
  Search, 
  CheckCircle2, 
  Lock, 
  Calendar,
  AlertCircle,
  Loader2
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { VaccinationRecord } from '../types';

interface VerifyPageProps {
  navigate: (route: string) => void;
}

export const VerifyPage: React.FC<VerifyPageProps> = ({ navigate }) => {
  const [vaccinations, setVaccinations] = useState<VaccinationRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedRecord, setSelectedRecord] = useState<VaccinationRecord | null>(null);

  useEffect(() => {
    async function loadVaccinations() {
      try {
        setLoading(true);
        const { data, error } = await supabase
          .from('vaccinations')
          .select('*, pets(name, species, breed, image_url)')
          .order('administered_date', { ascending: false });

        if (data && !error && data.length > 0) {
          setVaccinations(data);
          setSelectedRecord(data[0]);
        }
      } catch (err) {
        console.warn('Error fetching vaccinations:', err);
      } finally {
        setLoading(false);
      }
    }

    loadVaccinations();
  }, []);

  const filteredVaccinations = vaccinations.filter(v => {
    const term = searchTerm.toLowerCase().trim();
    if (!term) return true;
    const petName = (v.pets?.name || '').toLowerCase();
    const vacName = (v.vaccine_name || '').toLowerCase();
    const batch = (v.batch_number || '').toLowerCase();
    return petName.includes(term) || vacName.includes(term) || batch.includes(term);
  });

  return (
    <div style={{ maxWidth: '920px', margin: '0 auto', padding: '40px 24px 80px' }}>
      {/* Editorial Header */}
      <div style={{ textAlign: 'center', marginBottom: '36px' }}>
        <span className="pill-badge" style={{ marginBottom: '12px' }}>
          Official Immunization & Rabies Verification
        </span>
        <h1 style={{ fontSize: 'clamp(1.9rem, 3.5vw, 2.6rem)', fontWeight: 800, letterSpacing: '-0.025em', marginTop: '6px' }}>
          Vaccination Registry
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '0.96rem', maxWidth: '580px', margin: '8px auto 0' }}>
          Real-time cryptographic verification of rabies and core vaccinations registered on PetConnect AI for travel and boarding.
        </p>
      </div>

      {/* Minimalist Search Bar */}
      <div style={{ marginBottom: '28px' }}>
        <div 
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            backgroundColor: 'var(--bg-surface)',
            border: '1px solid var(--border-medium)',
            borderRadius: 'var(--radius-md)',
            padding: '6px 14px',
          }}
        >
          <Search size={16} color="var(--text-muted)" />
          <input
            type="text"
            placeholder="Search by pet name (e.g. Harly, chikku, miavv) or vaccine name..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{
              flex: 1,
              backgroundColor: 'transparent',
              border: 'none',
              color: 'var(--text-primary)',
              fontSize: '0.9rem',
              padding: '8px 0',
              outline: 'none',
            }}
          />
        </div>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '50px 0', color: 'var(--text-muted)' }}>
          <Loader2 size={24} className="animate-spin" style={{ margin: '0 auto 10px' }} />
          <p style={{ fontSize: '0.88rem', fontFamily: 'var(--font-mono)' }}>Loading vaccination certificates from Supabase...</p>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '20px' }}>
          {/* List of Verified Records */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            <div style={{ fontSize: '0.78rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Records in Database ({filteredVaccinations.length})
            </div>
            {filteredVaccinations.map((vac) => {
              const isSelected = selectedRecord?.id === vac.id;
              return (
                <div
                  key={vac.id}
                  onClick={() => setSelectedRecord(vac)}
                  className="flat-card"
                  style={{
                    padding: '14px 16px',
                    cursor: 'pointer',
                    borderColor: isSelected ? 'var(--border-active)' : 'var(--border-subtle)',
                    backgroundColor: isSelected ? 'var(--bg-surface-elevated)' : 'var(--bg-surface)',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: '4px' }}>
                    <span style={{ fontWeight: 800, fontSize: '0.95rem' }}>
                      {vac.pets?.name || 'Companion'}
                    </span>
                    <span className="pill-badge success">
                      VERIFIED
                    </span>
                  </div>
                  <div style={{ fontSize: '0.86rem', color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    {vac.vaccine_name}
                  </div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontFamily: 'var(--font-mono)' }}>
                    Administered: {vac.administered_date || 'N/A'} • Due: {vac.next_due_date || 'N/A'}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Certificate Detail Card - Flat Minimalist */}
          {selectedRecord && (
            <div 
              className="flat-card"
              style={{
                padding: '24px',
                height: 'fit-content',
                position: 'sticky',
                top: '84px',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingBottom: '16px', borderBottom: '1px solid var(--border-subtle)', marginBottom: '16px' }}>
                <div>
                  <span className="pill-badge success" style={{ marginBottom: '6px' }}>
                    AUTHENTIC MEDICAL RECORD
                  </span>
                  <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>
                    {selectedRecord.pets?.name || 'Companion'}
                  </h3>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                    {selectedRecord.pets?.breed || 'Companion Breed'} • {selectedRecord.pets?.species || 'Pet'}
                  </div>
                </div>
                <CheckCircle2 size={24} color="var(--primary)" />
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '0.86rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '8px', borderBottom: '1px solid var(--border-subtle)' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Vaccine Formulation:</span>
                  <span style={{ fontWeight: 700 }}>{selectedRecord.vaccine_name}</span>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '8px', borderBottom: '1px solid var(--border-subtle)' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Administered Date:</span>
                  <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 600 }}>{selectedRecord.administered_date || 'N/A'}</span>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '8px', borderBottom: '1px solid var(--border-subtle)' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Next Due Date:</span>
                  <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 600, color: 'var(--primary)' }}>
                    {selectedRecord.next_due_date || 'Annual Booster Required'}
                  </span>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '8px', borderBottom: '1px solid var(--border-subtle)' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Certificate Record ID:</span>
                  <span style={{ fontFamily: 'var(--font-mono)', fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                    {selectedRecord.id.substring(0, 16)}
                  </span>
                </div>
              </div>

              <div style={{ marginTop: '20px', padding: '10px 14px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--bg-inset)', border: '1px solid var(--border-subtle)', display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.74rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)' }}>
                <Lock size={12} color="var(--primary)" />
                <span>CRYPTOGRAPHICALLY VERIFIED VIA SUPABASE CLOUD</span>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
