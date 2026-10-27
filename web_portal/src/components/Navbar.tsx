import React, { useState, useEffect } from 'react';
import { 
  ShieldAlert, 
  Radio, 
  HeartHandshake, 
  FileCheck, 
  Download, 
  Sun, 
  Moon, 
  Menu, 
  X, 
  QrCode,
  Activity,
  Sparkles
} from 'lucide-react';

interface NavbarProps {
  currentRoute: string;
  navigate: (route: string) => void;
  onOpenQrSimulator: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ currentRoute, navigate, onOpenQrSimulator }) => {
  const [theme, setTheme] = useState<'dark' | 'light'>('dark');
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem('petconnect_theme') as 'dark' | 'light' | null;
    const initial = saved || 'dark';
    setTheme(initial);
    document.documentElement.setAttribute('data-theme', initial);

    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const toggleTheme = () => {
    const next = theme === 'dark' ? 'light' : 'dark';
    setTheme(next);
    localStorage.setItem('petconnect_theme', next);
    document.documentElement.setAttribute('data-theme', next);
  };

  const navLinks = [
    { label: 'Platform', route: 'home', icon: Sparkles },
    { label: 'Emergency Pass', route: 'emergency', icon: ShieldAlert, badge: 'LIVE' },
    { label: 'Lost Pet Radar', route: 'missing', icon: Radio, badge: 'RADAR' },
    { label: 'Adoptions', route: 'adopt', icon: HeartHandshake },
    { label: 'Verify Records', route: 'verify', icon: FileCheck },
  ];

  return (
    <header 
      style={{
        position: 'sticky',
        top: 0,
        zIndex: 100,
        width: '100%',
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)',
        backgroundColor: scrolled 
          ? (theme === 'dark' ? 'rgba(8, 10, 16, 0.92)' : 'rgba(248, 250, 249, 0.92)')
          : (theme === 'dark' ? 'rgba(8, 10, 16, 0.75)' : 'rgba(248, 250, 249, 0.75)'),
        borderBottom: `1px solid ${scrolled ? 'var(--border-medium)' : 'var(--border-subtle)'}`,
        transition: 'all var(--transition-smooth)',
      }}
    >
      <div 
        style={{
          maxWidth: '1280px',
          margin: '0 auto',
          padding: '0 24px',
          height: '72px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        {/* Brand Logo */}
        <div 
          onClick={() => navigate('home')}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            cursor: 'pointer',
            userSelect: 'none',
          }}
        >
          <div 
            style={{
              width: '42px',
              height: '42px',
              borderRadius: '12px',
              background: 'linear-gradient(135deg, #10B981 0%, #06B6D4 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 4px 16px rgba(16, 185, 129, 0.35)',
            }}
          >
            <Activity size={22} color="#FFFFFF" strokeWidth={2.6} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ 
                fontFamily: 'var(--font-display)', 
                fontSize: '1.25rem', 
                fontWeight: 800, 
                letterSpacing: '-0.03em',
                color: 'var(--text-primary)'
              }}>
                PetConnect<span style={{ color: 'var(--primary)' }}>AI</span>
              </span>
              <span style={{
                fontSize: '0.65rem',
                fontFamily: 'var(--font-mono)',
                fontWeight: 700,
                padding: '2px 6px',
                borderRadius: '6px',
                background: 'rgba(16, 185, 129, 0.15)',
                color: 'var(--primary)',
                border: '1px solid rgba(16, 185, 129, 0.3)',
              }}>
                v1.0.2
              </span>
            </div>
            <div style={{ 
              fontSize: '0.72rem', 
              color: 'var(--text-muted)', 
              letterSpacing: '0.04em',
              textTransform: 'uppercase',
              fontWeight: 600,
            }}>
              Autonomous Pet Care OS
            </div>
          </div>
        </div>

        {/* Desktop Navigation */}
        <nav 
          style={{
            display: 'none',
            alignItems: 'center',
            gap: '8px',
          }}
          className="desktop-nav"
        >
          {navLinks.map((item) => {
            const isActive = currentRoute === item.route;
            const Icon = item.icon;
            return (
              <button
                key={item.route}
                onClick={() => navigate(item.route)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '8px 14px',
                  borderRadius: '10px',
                  fontSize: '0.88rem',
                  fontWeight: 600,
                  color: isActive ? 'var(--text-highlight)' : 'var(--text-secondary)',
                  backgroundColor: isActive ? 'rgba(255, 255, 255, 0.08)' : 'transparent',
                  border: isActive ? '1px solid var(--border-medium)' : '1px solid transparent',
                  transition: 'all var(--transition-fast)',
                }}
                onMouseEnter={(e) => {
                  if (!isActive) {
                    e.currentTarget.style.color = 'var(--text-primary)';
                    e.currentTarget.style.backgroundColor = 'rgba(255, 255, 255, 0.04)';
                  }
                }}
                onMouseLeave={(e) => {
                  if (!isActive) {
                    e.currentTarget.style.color = 'var(--text-secondary)';
                    e.currentTarget.style.backgroundColor = 'transparent';
                  }
                }}
              >
                <Icon size={16} color={isActive ? 'var(--primary)' : 'currentColor'} />
                <span>{item.label}</span>
                {item.badge && (
                  <span style={{
                    fontSize: '0.62rem',
                    fontFamily: 'var(--font-mono)',
                    padding: '1px 5px',
                    borderRadius: '4px',
                    background: item.badge === 'LIVE' ? 'rgba(239, 68, 68, 0.2)' : 'rgba(6, 182, 212, 0.2)',
                    color: item.badge === 'LIVE' ? '#F87171' : '#38BDF8',
                    border: item.badge === 'LIVE' ? '1px solid rgba(239, 68, 68, 0.4)' : '1px solid rgba(6, 182, 212, 0.4)',
                  }}>
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}
        </nav>

        {/* Action Controls */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          {/* QR Simulator Trigger */}
          <button
            onClick={onOpenQrSimulator}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '8px 14px',
              borderRadius: '10px',
              fontSize: '0.84rem',
              fontWeight: 600,
              background: 'rgba(16, 185, 129, 0.12)',
              color: 'var(--primary)',
              border: '1px solid rgba(16, 185, 129, 0.35)',
              transition: 'all var(--transition-fast)',
            }}
            title="Interactive Collar Tag Simulator"
          >
            <QrCode size={16} />
            <span className="hide-mobile">Test Collar QR</span>
          </button>

          {/* Download APK Link */}
          <a
            href="https://github.com/Antony0610/Pet_Connect_Ai/releases/download/v1.0.2/PetConnectAI-v1.0.2.apk"
            target="_blank"
            rel="noopener noreferrer"
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '8px 16px',
              borderRadius: '10px',
              fontSize: '0.84rem',
              fontWeight: 700,
              background: 'linear-gradient(135deg, var(--primary) 0%, #059669 100%)',
              color: '#FFFFFF',
              boxShadow: '0 4px 14px rgba(16, 185, 129, 0.3)',
              transition: 'all var(--transition-fast)',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-1px)';
              e.currentTarget.style.boxShadow = '0 6px 20px rgba(16, 185, 129, 0.45)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0px)';
              e.currentTarget.style.boxShadow = '0 4px 14px rgba(16, 185, 129, 0.3)';
            }}
          >
            <Download size={15} />
            <span>Get App (APK)</span>
          </a>

          {/* Theme Switcher */}
          <button
            onClick={toggleTheme}
            style={{
              width: '38px',
              height: '38px',
              borderRadius: '10px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              backgroundColor: 'rgba(255, 255, 255, 0.06)',
              border: '1px solid var(--border-subtle)',
              color: 'var(--text-secondary)',
              transition: 'all var(--transition-fast)',
            }}
            aria-label="Toggle visual theme"
          >
            {theme === 'dark' ? <Sun size={17} /> : <Moon size={17} />}
          </button>

          {/* Mobile Menu Toggle */}
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            style={{
              width: '38px',
              height: '38px',
              borderRadius: '10px',
              display: 'none',
              alignItems: 'center',
              justifyContent: 'center',
              backgroundColor: 'rgba(255, 255, 255, 0.06)',
              border: '1px solid var(--border-subtle)',
              color: 'var(--text-primary)',
            }}
            className="mobile-toggle"
            aria-label="Open mobile menu"
          >
            {isMobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
      </div>

      {/* Mobile Drawer */}
      {isMobileMenuOpen && (
        <div 
          style={{
            padding: '16px 24px 24px',
            backgroundColor: theme === 'dark' ? 'rgba(11, 14, 23, 0.98)' : 'rgba(255, 255, 255, 0.98)',
            borderTop: '1px solid var(--border-subtle)',
            display: 'flex',
            flexDirection: 'column',
            gap: '10px',
          }}
        >
          {navLinks.map((item) => {
            const Icon = item.icon;
            const isActive = currentRoute === item.route;
            return (
              <button
                key={item.route}
                onClick={() => {
                  navigate(item.route);
                  setIsMobileMenuOpen(false);
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '12px 16px',
                  borderRadius: '10px',
                  background: isActive ? 'rgba(16, 185, 129, 0.12)' : 'rgba(255, 255, 255, 0.03)',
                  color: isActive ? 'var(--primary)' : 'var(--text-primary)',
                  fontWeight: 600,
                  fontSize: '0.95rem',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <Icon size={18} />
                  <span>{item.label}</span>
                </div>
                {item.badge && (
                  <span style={{
                    fontSize: '0.65rem',
                    fontFamily: 'var(--font-mono)',
                    padding: '2px 6px',
                    borderRadius: '4px',
                    background: item.badge === 'LIVE' ? 'rgba(239, 68, 68, 0.2)' : 'rgba(6, 182, 212, 0.2)',
                    color: item.badge === 'LIVE' ? '#F87171' : '#38BDF8',
                  }}>
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}
        </div>
      )}

      {/* Media query styling for responsive navbar */}
      <style>{`
        @media (min-width: 860px) {
          .desktop-nav {
            display: flex !important;
          }
          .mobile-toggle {
            display: none !important;
          }
        }
        @media (max-width: 859px) {
          .desktop-nav {
            display: none !important;
          }
          .mobile-toggle {
            display: flex !important;
          }
          .hide-mobile {
            display: none !important;
          }
        }
      `}</style>
    </header>
  );
};
