import React from 'react';
import { useAuth } from '../../context/AuthContext';
import { useLanguage } from '../../context/LanguageContext';
import { LogOut, ShieldCheck, Globe } from 'lucide-react';

interface HeaderProps {
  title?: string;
}

export const Header: React.FC<HeaderProps> = ({ title }) => {
  const { admin, logout } = useAuth();
  const { language, setLanguage, t } = useLanguage();

  const displayTitle = title || t('app_subtitle');
  const displayName = admin?.fullName || admin?.full_name || admin?.username || t('header_admin');
  const usernameTag = admin?.username ? `@${admin.username}` : '';
  const avatarLetter = (displayName || admin?.username || 'A').trim().charAt(0).toUpperCase();

  return (
    <header className="top-header">
      <div className="header-left">
        <h1>{displayTitle}</h1>
      </div>

      <div className="header-right">
        {/* Language Switcher Button */}
        <div className="lang-switcher-container">
          <button
            onClick={() => setLanguage('ta')}
            className={`lang-btn ${language === 'ta' ? 'active' : ''}`}
          >
            தமிழ்
          </button>
          <button
            onClick={() => setLanguage('en')}
            className={`lang-btn ${language === 'en' ? 'active' : ''}`}
          >
            English
          </button>
        </div>

        {/* Admin Info Chip */}
        <div className="admin-chip" title={`${displayName} ${usernameTag}`}>
          <div className="admin-avatar-bubble">
            {avatarLetter}
          </div>
          <div className="admin-info-text">
            <div className="admin-name">
              {displayName}
            </div>
            <div className="admin-role-badge">
              <ShieldCheck size={12} color="var(--primary)" />
              <span>
                {usernameTag ? `${usernameTag} • ` : ''}
                {admin?.role === 'super_admin' ? t('role_super_admin') : t('role_content_admin')}
              </span>
            </div>
          </div>
        </div>

        {/* Logout Button */}
        <button
          onClick={logout}
          className="btn btn-secondary btn-header-logout"
          title={t('nav_logout')}
        >
          <LogOut size={15} />
          <span>{t('header_logout_btn')}</span>
        </button>
      </div>
    </header>
  );
};
