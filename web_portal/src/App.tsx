import React, { useState, useEffect } from 'react';
import { Navbar } from './components/Navbar';
import { Footer } from './components/Footer';
import { QrSimulatorModal } from './components/QrSimulatorModal';
import { HomePage } from './pages/HomePage';
import { EmergencyPage } from './pages/EmergencyPage';
import { MissingPetsPage } from './pages/MissingPetsPage';
import { AdoptionPage } from './pages/AdoptionPage';
import { VerifyPage } from './pages/VerifyPage';

export function App() {
  const [currentRoute, setCurrentRoute] = useState<string>('home');
  const [routeId, setRouteId] = useState<string>('');
  const [isQrModalOpen, setIsQrModalOpen] = useState(false);

  // Initialize route from URL pathname / hash / search
  useEffect(() => {
    const handleLocationChange = () => {
      const rawPath = window.location.pathname;
      const path = rawPath.toLowerCase();
      const hash = window.location.hash.toLowerCase();
      const searchParams = new URLSearchParams(window.location.search);

      // Extract parameter ID from query ?id=... or from path segment /section/:id
      let id = searchParams.get('id') || '';
      const segments = rawPath.split('/').filter(Boolean);
      if (!id && segments.length > 1) {
        const last = segments[segments.length - 1];
        if (!['emergency', 'missing', 'adopt', 'verify', 'vaccine', 'report', 'passport'].includes(last)) {
          id = last;
        }
      }
      setRouteId(id);

      if (path.includes('/emergency') || path.includes('/passport') || hash.includes('emergency')) {
        setCurrentRoute('emergency');
      } else if (path.includes('/missing') || hash.includes('missing')) {
        setCurrentRoute('missing');
      } else if (path.includes('/adopt') || hash.includes('adopt')) {
        setCurrentRoute('adopt');
      } else if (path.includes('/verify') || hash.includes('verify')) {
        setCurrentRoute('verify');
      } else {
        setCurrentRoute('home');
      }
    };

    handleLocationChange();
    window.addEventListener('popstate', handleLocationChange);
    return () => window.removeEventListener('popstate', handleLocationChange);
  }, []);

  const navigate = (route: string) => {
    setCurrentRoute(route);
    setRouteId('');
    let targetPath = '/';
    if (route === 'emergency') targetPath = '/emergency';
    else if (route === 'missing') targetPath = '/missing';
    else if (route === 'adopt') targetPath = '/adopt';
    else if (route === 'verify') targetPath = '/verify';

    window.history.pushState({}, '', targetPath);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleNavigateEmergency = (petId: string) => {
    setCurrentRoute('emergency');
    setRouteId(petId);
    window.history.pushState({}, '', `/emergency?id=${petId}&demo=true`);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Navbar 
        currentRoute={currentRoute} 
        navigate={navigate} 
        onOpenQrSimulator={() => setIsQrModalOpen(true)} 
      />

      <main style={{ flex: 1 }}>
        {currentRoute === 'home' && (
          <HomePage 
            navigate={navigate} 
            onOpenQrSimulator={() => setIsQrModalOpen(true)} 
          />
        )}
        {currentRoute === 'emergency' && (
          <EmergencyPage navigate={navigate} routeId={routeId} />
        )}
        {currentRoute === 'missing' && (
          <MissingPetsPage navigate={navigate} routeId={routeId} />
        )}
        {currentRoute === 'adopt' && (
          <AdoptionPage navigate={navigate} routeId={routeId} />
        )}
        {currentRoute === 'verify' && (
          <VerifyPage navigate={navigate} routeId={routeId} />
        )}
      </main>

      <Footer navigate={navigate} />

      <QrSimulatorModal
        isOpen={isQrModalOpen}
        onClose={() => setIsQrModalOpen(false)}
        onNavigateEmergency={handleNavigateEmergency}
      />
    </div>
  );
}
