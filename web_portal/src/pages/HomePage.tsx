import React, { useState, useEffect } from 'react';
import { 
  Activity, 
  ShieldAlert, 
  Radio, 
  HeartHandshake, 
  FileCheck, 
  Download, 
  Sparkles, 
  ArrowRight, 
  Zap, 
  Cpu, 
  Heart, 
  MapPin, 
  QrCode,
  CheckCircle2,
  Clock,
  ShieldCheck,
  Stethoscope,
  TrendingUp,
  Flame,
  Layers
} from 'lucide-react';

interface HomePageProps {
  navigate: (route: string) => void;
  onOpenQrSimulator: () => void;
}

export const HomePage: React.FC<HomePageProps> = ({ navigate, onOpenQrSimulator }) => {
  const [ecgPoints, setEcgPoints] = useState<number[]>([40, 42, 38, 41, 75, 12, 58, 39, 41, 40]);
  const [liveBpm, setLiveBpm] = useState(84);
  const [activeTelemetryTab, setActiveTelemetryTab] = useState<'vitals' | 'gps' | 'activity'>('vitals');

  // Simulated live ECG pulse heartbeat
  useEffect(() => {
    const interval = setInterval(() => {
      setLiveBpm(prev => {
        const delta = Math.floor(Math.random() * 5) - 2;
        return Math.min(95, Math.max(76, prev + delta));
      });
    }, 2500);
    return () => clearInterval(interval);
  }, []);

  return (
    <div style={{ position: 'relative', overflow: 'hidden' }}>
      {/* Hero Section */}
      <section 
        style={{
          maxWidth: '1280px',
          margin: '0 auto',
          padding: '80px 24px 70px',
          display: 'grid',
          gridTemplateColumns: '1fr',
          gap: '60px',
          alignItems: 'center',
        }}
        className="hero-grid"
      >
        <div>
          {/* Status Badge */}
          <div 
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '10px',
              padding: '6px 14px',
              borderRadius: 'var(--radius-full)',
              background: 'rgba(16, 185, 129, 0.12)',
              border: '1px solid rgba(16, 185, 129, 0.3)',
              marginBottom: '24px',
            }}
          >
            <span style={{ 
              width: '8px', 
              height: '8px', 
              borderRadius: '50%', 
              backgroundColor: 'var(--primary)',
              boxShadow: '0 0 10px var(--primary)',
              animation: 'pulseGlow 2s infinite'
            }} />
            <span style={{ 
              fontSize: '0.82rem', 
              fontFamily: 'var(--font-mono)', 
              fontWeight: 600, 
              color: 'var(--primary)',
              letterSpacing: '0.02em'
            }}>
              GEMINI 3.7 SUB-SECOND VET TRIAGE • ZERO-PII ARCHITECTURE
            </span>
          </div>

          {/* Main Display Headline */}
          <h1 
            style={{
              fontSize: 'clamp(2.5rem, 5.2vw, 4.2rem)',
              fontWeight: 900,
              letterSpacing: '-0.035em',
              lineHeight: 1.08,
              marginBottom: '24px',
            }}
          >
            The Autonomous Care OS for <span className="gradient-accent-text">Companion Animals.</span>
          </h1>

          <p 
            style={{
              fontSize: 'clamp(1.05rem, 1.8vw, 1.25rem)',
              lineHeight: 1.6,
              color: 'var(--text-secondary)',
              maxWidth: '620px',
              marginBottom: '36px',
            }}
          >
            PetConnect AI fuses continuous smart collar telemetry, sub-second multimodal clinical triage powered by Google Gemini, tamper-evident emergency QR passes, and real-time community lost pet radar.
          </p>

          {/* CTA Group */}
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '14px', alignItems: 'center' }}>
            <a
              href="https://github.com/Antony0610/Pet_Connect_Ai/releases/download/v1.0.2/PetConnectAI-v1.0.2.apk"
              target="_blank"
              rel="noopener noreferrer"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '10px',
                padding: '14px 28px',
                borderRadius: '12px',
                background: 'linear-gradient(135deg, var(--primary) 0%, #059669 100%)',
                color: '#FFFFFF',
                fontSize: '0.96rem',
                fontWeight: 700,
                boxShadow: '0 8px 24px rgba(16, 185, 129, 0.35)',
                transition: 'all var(--transition-fast)',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'translateY(-2px)';
                e.currentTarget.style.boxShadow = '0 12px 32px rgba(16, 185, 129, 0.45)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0px)';
                e.currentTarget.style.boxShadow = '0 8px 24px rgba(16, 185, 129, 0.35)';
              }}
            >
              <Download size={18} />
              <span>Download Mobile App (v1.0.2 APK)</span>
            </a>

            <button
              onClick={onOpenQrSimulator}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '8px',
                padding: '14px 22px',
                borderRadius: '12px',
                backgroundColor: 'rgba(255, 255, 255, 0.06)',
                border: '1px solid var(--border-medium)',
                color: 'var(--text-primary)',
                fontSize: '0.94rem',
                fontWeight: 600,
                transition: 'all var(--transition-fast)',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = 'rgba(255, 255, 255, 0.1)';
                e.currentTarget.style.borderColor = 'var(--primary)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = 'rgba(255, 255, 255, 0.06)';
                e.currentTarget.style.borderColor = 'var(--border-medium)';
              }}
            >
              <QrCode size={18} color="var(--primary)" />
              <span>Simulate Collar QR Tag</span>
            </button>

            <button
              onClick={() => navigate('missing')}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '8px',
                padding: '14px 20px',
                borderRadius: '12px',
                backgroundColor: 'transparent',
                color: 'var(--text-secondary)',
                fontSize: '0.94rem',
                fontWeight: 600,
              }}
            >
              <Radio size={17} color="#38BDF8" />
              <span>Live Lost Pet Radar</span>
              <ArrowRight size={15} />
            </button>
          </div>

          {/* Quick Metrics */}
          <div 
            style={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: '28px',
              marginTop: '48px',
              paddingTop: '32px',
              borderTop: '1px solid var(--border-subtle)',
            }}
          >
            <div>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: '1.6rem', fontWeight: 800, color: 'var(--primary)' }}>
                &lt; 1.2s
              </div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>AI Clinical Triage Latency</div>
            </div>
            <div>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: '1.6rem', fontWeight: 800, color: 'var(--secondary)' }}>
                100%
              </div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Zero-PII Privacy Protection</div>
            </div>
            <div>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: '1.6rem', fontWeight: 800, color: 'var(--accent-amber)' }}>
                24 / 7
              </div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Autonomous Collar Telemetry</div>
            </div>
          </div>
        </div>

        {/* Hero Visual: Interactive Smart Collar Telemetry Bento */}
        <div 
          className="glass-panel"
          style={{
            padding: '28px',
            position: 'relative',
            overflow: 'hidden',
          }}
        >
          {/* Top Pill Header */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <div 
                style={{
                  width: '10px',
                  height: '10px',
                  borderRadius: '50%',
                  backgroundColor: 'var(--primary)',
                  boxShadow: '0 0 12px var(--primary)',
                }}
              />
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-primary)' }}>
                COLLAR-NODE // PC-NEXUS-09
              </span>
            </div>
            <div style={{ display: 'flex', gap: '6px' }}>
              {(['vitals', 'gps', 'activity'] as const).map(tab => (
                <button
                  key={tab}
                  onClick={() => setActiveTelemetryTab(tab)}
                  style={{
                    padding: '4px 10px',
                    borderRadius: '6px',
                    fontSize: '0.75rem',
                    fontWeight: 600,
                    textTransform: 'uppercase',
                    fontFamily: 'var(--font-mono)',
                    backgroundColor: activeTelemetryTab === tab ? 'rgba(16, 185, 129, 0.2)' : 'transparent',
                    color: activeTelemetryTab === tab ? 'var(--primary)' : 'var(--text-muted)',
                    border: activeTelemetryTab === tab ? '1px solid rgba(16, 185, 129, 0.4)' : '1px solid transparent',
                  }}
                >
                  {tab}
                </button>
              ))}
            </div>
          </div>

          {/* Telemetry Tab Content */}
          {activeTelemetryTab === 'vitals' && (
            <div>
              {/* Pet Quick Profile */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginBottom: '20px' }}>
                <img
                  src="https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=120&q=80"
                  alt="Buddy"
                  style={{
                    width: '54px',
                    height: '54px',
                    borderRadius: '50%',
                    objectFit: 'cover',
                    border: '2px solid var(--primary)',
                  }}
                />
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <h3 style={{ fontSize: '1.15rem', fontWeight: 800 }}>Buddy</h3>
                    <span style={{
                      fontSize: '0.68rem',
                      fontFamily: 'var(--font-mono)',
                      padding: '2px 6px',
                      borderRadius: '4px',
                      backgroundColor: 'rgba(16, 185, 129, 0.15)',
                      color: 'var(--primary)',
                      fontWeight: 700,
                    }}>OPTIMAL</span>
                  </div>
                  <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Golden Retriever • 3 yrs • 28.5 kg</p>
                </div>
              </div>

              {/* Vitals Grid */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '12px', marginBottom: '20px' }}>
                <div style={{ 
                  padding: '14px', 
                  borderRadius: '12px', 
                  backgroundColor: 'rgba(255, 255, 255, 0.03)',
                  border: '1px solid var(--border-subtle)' 
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#EF4444', marginBottom: '4px' }}>
                    <Heart size={15} fill="#EF4444" />
                    <span style={{ fontSize: '0.74rem', fontWeight: 600 }}>HEART RATE (HRV)</span>
                  </div>
                  <div style={{ fontFamily: 'var(--font-mono)', fontSize: '1.45rem', fontWeight: 800 }}>
                    {liveBpm} <span style={{ fontSize: '0.8rem', fontWeight: 500, color: 'var(--text-muted)' }}>BPM</span>
                  </div>
                </div>

                <div style={{ 
                  padding: '14px', 
                  borderRadius: '12px', 
                  backgroundColor: 'rgba(255, 255, 255, 0.03)',
                  border: '1px solid var(--border-subtle)' 
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#06B6D4', marginBottom: '4px' }}>
                    <Flame size={15} />
                    <span style={{ fontSize: '0.74rem', fontWeight: 600 }}>BODY TEMP</span>
                  </div>
                  <div style={{ fontFamily: 'var(--font-mono)', fontSize: '1.45rem', fontWeight: 800 }}>
                    38.6 <span style={{ fontSize: '0.8rem', fontWeight: 500, color: 'var(--text-muted)' }}>°C</span>
                  </div>
                </div>
              </div>

              {/* Real-time Simulated ECG Chart */}
              <div style={{ 
                padding: '14px 18px', 
                borderRadius: '12px', 
                backgroundColor: 'rgba(10, 14, 24, 0.8)',
                border: '1px solid var(--border-subtle)',
                position: 'relative'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                  <span style={{ fontSize: '0.72rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)' }}>
                    CONTINUOUS ECG WAVEFORM
                  </span>
                  <span style={{ fontSize: '0.72rem', fontFamily: 'var(--font-mono)', color: 'var(--primary)' }}>
                    R-R INTERVAL: 712ms
                  </span>
                </div>
                {/* SVG ECG Waveform */}
                <svg width="100%" height="45" viewBox="0 0 300 45" fill="none" style={{ overflow: 'visible' }}>
                  <path
                    d="M 0 25 L 30 25 L 45 23 L 55 25 L 75 25 L 85 8 L 95 38 L 105 25 L 140 25 L 155 23 L 165 25 L 185 25 L 195 6 L 205 40 L 215 25 L 250 25 L 270 23 L 300 25"
                    stroke="var(--primary)"
                    strokeWidth="2.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </div>
            </div>
          )}

          {activeTelemetryTab === 'gps' && (
            <div style={{ padding: '10px 0' }}>
              <div style={{
                height: '180px',
                borderRadius: '12px',
                backgroundColor: '#0c1220',
                border: '1px solid var(--border-subtle)',
                position: 'relative',
                overflow: 'hidden',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}>
                {/* Simulated Geofence Ring */}
                <div style={{
                  width: '130px',
                  height: '130px',
                  borderRadius: '50%',
                  border: '2px dashed rgba(16, 185, 129, 0.6)',
                  position: 'absolute',
                  animation: 'pulseGlow 3s infinite',
                }} />
                {/* Radar sweep */}
                <div style={{
                  width: '160px',
                  height: '160px',
                  borderRadius: '50%',
                  border: '1px solid rgba(6, 182, 212, 0.3)',
                  position: 'absolute',
                }} />
                <div style={{
                  width: '18px',
                  height: '18px',
                  borderRadius: '50%',
                  backgroundColor: 'var(--primary)',
                  boxShadow: '0 0 15px var(--primary)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  zIndex: 2,
                }}>
                  <MapPin size={12} color="#FFFFFF" />
                </div>
                <div style={{
                  position: 'absolute',
                  bottom: '10px',
                  left: '12px',
                  fontSize: '0.72rem',
                  fontFamily: 'var(--font-mono)',
                  color: 'var(--primary)',
                }}>
                  GPS: SAFE ZONE (HOME GEOFENCE ACTIVE)
                </div>
              </div>
            </div>
          )}

          {activeTelemetryTab === 'activity' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Daily Movement Goal</span>
                <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, color: 'var(--primary)' }}>84%</span>
              </div>
              <div style={{ height: '8px', borderRadius: '4px', backgroundColor: 'rgba(255,255,255,0.08)', overflow: 'hidden' }}>
                <div style={{ width: '84%', height: '100%', background: 'linear-gradient(90deg, var(--primary), var(--secondary))' }} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '8px', marginTop: '10px' }}>
                <div style={{ textAlign: 'center', padding: '10px', background: 'rgba(255,255,255,0.02)', borderRadius: '8px' }}>
                  <div style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: '1.1rem' }}>9,410</div>
                  <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Steps</div>
                </div>
                <div style={{ textAlign: 'center', padding: '10px', background: 'rgba(255,255,255,0.02)', borderRadius: '8px' }}>
                  <div style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: '1.1rem' }}>4.8 km</div>
                  <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Distance</div>
                </div>
                <div style={{ textAlign: 'center', padding: '10px', background: 'rgba(255,255,255,0.02)', borderRadius: '8px' }}>
                  <div style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: '1.1rem' }}>410 kcal</div>
                  <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Active Burn</div>
                </div>
              </div>
            </div>
          )}

          {/* Quick Action Footer in Hero Card */}
          <div style={{ 
            marginTop: '20px', 
            paddingTop: '16px', 
            borderTop: '1px solid var(--border-subtle)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between'
          }}>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
              Encrypted Telemetry via BLE 5.3 & LTE-M
            </span>
            <button
              onClick={() => navigate('emergency')}
              style={{
                fontSize: '0.8rem',
                fontWeight: 700,
                color: 'var(--primary)',
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
              }}
            >
              <span>View Emergency Pass</span>
              <ArrowRight size={14} />
            </button>
          </div>
        </div>
      </section>

      {/* Feature Bento Grid */}
      <section style={{ maxWidth: '1280px', margin: '0 auto', padding: '60px 24px 80px' }}>
        <div style={{ textAlign: 'center', marginBottom: '50px' }}>
          <h2 style={{ fontSize: 'clamp(1.8rem, 3.5vw, 2.8rem)', marginBottom: '14px' }}>
            Engineered For Clinical Precision. Zero Generic Fluff.
          </h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '1.05rem', maxWidth: '640px', margin: '0 auto' }}>
            Built by veterinary technologists and systems engineers to eliminate the flaws of traditional microchips and fragmented vet clinics.
          </p>
        </div>

        <div 
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
            gap: '24px',
          }}
        >
          {/* Card 1: Gemini Multimodal Triage */}
          <div className="glass-panel" style={{ padding: '32px' }}>
            <div style={{
              width: '44px',
              height: '44px',
              borderRadius: '12px',
              backgroundColor: 'rgba(16, 185, 129, 0.15)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'var(--primary)',
              marginBottom: '20px',
            }}>
              <Stethoscope size={22} />
            </div>
            <h3 style={{ fontSize: '1.3rem', fontWeight: 700, marginBottom: '10px' }}>
              Sub-Second Clinical Triage
            </h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.92rem', lineHeight: '1.6', marginBottom: '16px' }}>
              Powered by fine-tuned Gemini models with strict <code>thinkingBudget: 0</code> latency optimization and automatic circuit breakers. Evaluates dermatological rashes, corneal injuries, toxic exposures, and acute distress in under 1.2s.
            </p>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.82rem', color: 'var(--primary)', fontWeight: 600 }}>
              <Zap size={14} />
              <span>WSAVA Guidelines Compliant</span>
            </div>
          </div>

          {/* Card 2: Sovereign Emergency QR Pass */}
          <div className="glass-panel" style={{ padding: '32px' }}>
            <div style={{
              width: '44px',
              height: '44px',
              borderRadius: '12px',
              backgroundColor: 'rgba(239, 68, 68, 0.15)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#EF4444',
              marginBottom: '20px',
            }}>
              <ShieldAlert size={22} />
            </div>
            <h3 style={{ fontSize: '1.3rem', fontWeight: 700, marginBottom: '10px' }}>
              Zero-PII Emergency Health Pass
            </h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.92rem', lineHeight: '1.6', marginBottom: '16px' }}>
              Scannable by any smartphone camera with no app installation required. Presents verified microchip data, drug allergies, and one-tap emergency calling without leaking private home addresses or billing records.
            </p>
            <div 
              onClick={() => navigate('emergency')}
              style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.82rem', color: '#EF4444', fontWeight: 600, cursor: 'pointer' }}
            >
              <span>Test Emergency Pass Scan</span>
              <ArrowRight size={14} />
            </div>
          </div>

          {/* Card 3: Real-Time Lost Pet Radar */}
          <div className="glass-panel" style={{ padding: '32px' }}>
            <div style={{
              width: '44px',
              height: '44px',
              borderRadius: '12px',
              backgroundColor: 'rgba(6, 182, 212, 0.15)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'var(--secondary)',
              marginBottom: '20px',
            }}>
              <Radio size={22} />
            </div>
            <h3 style={{ fontSize: '1.3rem', fontWeight: 700, marginBottom: '10px' }}>
              Community Geofence Radar
            </h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.92rem', lineHeight: '1.6', marginBottom: '16px' }}>
              Instant broadcast activation when a pet slips the collar perimeter. Notifies nearby registered pet owners within a 5-mile radius, integrates live GPS coordinate pings, and displays sightings on an interactive radar.
            </p>
            <div 
              onClick={() => navigate('missing')}
              style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.82rem', color: 'var(--secondary)', fontWeight: 600, cursor: 'pointer' }}
            >
              <span>Open Missing Pet Radar</span>
              <ArrowRight size={14} />
            </div>
          </div>
        </div>
      </section>

      {/* Comparison Table: Traditional Tag vs PetConnect AI */}
      <section style={{ maxWidth: '1000px', margin: '0 auto', padding: '0 24px 80px' }}>
        <div className="glass-panel" style={{ padding: '36px', overflowX: 'auto' }}>
          <h3 style={{ fontSize: '1.4rem', fontWeight: 800, marginBottom: '8px' }}>
            Why Traditional Metal Tags Fail Pets
          </h3>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', marginBottom: '24px' }}>
            A comparative overview of legacy pet identification versus PetConnect AI sovereign passports.
          </p>

          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: '550px' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border-medium)', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                <th style={{ padding: '12px 16px' }}>FEATURE / CAPABILITY</th>
                <th style={{ padding: '12px 16px' }}>ENGRAVED METAL TAG</th>
                <th style={{ padding: '12px 16px', color: 'var(--primary)' }}>PETCONNECT AI PASS</th>
              </tr>
            </thead>
            <tbody style={{ fontSize: '0.9rem' }}>
              <tr style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                <td style={{ padding: '14px 16px', fontWeight: 600 }}>Emergency Contact Updatability</td>
                <td style={{ padding: '14px 16px', color: 'var(--text-muted)' }}>Requires buying a new tag</td>
                <td style={{ padding: '14px 16px', color: 'var(--primary)', fontWeight: 600 }}>Instant cloud sync in 1 tap</td>
              </tr>
              <tr style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                <td style={{ padding: '14px 16px', fontWeight: 600 }}>Critical Allergies & Medication Alerts</td>
                <td style={{ padding: '14px 16px', color: 'var(--text-muted)' }}>Zero space (2-3 lines max)</td>
                <td style={{ padding: '14px 16px', color: 'var(--primary)', fontWeight: 600 }}>Full veterinary dosage profile</td>
              </tr>
              <tr style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                <td style={{ padding: '14px 16px', fontWeight: 600 }}>Zero-PII Privacy Protection</td>
                <td style={{ padding: '14px 16px', color: '#EF4444' }}>Exposes home address publicly</td>
                <td style={{ padding: '14px 16px', color: 'var(--primary)', fontWeight: 600 }}>Sanitized proxy contact gate</td>
              </tr>
              <tr style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                <td style={{ padding: '14px 16px', fontWeight: 600 }}>Scan Notification for Owner</td>
                <td style={{ padding: '14px 16px', color: 'var(--text-muted)' }}>None (Passive piece of metal)</td>
                <td style={{ padding: '14px 16px', color: 'var(--primary)', fontWeight: 600 }}>Instant push alert with scan time</td>
              </tr>
              <tr>
                <td style={{ padding: '14px 16px', fontWeight: 600 }}>AI Veterinary Triage on Scan</td>
                <td style={{ padding: '14px 16px', color: 'var(--text-muted)' }}>Impossible</td>
                <td style={{ padding: '14px 16px', color: 'var(--primary)', fontWeight: 600 }}>Embedded Gemini 3.7 fast triage</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      {/* Responsive Media Query */}
      <style>{`
        @media (min-width: 960px) {
          .hero-grid {
            grid-template-columns: 1.15fr 0.85fr !important;
          }
        }
      `}</style>
    </div>
  );
};
