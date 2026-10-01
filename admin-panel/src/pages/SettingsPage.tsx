import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { authApi } from '../api/auth';
import { useLanguage } from '../context/LanguageContext';
import { ShieldCheck, Lock, CheckCircle2, AlertCircle, Server } from 'lucide-react';

export const SettingsPage: React.FC = () => {
  const { admin } = useAuth();
  const { t } = useLanguage();
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [status, setStatus] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handlePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentPassword || !newPassword) {
      setStatus({ type: 'error', message: 'Fill all fields' });
      return;
    }

    if (newPassword.length < 6) {
      setStatus({ type: 'error', message: 'Password must be at least 6 characters' });
      return;
    }

    if (newPassword !== confirmPassword) {
      setStatus({ type: 'error', message: 'Passwords do not match' });
      return;
    }

    setIsSubmitting(true);
    setStatus(null);

    try {
      const res = await authApi.changePassword({ currentPassword, newPassword });
      if (res.success) {
        setStatus({ type: 'success', message: t('settings.passwordChanged') });
        setCurrentPassword('');
        setNewPassword('');
        setConfirmPassword('');
      }
    } catch (err: any) {
      setStatus({
        type: 'error',
        message: err.response?.data?.message || err.message || 'Password update failed',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:5000/api/v1';

  return (
    <div style={{ maxWidth: '800px' }}>
      <div className="page-header">
        <div className="page-title-group">
          <h2>{t('settings.pageTitle')}</h2>
          <p>{t('settings.pageSubtitle')}</p>
        </div>
      </div>

      {/* Admin Profile Card */}
      <div className="card" style={{ marginBottom: '24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '20px' }}>
          <div
            style={{
              width: '56px',
              height: '56px',
              borderRadius: '50%',
              background: 'var(--secondary)',
              color: 'white',
              fontSize: '24px',
              fontWeight: 800,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            {admin?.fullName?.charAt(0) || 'A'}
          </div>
          <div>
            <h3 style={{ fontSize: '18px', fontWeight: 700 }}>{admin?.fullName}</h3>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--text-muted)', fontSize: '14px' }}>
              <ShieldCheck size={16} color="var(--primary)" />
              <span>{admin?.role === 'super_admin' ? t('header.superAdmin') : 'Content Admin'}</span>
            </div>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', borderTop: '1px solid var(--border-color)', paddingTop: '16px' }}>
          <div>
            <div style={{ fontSize: '13px', color: 'var(--text-muted)' }}>{t('settings.username')}</div>
            <div style={{ fontWeight: 600, fontSize: '15px', marginTop: '2px' }}>{admin?.username}</div>
          </div>
          <div>
            <div style={{ fontSize: '13px', color: 'var(--text-muted)' }}>{t('settings.email')}</div>
            <div style={{ fontWeight: 600, fontSize: '15px', marginTop: '2px' }}>{admin?.email}</div>
          </div>
        </div>
      </div>

      {/* Change Password Card */}
      <div className="card" style={{ marginBottom: '24px' }}>
        <h3 style={{ fontSize: '17px', fontWeight: 700, marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Lock size={18} color="var(--primary)" />
          <span>{t('settings.changePassword')}</span>
        </h3>
        <p style={{ fontSize: '14px', color: 'var(--text-muted)', marginBottom: '16px' }}>
          {t('settings.pageSubtitle')}
        </p>

        {status && (
          <div
            style={{
              padding: '12px 16px',
              borderRadius: 'var(--radius-md)',
              background: status.type === 'success' ? 'var(--success-light)' : 'var(--danger-light)',
              color: status.type === 'success' ? 'var(--success)' : 'var(--danger)',
              fontSize: '14px',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              marginBottom: '16px',
            }}
          >
            {status.type === 'success' ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
            <span>{status.message}</span>
          </div>
        )}

        <form onSubmit={handlePasswordChange}>
          <div className="form-group">
            <label className="form-label">{t('settings.currentPassword')}</label>
            <input
              type="password"
              className="form-control"
              placeholder="••••••••"
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              required
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('settings.newPassword')}</label>
              <input
                type="password"
                className="form-control"
                placeholder="Min 6 characters"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('settings.confirmPassword')}</label>
              <input
                type="password"
                className="form-control"
                placeholder="Repeat password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
              />
            </div>
          </div>

          <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
            {isSubmitting ? t('common.saving') : t('settings.updatePassword')}
          </button>
        </form>
      </div>

      {/* Backend Connection Info */}
      <div className="card">
        <h3 style={{ fontSize: '16px', fontWeight: 700, marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Server size={18} color="#3B82F6" />
          <span>{t('settings.backendConnection')}</span>
        </h3>
        <div style={{ fontSize: '14px', color: 'var(--text-muted)', marginBottom: '12px' }}>
          AGARAM Node.js + Express REST API:
        </div>
        <div style={{ background: 'var(--bg-muted)', padding: '10px 14px', borderRadius: 'var(--radius-md)', fontFamily: 'monospace', fontSize: '14px' }}>
          {apiUrl}
        </div>
      </div>
    </div>
  );
};
