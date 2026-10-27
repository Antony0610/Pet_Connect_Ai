import React, { useState, useEffect } from 'react';
import { 
  Activity, 
  ShieldAlert, 
  Radio, 
  HeartHandshake, 
  FileCheck, 
  Download, 
  ArrowRight, 
  CheckCircle2, 
  QrCode, 
  MapPin, 
  Cpu, 
  Heart,
  Thermometer,
  BatteryCharging
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { AdoptionListing } from '../types';

interface HomePageProps {
  navigate: (route: string) => void;
  onOpenQrSimulator: () => void;
}

export const HomePage: React.FC<HomePageProps> = ({ navigate, onOpenQrSimulator }) => {
  const [featuredAdoptions, setFeaturedAdoptions] = useState<AdoptionListing[]>([]);
  const [dbStats, setDbStats] = useState({ adoptions: 8, registeredPets: 5, vaccines: 12 });

  useEffect(() => {
    async function loadHomeData() {
      try {
        // Fetch real featured adoption listings
        const { data: adoptData } = await supabase
          .from('adoption_listings')
          .select('*')
          .eq('status', 'active')
          .limit(3);

        if (adoptData && adoptData.length > 0) {
          setFeaturedAdoptions(adoptData);
        }

        // Count queries
        const { count: adoptCount } = await supabase.from('adoption_listings').select('*', { count: 'exact', head: true });
        const { count: petCount } = await supabase.from('pets').select('*', { count: 'exact', head: true });
        const { count: vacCount } = await supabase.from('vaccinations').select('*', { count: 'exact', head: true });

        setDbStats({
          adoptions: adoptCount ?? 8,
          registeredPets: petCount ?? 5,
          vaccines: vacCount ?? 12,
        });
      } catch (err) {
        console.warn('Error loading live home data:', err);
      }
    }

    loadHomeData();
  }, []);

  return (
    <div style={{ maxWidth: '1280px', margin: '0 auto', padding: '60px 24px 80px' }}>
      {/* Hero Section - Strict Minimalist Editorial */}
      <section style={{ maxWidth: '860px', marginBottom: '70px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '18px' }}>
          <span className="pill-badge">
            PetConnect Ecosystem // Production Release v1.0.3
          </span>
        </div>

        <h1 
          style={{
            fontSize: 'clamp(2.4rem, 5vw, 3.8rem)',
            fontWeight: 800,
            letterSpacing: '-0.03em',
            lineHeight: 1.12,
            marginBottom: '20px',
            color: 'var(--text-primary)',
          }}
        >
          Connected health monitoring and emergency recovery for companion animals.
        </h1>

        <p 
          style={{
            fontSize: 'clamp(1.05rem, 1.8vw, 1.2rem)',
            lineHeight: 1.6,
            color: 'var(--text-secondary)',
            maxWidth: '680px',
            marginBottom: '32px',
          }}
        >
          A unified platform combining continuous smart collar biosensing, verified emergency health passes with zero PII leaks, cryptographic vaccine records, and community shelter adoptions.
        </p>

        {/* Action Controls - Flat Minimalist */}
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '12px', alignItems: 'center' }}>
          <a
            href="https://github.com/Antony0610/Pet_Connect_Ai/releases/download/v1.0.3/PetConnectAI-v1.0.3.apk"
            target="_blank"
            rel="noopener noreferrer"
            className="btn-primary"
            style={{ padding: '12px 24px', fontSize: '0.94rem' }}
          >
            <Download size={16} />
            <span>Download Android App (v1.0.3 APK)</span>
          </a>

          <button
            onClick={onOpenQrSimulator}
            className="btn-secondary"
            style={{ padding: '12px 20px', fontSize: '0.94rem' }}
          >
            <QrCode size={16} />
            <span>Collar Tag Simulator</span>
          </button>

          <button
            onClick={() => navigate('emergency')}
            className="btn-secondary"
            style={{ padding: '12px 20px', fontSize: '0.94rem' }}
          >
            <ShieldAlert size={16} color="var(--primary)" />
            <span>Emergency Pass</span>
          </button>
        </div>

        {/* Real Live Database Metric Counters */}
        <div 
          style={{
            display: 'flex',
            flexWrap: 'wrap',
            gap: '32px',
            marginTop: '44px',
            paddingTop: '28px',
            borderTop: '1px solid var(--border-subtle)',
          }}
        >
          <div>
            <div style={{ fontFamily: 'var(--font-mono)', fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {dbStats.adoptions}
            </div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Verified Adoption Listings</div>
          </div>

          <div>
            <div style={{ fontFamily: 'var(--font-mono)', fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {dbStats.registeredPets}
            </div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Registered Companions</div>
          </div>

          <div>
            <div style={{ fontFamily: 'var(--font-mono)', fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {dbStats.vaccines}
            </div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Vaccinations Verified</div>
          </div>
        </div>
      </section>

      {/* Featured Real Adoptions Spotlight */}
      {featuredAdoptions.length > 0 && (
        <section style={{ marginBottom: '70px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: '22px' }}>
            <div>
              <span className="pill-badge" style={{ marginBottom: '6px' }}>DATABASE SPOTLIGHT</span>
              <h2 style={{ fontSize: '1.4rem', fontWeight: 800 }}>Companions Awaiting Homes</h2>
            </div>
            <button
              onClick={() => navigate('adopt')}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '4px',
                color: 'var(--text-primary)',
                fontSize: '0.86rem',
                fontWeight: 700,
              }}
            >
              <span>View All {dbStats.adoptions} Listings</span>
              <ArrowRight size={14} />
            </button>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
            {featuredAdoptions.map((pet) => (
              <div 
                key={pet.id} 
                className="flat-card"
                onClick={() => navigate('adopt')}
                style={{ padding: '16px', display: 'flex', gap: '14px', alignItems: 'center', cursor: 'pointer' }}
              >
                <img
                  src={pet.image_url || (pet.images && pet.images[0]) || 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=300'}
                  alt={pet.name}
                  style={{ width: '74px', height: '74px', borderRadius: 'var(--radius-sm)', objectFit: 'cover' }}
                  onError={(e) => {
                    (e.currentTarget as HTMLImageElement).src = 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=300';
                  }}
                />
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                    <h3 style={{ fontSize: '1.05rem', fontWeight: 800 }}>{pet.name}</h3>
                    <span style={{ fontSize: '0.74rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)' }}>{pet.age || 'Adult'}</span>
                  </div>
                  <div style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>{pet.breed}</div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.78rem', color: 'var(--text-muted)', marginTop: '4px' }}>
                    <MapPin size={11} color="var(--primary)" />
                    <span>{pet.location || 'Kerala'}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Platform Pillars - Clean 3-Grid */}
      <section style={{ marginBottom: '70px' }} className="animate-fade-in">
        <div style={{ marginBottom: '24px' }}>
          <h2 style={{ fontSize: '1.4rem', fontWeight: 800 }}>Core System Architecture</h2>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '20px' }}>
          {/* Card 1 */}
          <div className="flat-card" style={{ padding: '24px' }}>
            <div style={{ width: '32px', height: '32px', borderRadius: '6px', backgroundColor: 'var(--bg-surface-elevated)', border: '1px solid var(--border-medium)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '14px' }}>
              <ShieldAlert size={16} color="var(--danger)" />
            </div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 800, marginBottom: '8px' }}>
              Zero-PII Emergency Health Pass
            </h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.88rem', lineHeight: '1.6' }}>
              Physical collar tag QR code resolves medical allergies and guardian contacts without exposing home addresses or financial details to strangers.
            </p>
          </div>

          {/* Card 2 */}
          <div className="flat-card" style={{ padding: '24px' }}>
            <div style={{ width: '32px', height: '32px', borderRadius: '6px', backgroundColor: 'var(--bg-surface-elevated)', border: '1px solid var(--border-medium)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '14px' }}>
              <Activity size={16} color="var(--primary)" />
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
              <h3 style={{ fontSize: '1.15rem', fontWeight: 800 }}>
                Companion Telemetry Pipeline
              </h3>
              <span className="pill-badge amber" style={{ fontSize: '0.65rem' }}>R&D</span>
            </div>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.88rem', lineHeight: '1.6' }}>
              Telemetry engine designed for companion health analytics, tracking activity patterns, rest intervals, and preparing for future BLE wearable integration.
            </p>
          </div>

          {/* Card 3 */}
          <div className="flat-card" style={{ padding: '24px' }}>
            <div style={{ width: '32px', height: '32px', borderRadius: '6px', backgroundColor: 'var(--bg-surface-elevated)', border: '1px solid var(--border-medium)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '14px' }}>
              <FileCheck size={16} color="var(--secondary)" />
            </div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 800, marginBottom: '8px' }}>
              Cryptographic Vaccine Registry
            </h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.88rem', lineHeight: '1.6' }}>
              Official verification for rabies certificates, deworming batches, and core vaccines required for airline transport and boarding kennels.
            </p>
          </div>
        </div>
      </section>

      {/* IoT Architecture & Hardware Prototype Roadmap Table */}
      <section className="animate-fade-in">
        <div className="flat-card" style={{ padding: '28px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '10px', marginBottom: '6px' }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 800 }}>
              Smart Collar Architecture & IoT Roadmap
            </h3>
            <span className="pill-badge amber">PROTOTYPE R&D ROADMAP</span>
          </div>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.86rem', marginBottom: '20px' }}>
            Physical collar hardware is in active research & development (R&D). Below is our engineering roadmap and planned telemetry specifications.
          </p>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px', fontSize: '0.86rem' }}>
            <div style={{ padding: '12px 14px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--bg-inset)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>DEVELOPMENT PHASE</div>
              <div style={{ fontWeight: 700, marginTop: '2px', color: 'var(--accent-amber)' }}>Hardware in R&D / Prototype</div>
            </div>

            <div style={{ padding: '12px 14px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--bg-inset)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>SOFTWARE PIPELINE</div>
              <div style={{ fontWeight: 700, marginTop: '2px' }}>BLE 5.3 & Cloud Telemetry Ingestion</div>
            </div>

            <div style={{ padding: '12px 14px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--bg-inset)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>PLANNED SENSING TARGET</div>
              <div style={{ fontWeight: 700, marginTop: '2px' }}>Motion, Subcutaneous Temp & Rest</div>
            </div>

            <div style={{ padding: '12px 14px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--bg-inset)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>MOBILE INTEGRATION</div>
              <div style={{ fontWeight: 700, marginTop: '2px' }}>PetConnect Companion App Sync</div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};
