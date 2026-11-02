import React from 'react';
import { useLanguage } from '../../context/LanguageContext';

interface HeaderProps {
  title?: string;
}

export const Header: React.FC<HeaderProps> = ({ title }) => {
  const { t } = useLanguage();

  const displayTitle = title || t('app_subtitle');
  return (
    <header className="top-header">
      <div className="header-left">
        <h1>{displayTitle}</h1>
      </div>

      <div className="header-right">
        <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--text-muted)' }}>
          English Edition (A - Z)
        </span>
      </div>
    </header>
  );
};
