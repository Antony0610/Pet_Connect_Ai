import React from 'react';
import { Activity, ShieldCheck, Heart, ArrowUpRight } from 'lucide-react';

interface FooterProps {
  navigate: (route: string) => void;
}

export const Footer: React.FC<FooterProps> = ({ navigate }) => {
  return (
    <footer 
      style={{
        marginTop: 'auto',
        borderTop: '1px solid var(--border-subtle)',
        backgroundColor: 'rgba(8, 10, 16, 0.95)',
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)',
        padding: '60px 24px 36px',
        color: 'var(--text-secondary)',
      }}
    >
      <div 
        style={{
          maxWidth: '1280px',
          margin: '0 auto',
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
          gap: '40px',
          marginBottom: '48px',
        }}
      >
        {/* Col 1: Brand & Mission */}
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '16px' }}>
            <div 
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '10px',
                background: 'linear-gradient(135deg, #10B981 0%, #06B6D4 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Activity size={18} color="#FFFFFF" />
            </div>
            <span style={{ 
              fontFamily: 'var(--font-display)', 
              fontSize: '1.2rem', 
              fontWeight: 800, 
              color: 'var(--text-primary)' 
            }}>
              PetConnect<span style={{ color: 'var(--primary)' }}>AI</span>
            </span>
          </div>
          <p style={{ fontSize: '0.9rem', lineHeight: '1.6', color: 'var(--text-muted)', marginBottom: '18px' }}>
            Autonomous clinical intelligence, continuous smart collar biosensing, and zero-PII emergency passes engineered for animal welfare and immediate lost pet recovery.
          </p>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div style={{ 
              width: '8px', 
              height: '8px', 
              borderRadius: '50%', 
              backgroundColor: 'var(--primary)',
              boxShadow: '0 0 10px var(--primary)' 
            }} />
            <span style={{ fontSize: '0.8rem', fontFamily: 'var(--font-mono)', color: 'var(--primary)' }}>
              All Clinical & Edge Services Operational
            </span>
          </div>
        </div>

        {/* Col 2: Emergency & Identification */}
        <div>
          <h4 style={{ color: 'var(--text-primary)', fontSize: '0.95rem', fontWeight: 700, marginBottom: '16px', letterSpacing: '0.04em' }}>
            IDENTIFICATION & SAFETY
          </h4>
          <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '0.88rem' }}>
            <li>
              <a 
                onClick={() => navigate('emergency')} 
                style={{ cursor: 'pointer', transition: 'color var(--transition-fast)' }}
                onMouseEnter={(e) => e.currentTarget.style.color = 'var(--primary)'}
                onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-secondary)'}
              >
                Emergency Health Pass (QR Scan)
              </a>
            </li>
            <li>
              <a 
                onClick={() => navigate('missing')} 
                style={{ cursor: 'pointer', transition: 'color var(--transition-fast)' }}
                onMouseEnter={(e) => e.currentTarget.style.color = 'var(--primary)'}
                onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-secondary)'}
              >
                Active Lost Pet Radar
              </a>
            </li>
            <li>
              <a 
                onClick={() => navigate('verify')} 
                style={{ cursor: 'pointer', transition: 'color var(--transition-fast)' }}
                onMouseEnter={(e) => e.currentTarget.style.color = 'var(--primary)'}
                onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-secondary)'}
              >
                Rabies & Vaccine Certificate Verification
              </a>
            </li>
            <li>
              <span style={{ color: 'var(--text-muted)', fontSize: '0.82rem' }}>
                ISO 11784/11785 Microchip Standard Compliant
              </span>
            </li>
          </ul>
        </div>

        {/* Col 3: Adoption & Community */}
        <div>
          <h4 style={{ color: 'var(--text-primary)', fontSize: '0.95rem', fontWeight: 700, marginBottom: '16px', letterSpacing: '0.04em' }}>
            ADOPTION & NETWORK
          </h4>
          <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '0.88rem' }}>
            <li>
              <a 
                onClick={() => navigate('adopt')} 
                style={{ cursor: 'pointer', transition: 'color var(--transition-fast)' }}
                onMouseEnter={(e) => e.currentTarget.style.color = 'var(--primary)'}
                onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-secondary)'}
              >
                Verified Animal Shelter Directory
              </a>
            </li>
            <li>
              <span style={{ color: 'var(--text-muted)' }}>
                WSAVA Global Nutrition Guidelines
              </span>
            </li>
            <li>
              <span style={{ color: 'var(--text-muted)' }}>
                Zero-PII Sovereign Privacy Policy
              </span>
            </li>
          </ul>
        </div>

        {/* Col 4: Open Source & Releases */}
        <div>
          <h4 style={{ color: 'var(--text-primary)', fontSize: '0.95rem', fontWeight: 700, marginBottom: '16px', letterSpacing: '0.04em' }}>
            MOBILE CLIENT & REPOSITORY
          </h4>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <a
              href="https://github.com/Antony0610/Pet_Connect_Ai/releases/download/v1.0.2/PetConnectAI-v1.0.2.apk"
              target="_blank"
              rel="noopener noreferrer"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '8px',
                padding: '10px 14px',
                borderRadius: '8px',
                background: 'rgba(255, 255, 255, 0.05)',
                border: '1px solid var(--border-medium)',
                color: 'var(--text-primary)',
                fontSize: '0.86rem',
                fontWeight: 600,
                transition: 'all var(--transition-fast)',
              }}
              onMouseEnter={(e) => e.currentTarget.style.borderColor = 'var(--primary)'}
              onMouseLeave={(e) => e.currentTarget.style.borderColor = 'var(--border-medium)'}
            >
              <span>Download Production APK (v1.0.2)</span>
              <ArrowUpRight size={15} />
            </a>

            <a
              href="https://github.com/Antony0610/Pet_Connect_Ai"
              target="_blank"
              rel="noopener noreferrer"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '8px',
                padding: '10px 14px',
                borderRadius: '8px',
                background: 'rgba(255, 255, 255, 0.05)',
                border: '1px solid var(--border-medium)',
                color: 'var(--text-primary)',
                fontSize: '0.86rem',
                fontWeight: 600,
                transition: 'all var(--transition-fast)',
              }}
              onMouseEnter={(e) => e.currentTarget.style.borderColor = 'var(--primary)'}
              onMouseLeave={(e) => e.currentTarget.style.borderColor = 'var(--border-medium)'}
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5.08-1.25-.27-2.48-1-3.5.28-1.15.28-2.35 0-3.5 0 0-1 0-3 1.5-2.64-.5-5.36-.5-8 0C6 2 5 2 5 2c-.3 1.15-.3 2.35 0 3.5A5.403 5.403 0 0 0 4 9c0 3.5 3 5.5 6 5.5-.39.49-.68 1.05-.85 1.65-.17.6-.22 1.23-.15 1.85v4" />
                <path d="M9 18c-4.51 2-5-2-7-2" />
              </svg>
              <span>GitHub Repository</span>
              <ArrowUpRight size={15} />
            </a>
          </div>
        </div>
      </div>

      {/* Bottom Bar */}
      <div 
        style={{
          maxWidth: '1280px',
          margin: '0 auto',
          paddingTop: '24px',
          borderTop: '1px solid var(--border-subtle)',
          display: 'flex',
          flexWrap: 'wrap',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '16px',
          fontSize: '0.82rem',
          color: 'var(--text-muted)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <ShieldCheck size={16} color="var(--primary)" />
          <span>© 2026 PetConnect AI Ecosystem. Cryptographically verified medical identity records.</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
          <span>Crafted with</span>
          <Heart size={14} color="#EF4444" fill="#EF4444" />
          <span>for pets worldwide</span>
        </div>
      </div>
    </footer>
  );
};
