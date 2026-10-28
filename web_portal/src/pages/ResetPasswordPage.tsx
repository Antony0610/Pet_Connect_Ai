import React, { useState, useEffect } from 'react';
import { 
  KeyRound, 
  Lock, 
  Eye, 
  EyeOff, 
  CheckCircle2, 
  AlertCircle, 
  ArrowLeft, 
  Mail, 
  ShieldCheck, 
  Sparkles,
  ExternalLink
} from 'lucide-react';
import confetti from 'canvas-confetti';
import { supabase } from '../lib/supabase';

interface ResetPasswordPageProps {
  navigate: (route: string) => void;
}

export const ResetPasswordPage: React.FC<ResetPasswordPageProps> = ({ navigate }) => {
  const [mode, setMode] = useState<'update' | 'request'>('request');
  const [email, setEmail] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [isUpdated, setIsUpdated] = useState(false);

  // Check for recovery token in URL hash / query / Supabase session
  useEffect(() => {
    const checkRecoverySession = async () => {
      const hash = window.location.hash;
      const search = window.location.search;

      // If hash contains type=recovery or access_token, or search has code
      if (hash.includes('type=recovery') || hash.includes('access_token') || search.includes('code=')) {
        setMode('update');
      }

      // Supabase Auth state listener for PASSWORD_RECOVERY event
      const { data: authListener } = supabase.auth.onAuthStateChange(async (event, session) => {
        if (event === 'PASSWORD_RECOVERY' || (session && hash.includes('type=recovery'))) {
          setMode('update');
        }
      });

      // Also check if there's already an active session
      const { data } = await supabase.auth.getSession();
      if (data.session && (hash.includes('type=recovery') || hash.includes('access_token'))) {
        setMode('update');
      }

      return () => {
        authListener.subscription.unsubscribe();
      };
    };

    checkRecoverySession();
  }, []);

  // Calculate password strength
  const getPasswordStrength = (pass: string) => {
    if (!pass) return { score: 0, label: '', color: 'transparent' };
    let score = 0;
    if (pass.length >= 6) score++;
    if (pass.length >= 10) score++;
    if (/[A-Z]/.test(pass)) score++;
    if (/[0-9]/.test(pass)) score++;
    if (/[^A-Za-z0-9]/.test(pass)) score++;

    if (score <= 2) return { score, label: 'Weak', color: '#EF4444' };
    if (score <= 4) return { score, label: 'Moderate', color: '#F59E0B' };
    return { score, label: 'Strong', color: '#10B981' };
  };

  const strength = getPasswordStrength(newPassword);

  // Handle requesting a new reset link
  const handleRequestReset = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setSuccessMsg(null);

    const trimmed = email.trim();
    if (!trimmed || !trimmed.includes('@')) {
      setErrorMsg('Please enter a valid email address.');
      return;
    }

    setLoading(true);
    try {
      const redirectUrl = `${window.location.origin}/reset-password`;
      const { error } = await supabase.auth.resetPasswordForEmail(trimmed, {
        redirectTo: redirectUrl,
      });

      if (error) {
        setErrorMsg(error.message);
      } else {
        setSuccessMsg(`A secure password reset link has been dispatched to ${trimmed}. Please check your inbox (and spam folder) and click the link to set your new password.`);
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'An unexpected error occurred. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  // Handle submitting new password
  const handleUpdatePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setSuccessMsg(null);

    if (newPassword.length < 6) {
      setErrorMsg('Password must be at least 6 characters long.');
      return;
    }

    if (newPassword !== confirmPassword) {
      setErrorMsg('Passwords do not match. Please re-enter.');
      return;
    }

    setLoading(true);
    try {
      const { error } = await supabase.auth.updateUser({
        password: newPassword,
      });

      if (error) {
        setErrorMsg(error.message);
      } else {
        setIsUpdated(true);
        try {
          confetti({
            particleCount: 100,
            spread: 80,
            origin: { y: 0.6 },
            colors: ['#10B981', '#06B6D4', '#F59E0B', '#FFFFFF'],
          });
        } catch (_) {}
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Failed to update password. Your recovery link may have expired.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '580px', margin: '0 auto', padding: '40px 20px 80px' }}>
      {/* Back button */}
      <button
        onClick={() => navigate('home')}
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '8px',
          padding: '8px 16px',
          borderRadius: '8px',
          backgroundColor: 'rgba(255, 255, 255, 0.05)',
          border: '1px solid var(--border-subtle)',
          color: 'var(--text-secondary)',
          cursor: 'pointer',
          fontSize: '0.88rem',
          fontWeight: 600,
          marginBottom: '28px',
        }}
      >
        <ArrowLeft size={16} />
        <span>Return to Platform</span>
      </button>

      {/* Main Glass Panel */}
      <div 
        className="glass-panel"
        style={{
          borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--border-medium)',
          boxShadow: 'var(--shadow-lg)',
          overflow: 'hidden',
        }}
      >
        {/* Header Ribbon */}
        <div 
          style={{
            padding: '24px 30px',
            backgroundColor: 'rgba(16, 185, 129, 0.08)',
            borderBottom: '1px solid var(--border-subtle)',
            display: 'flex',
            alignItems: 'center',
            gap: '14px',
          }}
        >
          <div 
            style={{
              width: '48px',
              height: '48px',
              borderRadius: '12px',
              backgroundColor: 'rgba(16, 185, 129, 0.15)',
              border: '1px solid rgba(16, 185, 129, 0.3)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'var(--primary)',
            }}
          >
            <KeyRound size={24} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <h2 style={{ fontSize: '1.3rem', fontWeight: 800, margin: 0 }}>
                {mode === 'update' ? 'Set New Password' : 'Reset Your Password'}
              </h2>
            </div>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.86rem', margin: '4px 0 0' }}>
              {mode === 'update' 
                ? 'Create a strong, secure password for your PetConnect AI account.' 
                : 'Recover access to your PetConnect AI profile and companions.'}
            </p>
          </div>
        </div>

        {/* Form Body */}
        <div style={{ padding: '30px' }}>
          {/* Error Notice */}
          {errorMsg && (
            <div 
              style={{
                display: 'flex',
                alignItems: 'flex-start',
                gap: '10px',
                padding: '14px 16px',
                borderRadius: '10px',
                backgroundColor: 'rgba(239, 68, 68, 0.12)',
                border: '1px solid rgba(239, 68, 68, 0.3)',
                color: '#F87171',
                fontSize: '0.88rem',
                marginBottom: '20px',
              }}
            >
              <AlertCircle size={18} style={{ flexShrink: 0, marginTop: '2px' }} />
              <div>
                <div style={{ fontWeight: 700 }}>Security Notice</div>
                <div style={{ marginTop: '2px' }}>{errorMsg}</div>
                {mode === 'update' && (
                  <button
                    onClick={() => {
                      setMode('request');
                      setErrorMsg(null);
                    }}
                    style={{
                      marginTop: '8px',
                      background: 'none',
                      border: 'none',
                      color: 'var(--primary)',
                      fontSize: '0.84rem',
                      fontWeight: 700,
                      cursor: 'pointer',
                      padding: 0,
                      textDecoration: 'underline',
                    }}
                  >
                    Click here to request a new reset link
                  </button>
                )}
              </div>
            </div>
          )}

          {/* Success Notice for Request Mode */}
          {successMsg && (
            <div 
              style={{
                display: 'flex',
                alignItems: 'flex-start',
                gap: '10px',
                padding: '16px',
                borderRadius: '10px',
                backgroundColor: 'rgba(16, 185, 129, 0.12)',
                border: '1px solid rgba(16, 185, 129, 0.3)',
                color: 'var(--primary)',
                fontSize: '0.9rem',
                lineHeight: '1.5',
                marginBottom: '20px',
              }}
            >
              <CheckCircle2 size={20} style={{ flexShrink: 0, marginTop: '2px' }} />
              <div>
                <div style={{ fontWeight: 800 }}>Reset Email Dispatched!</div>
                <div style={{ marginTop: '4px', color: 'var(--text-secondary)' }}>{successMsg}</div>
              </div>
            </div>
          )}

          {/* State 1: Password Updated Success */}
          {isUpdated ? (
            <div style={{ textAlign: 'center', padding: '20px 0' }}>
              <div 
                style={{
                  width: '64px',
                  height: '64px',
                  borderRadius: '50%',
                  backgroundColor: 'rgba(16, 185, 129, 0.18)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  margin: '0 auto 18px',
                  color: 'var(--primary)',
                }}
              >
                <CheckCircle2 size={36} />
              </div>
              <h3 style={{ fontSize: '1.4rem', fontWeight: 800, marginBottom: '8px' }}>
                Password Updated Successfully!
              </h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.94rem', lineHeight: '1.6', marginBottom: '28px' }}>
                Your account credentials have been securely updated in PetConnect AI. You can now sign in with your new password on the mobile app or web platform.
              </p>
              <button
                onClick={() => navigate('home')}
                style={{
                  padding: '14px 28px',
                  borderRadius: '10px',
                  background: 'linear-gradient(135deg, var(--primary) 0%, #059669 100%)',
                  color: '#FFFFFF',
                  fontWeight: 800,
                  fontSize: '0.96rem',
                  border: 'none',
                  cursor: 'pointer',
                  boxShadow: '0 4px 14px rgba(16, 185, 129, 0.35)',
                }}
              >
                Go to PetConnect AI Platform
              </button>
            </div>
          ) : mode === 'update' ? (
            /* State 2: Enter New Password Form */
            <form onSubmit={handleUpdatePassword}>
              <div style={{ marginBottom: '18px' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)', marginBottom: '8px' }}>
                  New Password *
                </label>
                <div style={{ position: 'relative' }}>
                  <input
                    type={showPassword ? 'text' : 'password'}
                    required
                    minLength={6}
                    placeholder="Enter at least 6 characters"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    style={{
                      width: '100%',
                      padding: '12px 44px 12px 14px',
                      borderRadius: '8px',
                      backgroundColor: 'rgba(255, 255, 255, 0.05)',
                      border: '1px solid var(--border-medium)',
                      color: 'var(--text-primary)',
                      fontSize: '0.94rem',
                      fontFamily: 'inherit',
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    style={{
                      position: 'absolute',
                      right: '12px',
                      top: '50%',
                      transform: 'translateY(-50%)',
                      background: 'none',
                      border: 'none',
                      color: 'var(--text-muted)',
                      cursor: 'pointer',
                      padding: '4px',
                    }}
                  >
                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>

                {/* Password Strength Meter */}
                {newPassword.length > 0 && (
                  <div style={{ marginTop: '8px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.74rem', marginBottom: '4px' }}>
                      <span style={{ color: 'var(--text-muted)' }}>Strength:</span>
                      <span style={{ color: strength.color, fontWeight: 700 }}>{strength.label}</span>
                    </div>
                    <div style={{ height: '4px', backgroundColor: 'rgba(255, 255, 255, 0.08)', borderRadius: '2px', overflow: 'hidden' }}>
                      <div 
                        style={{
                          height: '100%',
                          width: `${(strength.score / 5) * 100}%`,
                          backgroundColor: strength.color,
                          transition: 'all 0.3s ease',
                        }}
                      />
                    </div>
                  </div>
                )}
              </div>

              <div style={{ marginBottom: '24px' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)', marginBottom: '8px' }}>
                  Confirm New Password *
                </label>
                <div style={{ position: 'relative' }}>
                  <input
                    type={showConfirm ? 'text' : 'password'}
                    required
                    minLength={6}
                    placeholder="Re-enter your new password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    style={{
                      width: '100%',
                      padding: '12px 44px 12px 14px',
                      borderRadius: '8px',
                      backgroundColor: 'rgba(255, 255, 255, 0.05)',
                      border: '1px solid var(--border-medium)',
                      color: 'var(--text-primary)',
                      fontSize: '0.94rem',
                      fontFamily: 'inherit',
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirm(!showConfirm)}
                    style={{
                      position: 'absolute',
                      right: '12px',
                      top: '50%',
                      transform: 'translateY(-50%)',
                      background: 'none',
                      border: 'none',
                      color: 'var(--text-muted)',
                      cursor: 'pointer',
                      padding: '4px',
                    }}
                  >
                    {showConfirm ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                style={{
                  width: '100%',
                  padding: '14px',
                  borderRadius: '10px',
                  background: 'linear-gradient(135deg, var(--primary) 0%, #059669 100%)',
                  color: '#FFFFFF',
                  fontWeight: 800,
                  fontSize: '0.98rem',
                  border: 'none',
                  cursor: loading ? 'not-allowed' : 'pointer',
                  opacity: loading ? 0.7 : 1,
                  boxShadow: '0 4px 14px rgba(16, 185, 129, 0.35)',
                }}
              >
                {loading ? 'Updating Credentials...' : 'Save & Secure New Password'}
              </button>
            </form>
          ) : (
            /* State 3: Request Reset Link Form */
            <form onSubmit={handleRequestReset}>
              <div style={{ marginBottom: '22px' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)', marginBottom: '8px' }}>
                  Account Email Address *
                </label>
                <div style={{ position: 'relative' }}>
                  <input
                    type="email"
                    required
                    placeholder="e.g. antonythomson06@gmail.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    style={{
                      width: '100%',
                      padding: '12px 14px 12px 42px',
                      borderRadius: '8px',
                      backgroundColor: 'rgba(255, 255, 255, 0.05)',
                      border: '1px solid var(--border-medium)',
                      color: 'var(--text-primary)',
                      fontSize: '0.94rem',
                      fontFamily: 'inherit',
                    }}
                  />
                  <Mail 
                    size={18} 
                    style={{
                      position: 'absolute',
                      left: '14px',
                      top: '50%',
                      transform: 'translateY(-50%)',
                      color: 'var(--text-muted)',
                    }} 
                  />
                </div>
                <p style={{ color: 'var(--text-muted)', fontSize: '0.78rem', marginTop: '6px' }}>
                  We will send a one-time cryptographic reset link valid for 1 hour.
                </p>
              </div>

              <button
                type="submit"
                disabled={loading}
                style={{
                  width: '100%',
                  padding: '14px',
                  borderRadius: '10px',
                  background: 'linear-gradient(135deg, var(--primary) 0%, #059669 100%)',
                  color: '#FFFFFF',
                  fontWeight: 800,
                  fontSize: '0.98rem',
                  border: 'none',
                  cursor: loading ? 'not-allowed' : 'pointer',
                  opacity: loading ? 0.7 : 1,
                  boxShadow: '0 4px 14px rgba(16, 185, 129, 0.35)',
                }}
              >
                {loading ? 'Dispatched Request...' : 'Send Secure Reset Link'}
              </button>

              <div style={{ marginTop: '20px', textAlign: 'center' }}>
                <button
                  type="button"
                  onClick={() => setMode('update')}
                  style={{
                    background: 'none',
                    border: 'none',
                    color: 'var(--text-muted)',
                    fontSize: '0.82rem',
                    cursor: 'pointer',
                    textDecoration: 'underline',
                  }}
                >
                  Already have a recovery link or token? Click here to enter new password.
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};
