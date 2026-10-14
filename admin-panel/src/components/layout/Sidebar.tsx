import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  GraduationCap,
  BookOpen,
  Library,
  Video,
  HelpCircle,
  Gamepad2,
  Users,
  Settings,
  LogOut,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useLanguage } from '../../context/LanguageContext';

export const Sidebar: React.FC = () => {
  const { logout, admin } = useAuth();
  const { t } = useLanguage();

  return (
    <aside className="sidebar">
      {/* Brand Header */}
      <div className="sidebar-header">
        <img src="/app_logo.png" alt="App Logo" className="sidebar-logo-img" />
        <div>
          <div className="sidebar-title">{t('app_title')}</div>
          <div className="sidebar-subtitle">{t('app_subtitle')}</div>
        </div>
      </div>

      {/* Navigation Links */}
      <nav className="sidebar-nav">
        <div className="nav-section">
          <div className="nav-section-title">{t('nav_overview_section')}</div>
          <NavLink to="/dashboard" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <LayoutDashboard size={18} />
            <span>{t('nav_dashboard')}</span>
          </NavLink>
        </div>

        <div className="nav-section">
          <div className="nav-section-title">{t('nav_content_section')}</div>
          <NavLink to="/lessons" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <GraduationCap size={18} />
            <span>{t('nav_lessons')}</span>
          </NavLink>

          <NavLink to="/letters" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <BookOpen size={18} />
            <span>{t('nav_letters')}</span>
          </NavLink>

          <NavLink to="/stories" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <Library size={18} />
            <span>{t('nav_stories')}</span>
          </NavLink>

          <NavLink to="/videos" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <Video size={18} />
            <span>{t('nav_videos')}</span>
          </NavLink>

          <NavLink to="/quizzes" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <HelpCircle size={18} />
            <span>{t('nav_quizzes')}</span>
          </NavLink>

          <NavLink to="/games" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <Gamepad2 size={18} />
            <span>{t('nav_games')}</span>
          </NavLink>
        </div>

        <div className="nav-section">
          <div className="nav-section-title">{t('nav_learners_section')}</div>
          <NavLink to="/users" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <Users size={18} />
            <span>{t('nav_users')}</span>
          </NavLink>
        </div>

        <div className="nav-section">
          <div className="nav-section-title">{t('nav_system_section')}</div>
          <NavLink to="/settings" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <Settings size={18} />
            <span>{t('nav_settings')}</span>
          </NavLink>

          <button
            onClick={logout}
            className="nav-link nav-link-logout"
          >
            <LogOut size={18} />
            <span>{t('nav_logout')}</span>
          </button>
        </div>
      </nav>

      {/* Footer Info */}
      <div className="sidebar-footer">
        <div style={{ display: 'flex', flexDirection: 'column', width: '100%', gap: '3px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 600, fontSize: '13px', color: 'var(--text-main)' }}>
            <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#10B981', flexShrink: 0 }}></span>
            <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={admin?.fullName || admin?.username || 'Admin'}>
              {admin?.fullName || admin?.full_name || admin?.username || 'Admin'}
            </span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '11px', color: 'var(--text-muted)' }}>
            <span>{admin?.role === 'super_admin' ? t('role_super_admin') : t('role_content_admin')}</span>
            <span className="sidebar-footer-version">v1.0.0</span>
          </div>
        </div>
      </div>
    </aside>
  );
};
