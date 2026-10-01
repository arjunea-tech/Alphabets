import React from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';
import { useLanguage } from '../../context/LanguageContext';

export const AdminLayout: React.FC = () => {
  const location = useLocation();
  const { t } = useLanguage();

  const getPageTitle = (pathname: string): string => {
    switch (pathname) {
      case '/dashboard':
        return t('nav_dashboard');
      case '/lessons':
        return t('nav_lessons');
      case '/letters':
        return t('nav_letters');
      case '/stories':
        return t('nav_stories');
      case '/videos':
        return t('nav_videos');
      case '/quizzes':
        return t('nav_quizzes');
      case '/games':
        return t('nav_games');
      case '/users':
        return t('nav_users');
      case '/settings':
        return t('nav_settings');
      default:
        return t('app_subtitle');
    }
  };

  const currentTitle = getPageTitle(location.pathname);

  return (
    <div className="app-layout">
      <Sidebar />
      <div className="main-wrapper">
        <Header title={currentTitle} />
        <main className="content-body">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
