import React from 'react';
import { Activity, ShieldCheck, ArrowUpRight } from 'lucide-react';

interface FooterProps {
  navigate: (route: string) => void;
}

export const Footer: React.FC<FooterProps> = ({ navigate }) => {
  return (
    <footer 
      style={{
        marginTop: 'auto',
        borderTop: '1px solid var(--border-subtle)',
        backgroundColor: 'var(--bg-canvas)',
        padding: '50px 24px 32px',
        color: 'var(--text-secondary)',
      }}
    >
      <div 
        style={{
          maxWidth: '1280px',
          margin: '0 auto',
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
          gap: '40px',
          marginBottom: '40px',
        }}
      >
        {/* Brand & Description */}
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '14px' }}>
            <div 
              style={{
                width: '28px',
                height: '28px',
                borderRadius: '6px',
                backgroundColor: 'var(--bg-surface-elevated)',
                border: '1px solid var(--border-medium)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'var(--text-primary)',
              }}
            >
              <Activity size={15} />
            </div>
            <span style={{ 
              fontFamily: 'var(--font-display)', 
              fontSize: '1.1rem', 
              fontWeight: 800, 
              color: 'var(--text-primary)' 
            }}>
              PetConnect
            </span>
          </div>
          <p style={{ fontSize: '0.88rem', lineHeight: '1.6', color: 'var(--text-muted)', marginBottom: '16px' }}>
            Connected health monitoring, verified emergency passes, and community lost pet network.
          </p>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <div style={{ 
              width: '6px', 
              height: '6px', 
              borderRadius: '50%', 
              backgroundColor: 'var(--primary)'
            }} />
            <span style={{ fontSize: '0.78rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)' }}>
              Supabase Cloud Connected
            </span>
          </div>
        </div>

        {/* Directory Links */}
        <div>
          <h4 style={{ color: 'var(--text-primary)', fontSize: '0.86rem', fontWeight: 700, marginBottom: '14px', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
            PORTAL SERVICES
          </h4>
          <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '0.88rem' }}>
            <li>
              <a 
                onClick={() => navigate('emergency')} 
                style={{ cursor: 'pointer', transition: 'color var(--transition-fast)' }}
                onMouseEnter={(e) => e.currentTarget.style.color = 'var(--text-primary)'}
                onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-secondary)'}
              >
                Emergency Health Pass (QR Scan)
              </a>
            </li>
            <li>
              <a 
                onClick={() => navigate('missing')} 
                style={{ cursor: 'pointer', transition: 'color var(--transition-fast)' }}
                onMouseEnter={(e) => e.currentTarget.style.color = 'var(--text-primary)'}
                onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-secondary)'}
              >
                Lost Pet Community Radar
              </a>
            </li>
            <li>
              <a 
                onClick={() => navigate('adopt')} 
                style={{ cursor: 'pointer', transition: 'color var(--transition-fast)' }}
                onMouseEnter={(e) => e.currentTarget.style.color = 'var(--text-primary)'}
                onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-secondary)'}
              >
                Adoption Directory
              </a>
            </li>
            <li>
              <a 
                onClick={() => navigate('verify')} 
                style={{ cursor: 'pointer', transition: 'color var(--transition-fast)' }}
                onMouseEnter={(e) => e.currentTarget.style.color = 'var(--text-primary)'}
                onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-secondary)'}
              >
                Vaccine & Rabies Registry
              </a>
            </li>
          </ul>
        </div>

        {/* Repository & App */}
        <div>
          <h4 style={{ color: 'var(--text-primary)', fontSize: '0.86rem', fontWeight: 700, marginBottom: '14px', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
            RESOURCES
          </h4>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            <a
              href="https://github.com/Antony0610/Pet_Connect_Ai/releases/download/v1.0.2/PetConnectAI-v1.0.2.apk"
              target="_blank"
              rel="noopener noreferrer"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                color: 'var(--text-secondary)',
                fontSize: '0.88rem',
                transition: 'color var(--transition-fast)',
              }}
              onMouseEnter={(e) => e.currentTarget.style.color = 'var(--text-primary)'}
              onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-secondary)'}
            >
              <span>Download Android APK (v1.0.2)</span>
              <ArrowUpRight size={14} />
            </a>

            <a
              href="https://github.com/Antony0610/Pet_Connect_Ai"
              target="_blank"
              rel="noopener noreferrer"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                color: 'var(--text-secondary)',
                fontSize: '0.88rem',
                transition: 'color var(--transition-fast)',
              }}
              onMouseEnter={(e) => e.currentTarget.style.color = 'var(--text-primary)'}
              onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-secondary)'}
            >
              <span>GitHub Repository</span>
              <ArrowUpRight size={14} />
            </a>
          </div>
        </div>
      </div>

      {/* Bottom Bar */}
      <div 
        style={{
          maxWidth: '1280px',
          margin: '0 auto',
          paddingTop: '20px',
          borderTop: '1px solid var(--border-subtle)',
          display: 'flex',
          flexWrap: 'wrap',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '12px',
          fontSize: '0.8rem',
          color: 'var(--text-muted)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <ShieldCheck size={14} />
          <span>PetConnect AI • Zero-PII Sovereign Emergency Verification</span>
        </div>
        <div>
          <span>ISO 11784/11785 Microchip Compatible</span>
        </div>
      </div>
    </footer>
  );
};
