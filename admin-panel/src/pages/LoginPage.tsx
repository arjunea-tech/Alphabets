import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useLanguage } from '../context/LanguageContext';
import { Lock, User, AlertCircle, Loader2 } from 'lucide-react';

export const LoginPage: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { login } = useAuth();
  const { language, setLanguage, t } = useLanguage();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!username || !password) {
      setError(t('login_error_required'));
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      await login({ username, password });
      navigate('/dashboard');
    } catch (err: any) {
      setError(
        err.response?.data?.message || err.message || t('login_error_failed')
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const fillDefaultCredentials = () => {
    setUsername('superadmin');
    setPassword('Admin@123');
  };

  return (
    <div className="login-container">
      <div className="login-card">
        {/* Language Switcher in Login */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '14px' }}>
          <div style={{ display: 'inline-flex', background: 'var(--bg-muted)', padding: '3px', borderRadius: 'var(--radius-full)', border: '1px solid var(--border-color)' }}>
            
            <button
              type="button"
              onClick={() => setLanguage('en')}
              style={{
                padding: '4px 10px',
                borderRadius: 'var(--radius-full)',
                border: 'none',
                background: language === 'en' ? 'var(--primary)' : 'transparent',
                color: language === 'en' ? 'white' : 'var(--text-main)',
                fontWeight: 700,
                fontSize: '12px',
                cursor: 'pointer',
              }}
            >
              English
            </button>
          </div>
        </div>

        <div className="login-logo-box">
          <img src="/app_logo.png" alt="App Logo" className="login-logo-img" />
        </div>
        <h2 style={{ textAlign: 'center', fontSize: '26px', fontWeight: 800, color: 'var(--text-main)' }}>
          {t('login_title')}
        </h2>
        <p style={{ textAlign: 'center', fontSize: '14px', color: 'var(--text-muted)', marginBottom: '24px' }}>
          {t('login_subtitle')}
        </p>

        {error && (
          <div
            style={{
              padding: '12px 16px',
              borderRadius: 'var(--radius-md)',
              background: 'var(--danger-light)',
              color: 'var(--danger)',
              fontSize: '14px',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              marginBottom: '20px',
            }}
          >
            <AlertCircle size={18} style={{ flexShrink: 0 }} />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">{t('login_username_label')}</label>
            <div style={{ position: 'relative' }}>
              <input
                type="text"
                className="form-control"
                placeholder={t('login_username_placeholder')}
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                style={{ paddingLeft: '42px' }}
                disabled={isSubmitting}
              />
              <User
                size={18}
                style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: '#94A3B8' }}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">{t('login_password_label')}</label>
            <div style={{ position: 'relative' }}>
              <input
                type="password"
                className="form-control"
                placeholder={t('login_password_placeholder')}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                style={{ paddingLeft: '42px' }}
                disabled={isSubmitting}
              />
              <Lock
                size={18}
                style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: '#94A3B8' }}
              />
            </div>
          </div>

          <button
            type="submit"
            className="btn btn-primary"
            style={{ width: '100%', padding: '12px', marginTop: '12px', fontSize: '16px' }}
            disabled={isSubmitting}
          >
            {isSubmitting ? (
              <>
                <Loader2 size={18} className="spin" />
                <span>{t('login_verifying')}</span>
              </>
            ) : (
              <span>{t('login_submit_btn')}</span>
            )}
          </button>
        </form>

        {/* Demo Credentials Hint */}
        <div className="login-hint">
          <div style={{ fontWeight: 700, marginBottom: '6px', color: 'var(--text-main)', fontSize: '13px' }}>
            {t('login_demo_hint_title')}
          </div>
          <div>User: <code>superadmin</code></div>
          <div>Pass: <code>Admin@123</code></div>
          <button
            type="button"
            onClick={fillDefaultCredentials}
            className="btn btn-secondary btn-sm"
            style={{ marginTop: '10px', width: '100%', fontSize: '13px' }}
          >
            {t('login_autofill_btn')}
          </button>
        </div>
      </div>
    </div>
  );
};
