import React from 'react';
import { useLanguage } from '../../context/LanguageContext';

interface HeaderProps {
  title?: string;
}

export const Header: React.FC<HeaderProps> = ({ title }) => {
  const { language, setLanguage, t } = useLanguage();

  const displayTitle = title || t('app_subtitle');
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
      </div>
    </header>
  );
};
