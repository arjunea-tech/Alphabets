import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { authApi } from '../api/auth';
import { useLanguage } from '../context/LanguageContext';
import { ShieldCheck, Lock, KeyRound, X, CheckCircle2, AlertCircle, Server } from 'lucide-react';
import { API_BASE_URL } from '../api/client';

export const SettingsPage: React.FC = () => {
  const { admin } = useAuth();
  const { t } = useLanguage();
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [status, setStatus] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showPasswordForm, setShowPasswordForm] = useState(false);

  const togglePasswordForm = () => {
    setShowPasswordForm((open) => !open);
    setCurrentPassword('');
    setNewPassword('');
    setConfirmPassword('');
    setStatus(null);
  };

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
        setShowPasswordForm(false);
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

  const apiUrl = API_BASE_URL;

  return (
    <div style={{ maxWidth: '800px' }}>
      <div className="page-header">
        <div className="page-title-group">
          <h2>{t('settings.pageTitle')}</h2>
          <p>{t('settings.pageSubtitle')}</p>
        </div>
      </div>

      {/* Admin Profile Card + Change Password */}
      <div className="card" style={{ marginBottom: '24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '20px', flexWrap: 'wrap' }}>
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
              flexShrink: 0,
            }}
          >
            {(admin?.fullName || admin?.full_name || admin?.username || 'A').trim().charAt(0).toUpperCase()}
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <h3 style={{ fontSize: '18px', fontWeight: 700 }}>
              {admin?.fullName || admin?.full_name || admin?.username || 'Admin'}
            </h3>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--text-muted)', fontSize: '14px' }}>
              <ShieldCheck size={16} color="var(--primary)" />
              <span>{admin?.role === 'super_admin' ? t('role_super_admin') : t('role_content_admin')}</span>
            </div>
          </div>
          <button
            type="button"
            className={showPasswordForm ? 'btn btn-secondary' : 'btn btn-primary'}
            onClick={togglePasswordForm}
            style={{ display: 'inline-flex', alignItems: 'center', gap: '8px' }}
          >
            {showPasswordForm ? <X size={16} /> : <KeyRound size={16} />}
            <span>{showPasswordForm ? t('common.cancel') : t('settings.changePassword')}</span>
          </button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', borderTop: '1px solid var(--border-color)', paddingTop: '16px' }}>
          <div>
            <div style={{ fontSize: '13px', color: 'var(--text-muted)' }}>{t('settings.username')}</div>
            <div style={{ fontWeight: 600, fontSize: '15px', marginTop: '2px' }}>{admin?.username || '-'}</div>
          </div>
          <div>
            <div style={{ fontSize: '13px', color: 'var(--text-muted)' }}>{t('settings.email')}</div>
            <div style={{ fontWeight: 600, fontSize: '15px', marginTop: '2px' }}>{admin?.email || '-'}</div>
          </div>
        </div>

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
              marginTop: '16px',
            }}
          >
            {status.type === 'success' ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
            <span>{status.message}</span>
          </div>
        )}

        {showPasswordForm && (
          <form
            onSubmit={handlePasswordChange}
            style={{ borderTop: '1px solid var(--border-color)', marginTop: '16px', paddingTop: '16px' }}
          >
            <h4 style={{ fontSize: '16px', fontWeight: 700, marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Lock size={17} color="var(--primary)" />
              <span>{t('settings.changePassword')}</span>
            </h4>

            <div className="form-group">
              <label className="form-label">{t('settings.currentPassword')}</label>
              <input
                type="password"
                className="form-control"
                placeholder="••••••••"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                autoComplete="current-password"
                autoFocus
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
                  autoComplete="new-password"
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
                  autoComplete="new-password"
                  required
                />
              </div>
            </div>

            <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
              {isSubmitting ? t('common.saving') : t('settings.updatePassword')}
            </button>
          </form>
        )}
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
